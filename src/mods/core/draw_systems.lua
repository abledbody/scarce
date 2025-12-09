local Things = require"core/src/things"
local SystemRegistry = require_ext"src/system_registry"
local hook = SystemRegistry.new_hook

---@type Hook[]
local hooks = {
	hook("core_draw_clear", "After", "draw",
		function()
			cls()
		end
	),
	
	hook("core_draw_viewport", "After", "core_draw_clear",
		function(ctx)
			local ui_cols = ctx.res:get("config", "core_ui_colors")
			
			ctx.ui.viewport:draw(ctx.camera_pos, ui_cols)
			
			local viewport_translate = ctx.ui.viewport:screen_to_viewport(ctx.camera_pos)
			camera(viewport_translate.x, viewport_translate.y)
			ctx.ui.viewport:clip()
		end
	),
	
	hook("core_draw_things", "After", "core_draw_viewport", Things.draw),
	
	hook("core_clear_viewport_clip", "After", "core_draw_viewport",
		function()
			clip()
			camera()
		end
	),
	
	hook("core_draw_text_window", "After", "core_draw_clear",
		function(ctx)
			ctx.ui.text_window:draw(ctx.res)
		end
	),
	
	hook("core_draw_tooltip", "After", "core_draw_text_window",
		function(ctx)
			ctx.ui.tooltip:draw()
		end
	),
	
	hook("core_draw_debug", "After", "core_draw_clear",
		function()
			if btn(5) then get_display():bxor(get_display():shr(6), true) end
			
			print(string.format("\014\^o0ff\^-bcpu: %.2f%%", stat(1) * 100), 0, 0, 7)
		end
	),
}

return hooks