local Entities = require("core/src/entities")
local Math = require("core/src/math")
local lerp = Math.lerp

local PLAYER_COLOR = 4

---@class Player
local m_player = {}
m_player.__index = m_player

---@param self Player
---@param entity_map EntityMap
function m_player:interpret_inputs(entity_map)
	local dest = self.entity.pos
	dest += vec(
		(keyp("d") and 1 or 0) - (keyp("a") and 1 or 0),
		(keyp("s") and 1 or 0) - (keyp("w") and 1 or 0)
	)
	
	if dest.x == self.entity.pos.x and dest.y == self.entity.pos.y then return end
	
	entity_map:move(self.entity, dest)
end

---@param self Player
---@param tile_size integer
function m_player:animate(tile_size)
	self.display_pos = lerp(self.display_pos, self.entity.pos * tile_size + 0.5, 0.4)
end

---@param res ResourceRegistry
---@param entity_map EntityMap
---@param pos userdata
---@param color_over_coltab userdata
---@param tile_size integer
---@return Player
local function new(res, entity_map, pos, color_over_coltab, tile_size)
	local sprite = res:get("sprite", "core_anthro_canine")
	---@class Player
	local player = {
		display_pos = pos * tile_size,
		entity = entity_map:new(pos, sprite, PLAYER_COLOR)
	}
	
	player.entity.draw = function(self)
		if not self.sprite_ud then
			self.sprite_ud = get_spr(self.sprite_i):copy()
			Entities.color_in(self.sprite_ud, color_over_coltab, self.color)
		end
		spr(self.sprite_ud, player.display_pos.x, player.display_pos.y)
	end
	
	return setmetatable(player, m_player)
end

return new