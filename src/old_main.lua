include"src/require.lua"

-------------------------------------Dependencies--------------------------------------

local m_tooltip = require"src/tooltip"
local m_mouse = require"src/mouse"
local m_entities = require"src/entities"
local m_bg_viewport = require"src/bg_viewport"
local m_game_viewport = require"src/game_viewport"
local m_player = require"src/player"
local m_math = require"src/math"
local m_ui = require"src/ui"
local m_text_window = require"src/text_window"
local m_registry = require"src/registry"
local load_mods = require"src/load_mods"

---------------------------------------Constants---------------------------------------

local MAP_WIDTH <const> = 32
local TILE_SIZE <const> = get_spr(0):width() ---@type integer
local VIEWPORT_COLUMNS <const> = 15
local VIEWPORT_ROWS <const> = 15
local VIEWPORT_POS <const> = vec(3, 3)

--------------------------------------Game State---------------------------------------

local game --- @type GameState

--- @param entity_map EntityMap
--- @param cam_pos userdata
--- @param player Player
--- @param game_viewport GameViewport
--- @param color_over_coltab userdata
--- @param text_window TextWindow
--- @return GameState
local function new_game(
	entity_map,
	cam_pos,
	player,
	game_viewport,
	text_window,
	color_over_coltab
)
	--- @class GameState
	local gameState = {
		tooltip = m_tooltip.new(),
		entity_map = entity_map,
		cam_pos = cam_pos,
		player = player,
		viewport = game_viewport,
		text_window = text_window,
		color_over_coltab = color_over_coltab,
	}
	return gameState
end

----------------------------------Picotron Callbacks-----------------------------------

function _init()
	load_mods()
	window()
	local screen_w, screen_h = get_display():attribs()
	fetch(DATP .. "pal/0.pal"):poke(0x5000)
	fetch(DATP .. "font/0.font"):poke(0x4000)
	
	local map_data = fetch(DATP.."map/0.map")
	local bg_map_bmp = map_data[4].bmp
	local bg_map_cols = map_data[3].bmp
	local fg_map_bmp = map_data[2].bmp
	local fg_map_cols = map_data[1].bmp
	local color_over_coltab = get_spr(192)
	local function draw_map()
		-- Draw the foreground with mask 1
		poke(0x5509, 0x7f)
		map(fg_map_bmp)
		poke(0x5509, 0x3f)
		
		-- Color in the foreground
		memmap(color_over_coltab, 0x8000)
		map(fg_map_cols)
		unmap(color_over_coltab)
		
		-- Draw and color the background only where mask 1 is not set
		poke(0x550a, 0x7f)
		map(bg_map_bmp)
		memmap(color_over_coltab, 0x8000)
		map(bg_map_cols)
		unmap(color_over_coltab)
		poke(0x550a, 0x3f)
	end
	
	local bg_viewport = m_bg_viewport.new(
		vec(VIEWPORT_COLUMNS, VIEWPORT_ROWS) * TILE_SIZE,
		draw_map
	)
	local game_viewport = m_game_viewport.new(
		VIEWPORT_POS,
		bg_viewport
	)
	
	local text_window_x = game_viewport.size.x + m_ui.BORDER_WIDTH * 3
	local text_window = m_text_window.new(
		vec(text_window_x, m_ui.BORDER_WIDTH),
		vec(screen_w - text_window_x - m_ui.BORDER_WIDTH, screen_h - m_ui.BORDER_WIDTH * 2),
		9,
		500
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
		text_window,
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
	
	game.text_window:scroll(m_mouse.scroll_delta().y * -5)
	
	if btnp(4) then
		local foo = ""
		local last_word = ""
		for i = 1, rnd(60) + 3 do
			local new_word
			repeat
				new_word = rnd{"has", "anyone", "really", "been", "far", "even", "as", "decided", "to", "use", "go", "want", "do", "look", "more", "like"}
			until(last_word ~= new_word)
			if i == 1 then new_word = string.upper(new_word[1]) .. new_word:sub(2) end
			foo = foo .. " " .. new_word
			last_word = new_word
		end
		game.text_window:push(foo .. "?")
	end
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
	game.text_window:draw()
	game.text_window:draw()
	game.tooltip:draw()
	
	if btn(5) then get_display():bxor(get_display():shr(6), true) end
	
	--- @diagnostic disable-next-line: err-esc
	print(string.format("\014\^o1ff\^-bcpu: %.2f%%", stat(1) * 100), 0, 0, 7)
end

include"src/error_explorer.lua"