local insert = table.insert

--- @param self EntityMap
--- @param key integer
--- @return userdata coords
local function to_coords(self, key)
	return vec(key % self.pitch, key // self.pitch)
end

--- @param self EntityMap
--- @param pos userdata
--- @return integer key
local function to_key(self, pos)
	return self.pitch * pos.y + mid(pos.x, 0, self.pitch - 1)
end

local function color_in(gfx, coltab, color)
	local cam_x, cam_y = camera()
	set_draw_target(gfx)
	memmap(coltab, 0x8000)
	poke(0x550b, 0x3f)
	rectfill(0, 0, gfx:width(), gfx:height() or 1, color)
	poke(0x550b, 0x00)
	unmap(coltab)
	set_draw_target()
	camera(cam_x, cam_y)
end
	

--- @param self Entity
--- @param coltab userdata
--- @param tile_size integer
local function draw(self, coltab, tile_size)
	local sprite = get_spr(self.sprite):copy()
	
	color_in(sprite, coltab, self.color)
	
	local scr_pos = self.pos * tile_size
	spr(sprite, scr_pos.x, scr_pos.y)
end

--- @param entity_map EntityMap
--- @param pos userdata
--- @param sprite integer
--- @param color integer?
--- @param tooltip string?
--- @return Entity entity
local function new(entity_map, pos, sprite, color, tooltip)
	--- @class Entity
	local entity = {
		sprite = sprite,
		color = color or 7,
		tooltip = tooltip,
		pos = pos,
		
		draw = draw,
	}
	
	entity_map:add(entity)
	
	return entity
end

--- @param self EntityMap
--- @param coltab userdata
--- @param tile_size integer
local function draw_all(self, coltab, tile_size)
	for _,v in pairs(self.entities) do
		for _, entity in ipairs(v) do
			entity:draw(coltab, tile_size)
		end
	end
end

--- @param self EntityMap
--- @param pos userdata
--- @return Entity[]?
local function get_tile(self, pos)
	return self.entities[self:to_key(pos)]
end

--- @param self EntityMap
--- @param entity Entity
--- @param new_pos userdata
local function move_tile(self, entity, new_pos)
	self:remove(entity)
	entity.pos = vec(mid(new_pos.x, 0, self.pitch - 1), new_pos.y)
	self:add(entity)
end

--- @param self EntityMap
--- @param entity Entity
local function add_to_map(self, entity)
	local entities = self.entities
	local key = to_key(self, entity.pos)
	if not entities[key] then
		entities[key] = {}
	end
	insert(entities[key], entity)
end

local function remove_from_map(self, entity)
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
local function new_map(pitch)
	--- @class EntityMap
	--- @field entities table<integer, Entity[]>
	local map = {
		entities = {},
		pitch = pitch,
		
		get = get_tile,
		add = add_to_map,
		remove = remove_from_map,
		move = move_tile,
		
		to_coords = to_coords,
		to_key = to_key,
		
		draw = draw_all,
	}
	
	return map
end

return {
	new = new,
	new_map = new_map,
	color_in = color_in,
}
