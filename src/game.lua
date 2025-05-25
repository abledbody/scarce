include"src/require.lua"

-------------------------------------Dependencies--------------------------------------

local m_tooltip = require("src/tooltip")
local m_mouse = require("src/mouse")

--------------------------------------Game State---------------------------------------

local game --- @type GameState

---@return GameState
local function new_game()
	--- @class GameState
	local gameState = {
		tooltip = m_tooltip.new(),
	}
	return gameState
end

----------------------------------Picotron Callbacks-----------------------------------

function _init()
	window {}
	game = new_game()
	game.tooltip:set_text("T-shirt\n\fmA comfy shirt to wear.\n\fnFlammable\n\fnWearable\n\fcCloth")
end

function _update()
	m_mouse.frame_start()
	
	game.tooltip:set_pos(m_mouse.position())
end

function _draw()
	cls(0)
	
	game.tooltip:draw()
end

include"src/error_explorer.lua"