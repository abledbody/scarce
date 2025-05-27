include"src/require.lua"

-------------------------------------Dependencies--------------------------------------

local m_tooltip = require("src/tooltip")
local m_mouse = require("src/mouse")
local m_entities = require("src/entities")

---------------------------------------Constants---------------------------------------

MAP_WIDTH = 64

--------------------------------------Game State---------------------------------------

local game --- @type GameState

---@return GameState
local function new_game()
	--- @class GameState
	local gameState = {
		tooltip = m_tooltip.new(),
		entity_map = m_entities.new_map(MAP_WIDTH),
		cam_pos = vec(0, 0),
	}
	return gameState
end

----------------------------------Picotron Callbacks-----------------------------------

function _init()
	window {}
	game = new_game()
	
	game.entity_map:add(
		m_entities.new(
			4,
			25,
			"T-shirt\n\fmA comfy shirt to wear.\n\fnFlammable\n\fnWearable\n\fcCloth"
		), 5, 5
	)
end

function _update()
	m_mouse.frame_start()
	
	local mouse_pos = m_mouse.position()
	local mouse_map_coords = (mouse_pos + game.cam_pos) // 16
	
	local entity_map = game.entity_map
	local entity = entity_map.entities[entity_map:to_key(mouse_map_coords.x, mouse_map_coords.y)]
	
	game.tooltip:set_text(entity and entity[1] and entity[1].tooltip)
	
	game.tooltip:set_pos(mouse_pos)
end

function _draw()
	cls(0)
	camera(game.cam_pos.x, game.cam_pos.y)
	
	game.entity_map:draw_all()
	
	game.tooltip:draw()
	camera()
	
	--- @diagnostic disable-next-line: err-esc
	print(string.format("\014\^o1ff\^-bcpu: %.2f%%", stat(1) * 100), 0, 0, 7)
end

include"src/error_explorer.lua"