local SystemRegistry = require_ext"src/system_registry"
local UI = require"core/src/ui"
local new_graphics_data = require"core/src/graphics"
local new_bg_viewport = require"core/src/bg_viewport"
local new_game_viewport = require"core/src/game_viewport"
local new_text_window = require"core/src/text_window"
local Entities = require"core/src/entities"
local new_tooltip = require"core/src/tooltip"
local new_player = require"core/src/player"

local hook = SystemRegistry.new_hook

---@type Hook[]
local hooks = {
	hook("core_init", "After", "init", 
		function(ctx)
			window()
			
			---@class Context
			---@field graphics GraphicsData
			---@field camera_pos userdata
			
			ctx.graphics = new_graphics_data()
			ctx.camera_pos = vec(0, 0)
		end
	),
	
	hook("core_init_palette", "After", "resources_loaded", 
		function(ctx)
			ctx.res:get("pal", "core_main"):poke(0x5000)
		end
	),
	
	hook("core_init_font", "After", "resources_loaded", 
		function(ctx)
			ctx.res:get("font", "core_charcoal"):poke(0x4000)
		end
	),
	
	hook("core_init_ui", "After", "resources_loaded", 
		function (ctx)
			local ui_config = ctx.res:get("config", "core_ui_map")
			
			---@class Context
			---@field ui UIData
			
			---@class UIData
			---@field bg_viewport BackgroundViewport
			---@field viewport GameViewport
			---@field draw_map function
			---@field text_window TextWindow
			---@field tooltip Tooltip
			ctx.ui = {}
			
			ctx.ui.viewport = new_game_viewport(
				ui_config.viewport_pos,
				new_bg_viewport(
					vec(ui_config.viewport_columns, ui_config.viewport_rows) * ui_config.tile_size,
					function() return ctx.ui.draw_map() end
				)
			)
			
			local screen_w, screen_h = get_display():attribs()
			
			local text_window_x = ctx.ui.viewport.size.x + UI.BORDER_WIDTH * 3
			ctx.ui.text_window = new_text_window(
				vec(text_window_x, UI.BORDER_WIDTH),
				vec(screen_w - text_window_x - UI.BORDER_WIDTH, screen_h - UI.BORDER_WIDTH * 2),
				9,
				500
			)
			
			ctx.ui.tooltip = new_tooltip()
		end
	),
	
	hook("core_init_map", "After", "resources_loaded", 
		function(ctx)
			local map_data = ctx.res:get("map", "core_test")
			local bg_map_bmp = map_data[4].bmp
			local bg_map_cols = map_data[3].bmp
			local fg_map_bmp = map_data[2].bmp
			local fg_map_cols = map_data[1].bmp
			local color_over_coltab = ctx.res:get("coltab", "core_color_over")
			
			ctx.ui.draw_map = function()
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
		end
	),
	
	hook("core_init_entity_map", "After", "resources_loaded", 
		function(ctx)
			local ui_config = ctx.res:get("config", "core_ui_map")
			
			---@class Context
			---@field entity_map EntityMap
			
			ctx.entity_map = Entities.new_map(ui_config.map_width)
		end
	),
	
	hook("core_init_test_entities", "After", "resources_loaded", 
		function(ctx)
			local ui_config = ctx.res:get("config", "core_ui_map")
			local color_over_coltab = ctx.res:get("coltab", "core_color_over")
			
			---@class Context
			---@field player Player
			
			ctx.entity_map:new(
				vec(5,5),
				ctx.res:get("sprite", "core_drawstring_bag"),
				25,
				"T-shirt\n\fmA comfy shirt to wear.\n\fnFlammable\n\fnWearable\n\fcCloth"
			)
			ctx.player = new_player(ctx.res, ctx.entity_map, vec(10, 10), color_over_coltab, ui_config.tile_size)
		end
	),
}

return hooks