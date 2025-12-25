local Things = require"core/src/things"

local PLAYER_COLOR = 4

---@class Player
local m_player = {}
m_player.__index = m_player

local function interpret_inputs(ctx)
	local move_request = vec(
		(keyp("d") and 1 or 0) - (keyp("a") and 1 or 0),
		(keyp("s") and 1 or 0) - (keyp("w") and 1 or 0)
	)
	
	for entity in ctx.entities:query("player") do
		if move_request.x != 0 or move_request.y != 0 then
			entity.move_request = move_request
		end
	end
end

---@param ctx Context
---@param pos userdata
---@return Entity
local function new(ctx, pos)
	local sprite = ctx.res:get("sprite", "core_anthro_canine")
	local tile_size = ctx.res:get("config", "core_map").tile_size
		
	return ctx.entity_map:add(
		ctx.entities:instantiate{
			display_pos = pos * tile_size,
			grid_pos = pos,
			thing_renderer = Things.new_renderer(
				sprite,
				PLAYER_COLOR
			),
			move_request = vec(0, 0),
			player = true
		}
	)
end

return {
	new = new,
	interpret_inputs = interpret_inputs
}