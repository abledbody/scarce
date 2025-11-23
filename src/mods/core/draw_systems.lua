---@type Hook[]
local hooks = {
	{system_key = "core_draw_clear", target_key = "draw", target_relation = "After", system = 
		function()
			cls()
		end
	},
	{system_key = "core_draw_viewport", target_key = "core_draw_clear", target_relation = "After", system = 
		function(ctx)
			local ui_cols = ctx.res:get"core_colors_ui"
			local ui_config = ctx.res:get"core_ui_config_map"
			local color_over = ctx.res:get"core_coltab_color_over"
			ctx.ui.game_viewport:draw(ctx.camera_pos, ui_cols)
			local viewport_translate = ctx.ui.game_viewport:screen_to_viewport(ctx.camera_pos)
			camera(viewport_translate.x, viewport_translate.y)
			ctx.ui.game_viewport:clip()
			ctx.entity_map:draw(color_over, ui_config.tile_size)
			clip()
			camera()
		end
	},
	{system_key = "core_draw_text_window", target_key = "core_draw_viewport", target_relation = "After", system =
		function(ctx)
			local ui_cols = ctx.res:get("core_colors_ui")
			ctx.ui.text_window:draw(ui_cols)
		end
	},
	{system_key = "core_draw_debug", target_key = "core_draw_text_window", target_relation = "After", system = 
		function()
			if btn(5) then get_display():bxor(get_display():shr(6), true) end
			
			print(string.format("\014\^o0ff\^-bcpu: %.2f%%", stat(1) * 100), 0, 0, 7)
		end
	},
}

return hooks