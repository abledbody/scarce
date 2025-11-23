local insert = table.insert

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

---@class Entity
local m_entity = {}
m_entity.__index = m_entity

--- @param color integer
function m_entity:set_color(color)
	self.color = color
	self.sprite_ud = nil
end

--- @param coltab userdata
--- @param tile_size integer
function m_entity:draw(coltab, tile_size)
	if not self.sprite_ud then
		self.sprite_ud = get_spr(self.sprite_i):copy()
		color_in(self.sprite_ud, coltab, self.color)
	end
	
	local scr_pos = self.pos * tile_size
	spr(self.sprite_ud, scr_pos.x, scr_pos.y)
end

---@class EntityMap
local m_entity_map = {}
m_entity_map.__index = m_entity_map

--- @param key integer
--- @return userdata coords
function m_entity_map:to_coords(key)
	return vec(key % self.pitch, key // self.pitch)
end

--- @param pos userdata
--- @return integer key
function m_entity_map:to_key(pos)
	return self.pitch * pos.y + mid(pos.x, 0, self.pitch - 1)
end

--- @param pos userdata
--- @param sprite_i integer
--- @param color integer?
--- @param tooltip string?
--- @return Entity entity
function m_entity_map:new(pos, sprite_i, color, tooltip)
	--- @class Entity
	--- @field sprite_i integer
	--- @field color integer
	--- @field sprite_ud userdata?
	--- @field tooltip string?
	--- @field pos userdata
	local entity = {
		sprite_i = sprite_i,
		color = color or 7,
		tooltip = tooltip,
		pos = pos,
	}
	
	setmetatable(entity, m_entity)
	
	self:add(entity)
	
	return entity
end

--- @param coltab userdata
--- @param tile_size integer
function m_entity_map:draw(coltab, tile_size)
	for _,v in pairs(self.entities) do
		for _, entity in ipairs(v) do
			entity:draw(coltab, tile_size)
		end
	end
end

--- @param pos userdata
--- @return Entity[]?
function m_entity_map:get_tile(pos)
	return self.entities[self:to_key(pos)]
end

--- @param entity Entity
--- @param new_pos userdata
function m_entity_map:move_tile(entity, new_pos)
	self:remove(entity)
	entity.pos = vec(mid(new_pos.x, 0, self.pitch - 1), new_pos.y)
	self:add(entity)
end

--- @param entity Entity
function m_entity_map:add(entity)
	local entities = self.entities
	local key = self:to_key(entity.pos)
	if not entities[key] then
		entities[key] = {}
	end
	insert(entities[key], entity)
end

--- @param entity Entity
function m_entity_map:remove(entity)
	local entities = self.entities
	local key = self:to_key(entity.pos)
	assert(
		entities[key]
		and del(entities[key], entity),
		"Entity not found in map"
	)
	if #entities[key] == 0 then
		entities[key] = nil
	end
end

--- @param pitch integer
--- @return EntityMap
local function new_map(pitch)
	--- @class EntityMap
	--- @field entities table<integer, Entity[]>
	local map = {
		entities = {},
		pitch = pitch,
	}
	
	return setmetatable(map, m_entity_map)
end

return {
	new_map = new_map,
	color_in = color_in,
}
