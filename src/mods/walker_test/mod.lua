local Things = require"core/src/things"

local SystemRegistry = require_ext"src/system_registry"
local hook = SystemRegistry.new_hook

local MAX_RANDOM_WALK_TIME = 3

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

---@param ctx MapGenerationContext
local function spawn_walkers(ctx)
	local game_ctx = ctx.game_ctx
	local map_config = ctx.res:get("config", "core_map")
	local map_w, map_h = map_config.size.x, map_config.size.y
	local tile_size = map_config.tile_size
	
	for _ = 1, 300 do
		local pos = vec(rnd(map_w), rnd(map_h)) // 1
		local sprite_name = rnd{"core_anthro_draconic", "core_anthro_canine"}
		
		ctx.entity_map:add(
			game_ctx.entities:instantiate{
				thing_renderer = Things.new_renderer(
					ctx.res:get("sprite", sprite_name),
					rnd(32) // 1
				),
				grid_pos = pos,
				display_pos = pos * tile_size,
				move_request = vec(0, 0),
				random_walk_timer = rnd(MAX_RANDOM_WALK_TIME),
				tooltip = rnd(sprite_name == "core_anthro_draconic" and random_draconic_names or random_canine_names)
					.. "\n\fmWalks randomly\n\fc"
					.. rnd(sprite_name == "core_anthro_draconic" and random_draconic_types or random_canine_types)
			}
		)
	end
end

---@param ctx Context
local function update_walkers(ctx)
	for entity in ctx.entities:query("random_walk_timer", "grid_pos") do
		entity.random_walk_timer -= 1/60
		if entity.random_walk_timer <= 0 then
			entity.random_walk_timer = rnd(MAX_RANDOM_WALK_TIME)
			entity.move_request = vec(rnd(3) - 1, rnd(3) - 1) // 1
		end
	end
end

---@type Mod
local mod = {
	register_systems = function()
		ctx.after_imports:register("walker_test_register_map_gen_hooks", "After", "core_register_map_gen_hooks",
			function(ctx)
				ctx.map_gen.generate_systems:register(
					"walker_test_spawn_walkers", "After", "core_init", spawn_walkers
				)
			end
		)
		
		ctx.updates:register("walker_random_walk", "Before", "core_apply_movement", update_walkers)
	end,
}

return mod