local Things = require"core/src/things"

local SystemRegistry = require_ext"src/system_registry"
local hook = SystemRegistry.new_hook

local MIN_RANDOM_WALK_TIME = 20
local MAX_RANDOM_WALK_TIME = 120
-- Steps a walker can go without a drink. Each walker picks its own limit in this range.
local MIN_THIRST_LIMIT = 1500
local MAX_THIRST_LIMIT = 3000
-- Walkers within this many tiles of the player report what they do in the log.
local CHATTER_RANGE = 7

local random_draconic_names = {
	"Li'l shit",
	"Little guy",
	"Fella",
	"Little dude",
	"Skrunkly",
	"Little baby man",
}

local random_draconic_types = {
	"Kobold",
	"Dragon",
	"Lizard",
	"Komodo Dragon"
}

local random_canine_names = {
	"Good boy",
	"Doggo",
	"Pupper",
	"Doge",
	"Smooth Brain",
}

local random_canine_types = {
	"Wolf",
	"Fox",
	"Maned Wolf",
	"Dog",
	"Dingo",
	"Coyote"
}

-- What each walker_state shows in the tooltip.
local STATE_NAMES = {
	wandering = "Wandering",
	to_water = "Thirsty",
	returning = "Heading back",
}

local DIRECTIONS = {
	[-1] = {[-1] = "north-west", [0] = "west", [1] = "south-west"},
	[0] = {[-1] = "north", [1] = "south"},
	[1] = {[-1] = "north-east", [0] = "east", [1] = "south-east"},
}

local function make_tooltip(walker)
	return walker.name .. "\n\fm" .. STATE_NAMES[walker.walker_state] .. "\n\fc" .. walker.species
end

local function water_distance_at(dist, pos)
	return dist[pos.y * dist:width() + pos.x]
end

-- Builds a map of how many steps each tile is from the nearest water.
-- Water is 0, land counts up from the shore, and -1 means no water can be reached.
local function build_water_distance(ctx)
	local ocean_mask = ctx.ocean_mask
	local w, h = ocean_mask:attribs()
	local dist = userdata("i16", w, h)
	local queue = {}
	
	for i = 0, w * h - 1 do
		if ocean_mask[i] > 0 then
			dist[i] = 0
			add(queue, i)
		else
			dist[i] = -1
		end
	end
	
	-- Flood outwards from the water, eight ways, the same way walkers move.
	local head = 1
	while head <= #queue do
		local i = queue[head]
		head += 1
		local x, y = i % w, i // w
		local d = dist[i] + 1
		for ny = max(y - 1, 0), min(y + 1, h - 1) do
			for nx = max(x - 1, 0), min(x + 1, w - 1) do
				local ni = ny * w + nx
				if dist[ni] == -1 then
					dist[ni] = d
					add(queue, ni)
				end
			end
		end
	end
	
	---@class Context
	---@field water_distance userdata i16 Steps to the nearest water. 0 is water, -1 is unreachable.
	ctx.game_ctx.water_distance = dist
end

local function step_toward_water(dist, pos)
	local w, h = dist:attribs()
	local best = water_distance_at(dist, pos)
	local step
	for dy = -1, 1 do
		for dx = -1, 1 do
			local x, y = pos.x + dx, pos.y + dy
			if x >= 0 and x < w and y >= 0 and y < h then
				local d = dist[y * w + x]
				if d > 0 and d < best then
					best, step = d, vec(dx, dy)
				end
			end
		end
	end
	return step
end

local function random_land_step(dist, pos)
	local w, h = dist:attribs()
	for _ = 1, 8 do
		local step = vec(rnd(3) - 1, rnd(3) - 1) // 1
		local x, y = pos.x + step.x, pos.y + step.y
		if (step.x != 0 or step.y != 0)
			and x >= 0 and x < w and y >= 0 and y < h
			and dist[y * w + x] != 0
		then
			return step
		end
	end
end

local function spawn_walkers(ctx)
	local game_ctx = ctx.game_ctx
	local dist = game_ctx.water_distance
	local map_config = ctx.res:get("config", "core_map")
	local map_w, map_h = map_config.size.x, map_config.size.y
	local tile_size = map_config.tile_size
	
	for _ = 1, 100 do
		local pos
		repeat
			pos = vec(rnd(map_w), rnd(map_h)) // 1
		until water_distance_at(dist, pos) != 0
		
		local sprite_name = rnd{"core_anthro_draconic", "core_anthro_canine"}
		
		local name = rnd(sprite_name == "core_anthro_draconic" and random_draconic_names or random_canine_names)
		local species = rnd(sprite_name == "core_anthro_draconic" and random_draconic_types or random_canine_types)
		local thirst_limit = (MIN_THIRST_LIMIT + rnd(MAX_THIRST_LIMIT - MIN_THIRST_LIMIT)) // 1
		
		local walker = {
			thing_renderer = Things.new_renderer(
				ctx.res:get("sprite", sprite_name),
				rnd(32) // 1
			),
			grid_pos = pos,
			display_pos = pos * tile_size,
			move_request = vec(0, 0),
			random_walk_timer = math.random(MIN_RANDOM_WALK_TIME, MAX_RANDOM_WALK_TIME),
			thirst = rnd(thirst_limit) // 1,
			thirst_limit = thirst_limit,
			-- "wandering", "to_water" or "returning".
			walker_state = "wandering",
			-- Steps taken on the way to water, walked backwards after drinking to get home.
			trail = {},
			name = name,
			species = species,
		}
		walker.tooltip = make_tooltip(walker)
		
		ctx.entity_map:add(game_ctx.entities:instantiate(walker))
	end
end

local function update_walkers(ctx)
	local dist = ctx.water_distance
	local player_pos = ctx.player.grid_pos
	
	local function say(entity, msg)
		local delta = (entity.grid_pos - player_pos):abs()
		if max(delta.x, delta.y) <= CHATTER_RANGE then
			ctx.ui.text_window:push(entity.name .. " " .. msg)
		end
	end
	
	local function set_state(entity, state)
		entity.walker_state = state
		entity.tooltip = make_tooltip(entity)
	end

	for entity in ctx.entities:query("thirst", "grid_pos") do
		entity.thirst += 1
		local water_dist = water_distance_at(dist, entity.grid_pos)
		local trail = entity.trail

		-- Getting thirsty sends a walker off to water from wherever it is, even on the way home.
		-- Walkers with no water they can reach (-1) just keep wandering.
		if entity.thirst >= entity.thirst_limit and water_dist > 0
			and entity.walker_state != "to_water"
		then
			set_state(entity, "to_water")
			say(entity, "is thirsty and heads for water.")
		end

		local state = entity.walker_state
		if state == "to_water" then
			if water_dist == 1 then
				-- Standing on the shore: drink, then retrace the trail home.
				entity.thirst = 0
				if #trail > 0 then
					set_state(entity, "returning")
					say(entity, "drinks from the water and heads back.")
				else
					set_state(entity, "wandering")
					say(entity, "drinks from the water.")
				end
			else
				local step = step_toward_water(dist, entity.grid_pos)
				if step then
					add(trail, step)
					entity.move_request = step
				end
			end
		elseif state == "returning" then
			local step = deli(trail)
			entity.move_request = vec(-step.x, -step.y)
			if #trail == 0 then
				set_state(entity, "wandering")
				say(entity, "is back from the water.")
			end
		else
			entity.random_walk_timer -= 1
			if entity.random_walk_timer <= 0 then
				entity.random_walk_timer = rnd(MAX_RANDOM_WALK_TIME) // 1
				local step = random_land_step(dist, entity.grid_pos)
				if step then
					entity.move_request = step
					say(entity, "wanders " .. DIRECTIONS[step.x][step.y] .. ".")
				end
			end
		end
	end
end

---@type Mod
local mod = {
	register_systems = function()
		ctx.after_imports:register("walker_test_register_map_gen_hooks", "After", "core_register_map_gen_hooks",
			function(ctx)
				ctx.map_gen.generate_systems:register(
					"walker_test_water_distance", "After", "core_ocean", build_water_distance
				):register(
					"walker_test_spawn_walkers", "After", "walker_test_water_distance", spawn_walkers
				)
			end
		):register("walker_test_register_step", "After", "core_register_step",
			function(ctx)
				ctx.step_systems:register("walker_test_walkers", "Before", "core_apply_movement", update_walkers)
				:register("walker_test_report_movement", "After", "walker_test_walkers",
					function(ctx)
					end
				)
			end
		)
	end,
}

return mod
