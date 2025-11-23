local fmt = string.format
local UI = require"core/src/ui"
local new_graphics_data = require"core/src/graphics"
local new_bg_viewport = require"core/src/bg_viewport"
local new_game_viewport = require"core/src/game_viewport"
local new_text_window = require"core/src/text_window"
local Entities = require"core/src/entities"

---@type Hook[]
local hooks = {
	{system_key = "core_init", target_key = "init", target_relation = "After", system = 
		function(ctx)
			window()
			
			---@class Context
			---@field graphics GraphicsData
			---@field camera_pos userdata
			
			ctx.graphics = new_graphics_data()
			ctx.camera_pos = vec(0, 0)
		end
	},
	{system_key = "core_resource_registration", target_key = "core_init", target_relation = "After", system =
		function (ctx)
			for _, mod in ipairs(ctx.mods) do
				if mod.resources then
					for _, resource in ipairs(mod.resources) do
						if ctx.res:register(ctx, resource) then
							printh("Registered resource: " .. resource.key)
						else
							printh(fmt("Failed to find resource \"%s\" with \"%s\"", resource.key, tostring(resource.value)))
						end
					end
				end
			end
		end
	},
	{system_key = "core_init_palette", target_key = "core_resource_registration", target_relation = "After", system =
		function(ctx)
			ctx.res:get"core_palette":poke(0x5000)
		end
	},
	{system_key = "core_init_font", target_key = "core_resource_registration", target_relation = "After", system =
		function(ctx)
			ctx.res:get"core_font_charcoal":poke(0x4000)
		end
	},
	{system_key = "core_init_ui", target_key = "core_resource_registration", target_relation = "After", system =
		function (ctx)
			local ui_config = ctx.res:get"core_ui_config_map"
			
			---@class Context
			---@field ui UIData
			
			---@class UIData
			---@field bg_viewport BackgroundViewport
			---@field game_viewport GameViewport
			---@field draw_map function
			---@field text_window TextWindow
			ctx.ui = {}
			
			ctx.ui.bg_viewport = new_bg_viewport(
				vec(ui_config.viewport_columns, ui_config.viewport_rows) * ui_config.tile_size,
				function() return ctx.ui.draw_map() end
			)
			ctx.ui.game_viewport = new_game_viewport(
				ui_config.viewport_pos,
				ctx.ui.bg_viewport
			)
			
			local screen_w, screen_h = get_display():attribs()
			
			local text_window_x = ctx.ui.game_viewport.size.x + UI.BORDER_WIDTH * 3
			ctx.ui.text_window = new_text_window(
				vec(text_window_x, UI.BORDER_WIDTH),
				vec(screen_w - text_window_x - UI.BORDER_WIDTH, screen_h - UI.BORDER_WIDTH * 2),
				9,
				500
			)
		end
	},
	{system_key = "core_init_map", target_key = "core_resource_registration", target_relation = "After", system =
		function(ctx)
			local map_data = ctx.res:get"core_map_test"
			local bg_map_bmp = map_data[4].bmp
			local bg_map_cols = map_data[3].bmp
			local fg_map_bmp = map_data[2].bmp
			local fg_map_cols = map_data[1].bmp
			local color_over_coltab = ctx.res:get"core_coltab_color_over"
			
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
	},
	{system_key = "core_init_entity_map", target_key = "core_resource_registration", target_relation = "After", system = 
		function(ctx)
			local ui_config = ctx.res:get"core_ui_config_map"
			
			---@class Context
			---@field entity_map EntityMap
			
			ctx.entity_map = Entities.new_map(ui_config.map_width)
			ctx.entity_map:new(
				vec(5,5),
				4,
				25,
				"T-shirt\n\fmA comfy shirt to wear.\n\fnFlammable\n\fnWearable\n\fcCloth"
			)
		end
	},
}

return hooks