local insert = table.insert
local Math = require"core/src/math"
local lerp = Math.lerp

--- @param gfx userdata
--- @param coltab userdata
--- @param color integer
local function color_in(gfx, coltab, color)
	local cam_x, cam_y = camera()
	local cx, cy, cw, ch = clip()
	set_draw_target(gfx)
	memmap(coltab, 0x8000)
	poke(0x550b, 0x3f)
		
	rectfill(0, 0, gfx:width(), gfx:height() or 1, color)
	
	poke(0x550b, 0x00)
	unmap(coltab)
	set_draw_target()
	clip(cx, cy, cw, ch)
	camera(cam_x, cam_y)
end

local function new_renderer(sprite_i, color)
	return {
		sprite_ud = nil,
		sprite_i = sprite_i,
		color = color,
	}
end

---@class EntityMap
local m_entity_map = {}
m_entity_map.__index = m_entity_map

--- @param key integer
--- @return userdata coords
function m_entity_map:to_coords(key)
	return vec(key % self.size.x, key // self.size.x)
end

--- @param pos userdata
--- @return integer key
function m_entity_map:to_key(pos)
	return self.size.x * pos.y + mid(pos.x, 0, self.size.x - 1)
end

--- @param pos userdata
--- @return Entity[]?
function m_entity_map:get(pos)
	return self.entities[self:to_key(pos)]
end

--- @param entity Entity
--- @param new_pos userdata
function m_entity_map:move(entity, new_pos)
	self:remove(entity)
	entity.grid_pos = vec(mid(new_pos.x, 0, self.size.x - 1), mid(new_pos.y, 0, self.size.y - 1))
	self:add(entity)
end

--- @param entity Entity
function m_entity_map:add(entity)
	local entities = self.entities
	local key = self:to_key(entity.grid_pos)
	if not entities[key] then
		entities[key] = {}
	end
	insert(entities[key], entity)
	return entity
end

--- @param entity Entity
function m_entity_map:remove(entity)
	local entities = self.entities
	local key = self:to_key(entity.grid_pos)
	assert(
		entities[key]
		and del(entities[key], entity),
		"Entity not found in map"
	)
	if #entities[key] == 0 then
		entities[key] = nil
	end
end

--- @param size userdata
--- @return EntityMap
local function new_map(size)
	--- @class EntityMap
	--- @field entities table<integer, Entity[]>
	local map = {
		entities = {},
		size = size,
	}
	
	return setmetatable(map, m_entity_map)
end

----------------------------------------Systems----------------------------------------

local function draw(ctx)
	local color_over = ctx.res:get("coltab", "core_color_over")
	local map_config = ctx.res:get("config", "core_map")
	
	for entity in ctx.entities:query("thing_renderer", "grid_pos") do
		local thing_renderer = entity.thing_renderer
		
		if not thing_renderer.sprite_ud then
			thing_renderer.sprite_ud = get_spr(thing_renderer.sprite_i):copy()
			color_in(thing_renderer.sprite_ud, color_over, thing_renderer.color)
		end
		
		local scr_pos = entity.display_pos or entity.grid_pos * map_config.tile_size
		spr(thing_renderer.sprite_ud, scr_pos.x, scr_pos.y)
	end
end

---@param ctx Context
local function apply_movement(ctx)
	for entity in ctx.entities:query("grid_pos", "move_request") do
		ctx.entity_map:move(entity, entity.grid_pos + entity.move_request)
		entity.move_request = nil
	end
end

---@param ctx Context
local function animate_movement(ctx)
	local tile_size = ctx.res:get("config", "core_map").tile_size
	for entity in ctx.entities:query("display_pos", "grid_pos") do
		entity.display_pos = lerp(entity.display_pos, entity.grid_pos * tile_size + 0.5, 0.4)
	end
end

return {
	color_in = color_in,
	new_renderer = new_renderer,
	draw = draw,
	new_map = new_map,
	apply_movement = apply_movement,
	animate_movement = animate_movement,
}