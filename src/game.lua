include"src/require.lua"

-------------------------------------Dependencies--------------------------------------

local m_tooltip = require("src/tooltip")
local m_mouse = require("src/mouse")
local m_entities = require("src/entities")
local m_bg_viewport = require("src/bg_viewport")
local m_intersection = require("src/intersection")
local m_player = require("src/player")

---------------------------------------Constants---------------------------------------

local MAP_WIDTH = 32
local TILE_SIZE = get_spr(0):width()
local VIEWPORT_COLUMNS = 30
local VIEWPORT_ROWS = 15

--------------------------------------Game State---------------------------------------

local game --- @type GameState

--- @param entity_map EntityMap
--- @param cam_pos userdata
--- @param player Player
--- @param map_viewport BackgroundViewport
--- @return GameState
local function new_game(
	entity_map,
	cam_pos,
	player,
	map_viewport,
	color_over_coltab
)
	--- @class GameState
	local gameState = {
		tooltip = m_tooltip.new(),
		entity_map = entity_map,
		cam_pos = cam_pos,
		dragging_viewport = false,
		player = player,
		map_viewport = map_viewport,
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
		
	local map_viewport = m_bg_viewport.new(
		vec(VIEWPORT_COLUMNS * TILE_SIZE, VIEWPORT_ROWS * TILE_SIZE),
		draw_map
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
		map_viewport,
		color_over_coltab
	)
end

function _update()
	m_mouse.frame_start()
	
	local entity_map = game.entity_map
	
	game.player:interpret_inputs(entity_map)
	game.player:animate(TILE_SIZE)
	
	local mouse_pos = m_mouse.position()
	local mouse_map_coords = (mouse_pos + game.cam_pos) // TILE_SIZE --- @type userdata
	
	local mouse_in_viewport =
		m_intersection.point_aabb(mouse_pos, vec(0,0), game.map_viewport.size)
	local entity = mouse_in_viewport
		and entity_map:get(mouse_map_coords) or nil
	
	game.tooltip:set_text(entity and entity[1] and entity[1].tooltip)
	game.tooltip:set_pos(mouse_pos)
	
	local last_cam_pos = game.cam_pos:copy()
	
	game.dragging_viewport = mouse_in_viewport and m_mouse.down(1) 
		or game.dragging_viewport
		and not m_mouse.up(1)
	
	if game.dragging_viewport then
		game.cam_pos -= m_mouse.delta()
	end
	
	game.map_viewport:move_view(game.cam_pos, last_cam_pos)
end

function _draw()
	cls(0)
	
	game.map_viewport:draw(vec(0, 0), game.cam_pos)
	clip(0, 0, VIEWPORT_COLUMNS * TILE_SIZE, VIEWPORT_ROWS * TILE_SIZE)
	camera(game.cam_pos.x, game.cam_pos.y)
	game.entity_map:draw(game.color_over_coltab, TILE_SIZE)
	camera()
	clip()
	game.tooltip:draw()
	
	--- @diagnostic disable-next-line: err-esc
	print(string.format("\014\^o1ff\^-bcpu: %.2f%%", stat(1) * 100), 0, 0, 7)
end

include"src/error_explorer.lua"