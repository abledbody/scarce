---@diagnostic disable: redefined-local

local Things = require"core/src/things"

---@param hook fun(key: string, target_relation: "Before"|"After", target_key: string, system: fun(ctx: Context))
local function register(hook)
	hook("core_clear", "After", "root",
		function()
			cls()
		end
	)
	
	hook("core_viewport", "After", "core_clear",
		function(ctx)
			local ui_cols = ctx.res:get("config", "core_ui_colors")
			
			ctx.ui.viewport:draw(ctx.camera_pos, ui_cols)
			
			local viewport_translate = ctx.ui.viewport:screen_to_viewport(ctx.camera_pos)
			camera(viewport_translate.x, viewport_translate.y)
			ctx.ui.viewport:clip()
		end
	)
	
	hook("core_things", "After", "core_viewport", Things.draw)
	
	hook("core_clear_viewport_clip", "After", "core_viewport",
		function()
			clip()
			camera()
		end
	)
	
	hook("core_text_window", "After", "core_clear",
		function(ctx)
			ctx.ui.text_window:draw(ctx.res)
		end
	)
	
	hook("core_tooltip", "After", "core_text_window",
		function(ctx)
			ctx.ui.tooltip:draw()
		end
	)
	
	hook("core_debug", "After", "core_clear",
		function()
			if btn(5) then get_display():bxor(get_display():shr(6), true) end
			
			print(string.format("\014\^o0ff\^-bcpu: %.2f%%", stat(1) * 100), 0, 0, 7)
		end
	)
end

return {
	register = register,
}