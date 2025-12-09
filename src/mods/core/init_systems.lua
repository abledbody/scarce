local SystemRegistry = require_ext"src/system_registry"
local UI = require"core/src/ui"
local new_graphics_data = require"core/src/graphics"
local new_bg_viewport = require"core/src/bg_viewport"
local new_game_viewport = require"core/src/game_viewport"
local new_text_window = require"core/src/text_window"
local new_tooltip = require"core/src/tooltip"
local Player = require"core/src/player"
local MapGeneration = require"core/src/map_gen"
local Ecs = require"core/src/ecs"
local Things = require"core/src/things"

local hook = SystemRegistry.new_hook

---@type Hook[]
local hooks = {
	hook("core_init", "After", "init", 
		function(ctx)
			window()
			
			---@class Context
			---@field graphics GraphicsData
			---@field camera_pos userdata
			---@field entities Entities
			---@field map_gen MapGenerator
			
			ctx.graphics = new_graphics_data()
			ctx.camera_pos = vec(0, 0)
			ctx.entities = Ecs.new()
			ctx.map_gen = MapGeneration.new()
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
			local viewport_config = ctx.res:get("config", "core_viewport")
			local map_config = ctx.res:get("config", "core_map")
			
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
				viewport_config.viewport_pos,
				new_bg_viewport(
					vec(viewport_config.viewport_columns, viewport_config.viewport_rows) * map_config.tile_size,
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
	
	hook("core_init_register_map_gen_hooks", "After", "resources_loaded", MapGeneration.register_core_hooks),
	
	hook("core_init_map", "After", "resources_loaded", 
		function(ctx)
			local map_config = ctx.res:get("config", "core_map")
			
			local map_context = ctx.map_gen:generate(ctx, {
				seed = math.random(2^53),
				size = map_config.size,
				basis_tile = ctx.res:get("tile", "core_grass_green"),
				
				ocean_size = 12,
				ocean_threshold = 0.55,
				
				desert_size = 6,
				desert_threshold = 1.7,
				
				beach_factor = 2.5,
			})
			
			---@class Context
			---@field map_data Map
			---@field entity_map EntityMap
			
			ctx.entity_map = map_context.entity_map
			ctx.map_data = map_context.map
			
			local color_over_coltab = ctx.res:get("coltab", "core_color_over")
			
			ctx.ui.draw_map = function()
				local map_data = ctx.map_data
				
				-- Draw the foreground with mask 1
				poke(0x5509, 0x7f)
				map(map_data[2].bmp)
				poke(0x5509, 0x3f)
				
				-- Color in the foreground
				memmap(color_over_coltab, 0x8000)
				map(map_data[1].bmp)
				unmap(color_over_coltab)
				
				-- Draw and color the background only where mask 1 is not set
				poke(0x550a, 0x7f)
				map(map_data[4].bmp)
				memmap(color_over_coltab, 0x8000)
				map(map_data[3].bmp)
				unmap(color_over_coltab)
				poke(0x550a, 0x3f)
			end
		end
	),
	
	hook("core_init_test_entities", "After", "resources_loaded", 
		function(ctx)
			---@class Context
			---@field player Entity
			
			ctx.entity_map:add(
				ctx.entities:instantiate{
					thing_renderer = Things.new_renderer(ctx.res:get("sprite", "core_drawstring_bag"), 25),
					grid_pos = vec(5, 5),
					tooltip = "T-shirt\n\fmA comfy shirt to wear.\n\fnFlammable\n\fnWearable\n\fcCloth"
				}
			)
			ctx.player = Player.new(ctx, vec(10, 10))
		end
	),
}

return hooks