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

--- @param self Entity
--- @param color integer
local function set_color(self, color)
	self.color = color
	self.sprite_ud = nil
end

--- @param self Entity
--- @param coltab userdata
--- @param tile_size integer
local function draw(self, coltab, tile_size)
	if not self.sprite_ud then
		self.sprite_ud = get_spr(self.sprite_i):copy()
		color_in(self.sprite_ud, coltab, self.color)
	end
	
	local scr_pos = self.pos * tile_size
	spr(self.sprite_ud, scr_pos.x, scr_pos.y)
end

--- @param entity_map EntityMap
--- @param pos userdata
--- @param sprite_i integer
--- @param color integer?
--- @param tooltip string?
--- @return Entity entity
local function new(entity_map, pos, sprite_i, color, tooltip)
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
		
		draw = draw,
		set_color = set_color,
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

--- @param self EntityMap
--- @param entity Entity
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
--- @return EntityMap
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
