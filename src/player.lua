local m_entities = require("src/entities")
local m_math = require("src/math")
local lerp = m_math.lerp

local PLAYER_SPRITE = 5
local PLAYER_COLOR = 4

--- @param self Player
--- @param entity_map EntityMap
local function interpret_inputs(self, entity_map)
	local dest = self.entity.pos
	dest += vec(
		(keyp("d") and 1 or 0) - (keyp("a") and 1 or 0),
		(keyp("s") and 1 or 0) - (keyp("w") and 1 or 0)
	)
	
	if dest.x == self.entity.pos.x and dest.y == self.entity.pos.y then return end
	
	entity_map:move(self.entity, dest)
end

--- @param self Player
--- @param tile_size integer
local function animate(self, tile_size)
	self.display_pos = lerp(self.display_pos, self.entity.pos * tile_size + 0.5, 0.4)
end

--- @param entity_map EntityMap
--- @param pos userdata
--- @param color_over_coltab userdata
--- @param tile_size integer
--- @return Player
local function new(entity_map, pos, color_over_coltab, tile_size)
	--- @class Player
	local player = {
		display_pos = pos * tile_size,
		entity = m_entities.new(entity_map, pos, PLAYER_SPRITE, PLAYER_COLOR),
		
		interpret_inputs = interpret_inputs,
		animate = animate,
	}
	
	player.entity.draw = function(self)
		local sprite = get_spr(self.sprite_i):copy()
		m_entities.color_in(sprite, color_over_coltab, self.color)
		spr(sprite, player.display_pos.x, player.display_pos.y)
	end
	
	return player
end

return {
	new = new,
}
