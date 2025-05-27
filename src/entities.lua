local insert = table.insert

--- @param self EntityMap
--- @param key integer
--- @return integer, integer
local function to_coords(self, key)
	return key % self.pitch, key // self.pitch
end

--- @param self EntityMap
--- @param x integer
--- @param y integer
--- @return integer
local function to_key(self, x, y)
	return self.pitch * y + x
end

--- @param self Entity
--- @param x integer
--- @param y integer
local function draw(self, x, y)
	pal(7, self.color)
	spr(self.sprite, x, y)
	pal(7, 7)
end

--- @param sprite integer
--- @param color integer?
--- @param tooltip string?
local function new(sprite, color, tooltip)
	--- @class Entity
	local entity = {
		sprite = sprite,
		color = color or 7,
		tooltip = tooltip,
		
		draw = draw,
	}
	
	return entity
end

--- @param self EntityMap
local function draw_all(self)
	for k,v in pairs(self.entities) do
		local x, y = self:to_coords(k)
		x *= 16
		y *= 16
		
		for _, entity in ipairs(v) do
			entity:draw(x, y)
		end
	end
end

--- @param self EntityMap
--- @param entity Entity
--- @param x integer
--- @param y integer
local function add_to_map(self, entity, x, y)
	local entities = self.entities
	local key = to_key(self, x, y)
	if not entities[key] then
		entities[key] = {}
	end
	insert(entities[key], entity)
end

--- @param pitch integer
local function new_map(pitch)
	--- @class EntityMap
	--- @field entities table<integer, Entity[]>
	local map = {
		entities = {},
		pitch = pitch,
		
		add = add_to_map,
		to_coords = to_coords,
		to_key = to_key,
		draw_all = draw_all,
	}
	
	return map
end

return {
	new = new,
	new_map = new_map,
}
