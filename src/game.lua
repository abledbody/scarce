include"src/require.lua"

-------------------------------------Dependencies--------------------------------------

local m_tooltip = require("src/tooltip")
local m_mouse = require("src/mouse")
local m_entities = require("src/entities")
local m_bg_viewport = require("src/bg_viewport")
local m_game_viewport = require("src/game_viewport")
local m_player = require("src/player")
local m_math = require("src/math")

---------------------------------------Constants---------------------------------------

local MAP_WIDTH = 32
local TILE_SIZE = get_spr(0):width()
local VIEWPORT_COLUMNS = 15
local VIEWPORT_ROWS = 15
local VIEWPORT_POS = vec(0, 0)

--------------------------------------Game State---------------------------------------

local game --- @type GameState

--- @param entity_map EntityMap
--- @param cam_pos userdata
--- @param player Player
--- @param game_viewport GameViewport
--- @param color_over_coltab userdata
--- @return GameState
local function new_game(
	entity_map,
	cam_pos,
	player,
	game_viewport,
	color_over_coltab
)
	--- @class GameState
	local gameState = {
		tooltip = m_tooltip.new(),
		entity_map = entity_map,
		cam_pos = cam_pos,
		player = player,
		viewport = game_viewport,
		color_over_coltab = color_over_coltab,
	}
	return gameState
end

----------------------------------Picotron Callbacks-----------------------------------

function _init()
	window {}
	local map_data = fetch(DATP.."map/0.map")
	local map_bmp = map_data[2].bmp
	local map_cols = map_data[1].bmp
	local color_over_coltab = get_spr(192)
	local function draw_map()
		map(map_bmp)
		memmap(color_over_coltab, 0x8000)
		map(map_cols)
		unmap(color_over_coltab)
	end
		
	local bg_viewport = m_bg_viewport.new(
		vec(VIEWPORT_COLUMNS, VIEWPORT_ROWS) * TILE_SIZE,
		draw_map
	)
	local game_viewport = m_game_viewport.new(
		VIEWPORT_POS,
		bg_viewport
	)
	
	local entity_map = m_entities.new_map(MAP_WIDTH)
	m_entities.new(
		entity_map,
		vec(5,5),
		4,
		25,
		"T-shirt\n\fmA comfy shirt to wear.\n\fnFlammable\n\fnWearable\n\fcCloth"
	)
	
	game = new_game(
		entity_map,
		vec(0, 0),
		m_player.new(entity_map, vec(10, 10), color_over_coltab, TILE_SIZE),
		game_viewport,
		color_over_coltab
	)
end

function _update()
	m_mouse.frame_start()
	
	local entity_map = game.entity_map
	
	game.player:interpret_inputs(entity_map)
	game.player:animate(TILE_SIZE)
	
	local mouse_pos = m_mouse.position()
	local mouse_map_coords =
		(game.viewport:screen_to_viewport(mouse_pos) + game.cam_pos - 1) // TILE_SIZE
		
	local entity = game.viewport:point_inside(mouse_pos)
		and entity_map:get(mouse_map_coords) or nil
	
	game.tooltip:set_text(entity and entity[1] and entity[1].tooltip)
	game.tooltip:set_pos(mouse_pos)
	
	local last_cam_pos = game.cam_pos:copy()
	
	game.cam_pos = m_math.lerp(
		game.cam_pos,
		(game.player.entity.pos + 0.5) * TILE_SIZE - game.viewport.bg.size * 0.5 + 0.5,
		0.2
	)
	
	game.viewport.bg:move_view(game.cam_pos, last_cam_pos)
end

function _draw()
	cls(0)
	
	game.viewport:draw(game.cam_pos)
	local viewport_translate = game.viewport:screen_to_viewport(game.cam_pos)
	camera(viewport_translate.x, viewport_translate.y)
	game.viewport:clip()
	game.entity_map:draw(game.color_over_coltab, TILE_SIZE)
	clip()
	camera()
	game.tooltip:draw()
	
	--- @diagnostic disable-next-line: err-esc
	print(string.format("\014\^o1ff\^-bcpu: %.2f%%", stat(1) * 100), 0, 0, 7)
end

include"src/error_explorer.lua"