local Mouse = require"core/src/mouse"
local Math = require"core/src/math"

---@type Hook[]
local hooks = {
	{system_key = "core_update_mouse", target_key = "update", target_relation = "After", system = 
		function()
			Mouse.frame_start()
		end
	},
	{system_key = "core_update_player", target_key = "update", target_relation = "After", system = 
		function(ctx)
			local ui_config = ctx.res:get("config", "core_ui_map")
			ctx.player:interpret_inputs(ctx.entity_map)
			ctx.player:animate(ui_config.tile_size)
		end
	},
	{system_key = "core_update_tooltip", target_key = "update", target_relation = "After", system = 
		function(ctx)
			local ui_config = ctx.res:get("config", "core_ui_map")
			local mouse_pos = Mouse.position()
			local mouse_map_coords =
				(ctx.ui.viewport:screen_to_viewport(mouse_pos) + ctx.camera_pos - 1) // ui_config.tile_size
				
			local entity = ctx.ui.viewport:point_inside(mouse_pos)
				and ctx.entity_map:get(mouse_map_coords) or nil
			
			ctx.ui.tooltip:set_text(entity and entity[1] and entity[1].tooltip)
			ctx.ui.tooltip:set_pos(mouse_pos)
		end
	},
	{system_key = "core_update_camera", target_key = "update", target_relation = "After", system = 
		function(ctx)
			local ui_config = ctx.res:get("config", "core_ui_map")
			local last_cam_pos = ctx.camera_pos:copy()
	
			ctx.camera_pos = Math.lerp(
				ctx.camera_pos,
				(ctx.player.entity.pos + 0.5) * ui_config.tile_size - ctx.ui.viewport.bg.size * 0.5 + 0.5,
				0.2
			)
			
			ctx.ui.viewport.bg:move_view(ctx.camera_pos, last_cam_pos)
		end
	},
	{system_key = "core_update_scroll_text", target_key = "update", target_relation = "After", system = 
		function(ctx)
			ctx.ui.text_window:scroll(Mouse.scroll_delta().y * -5)
		end
	},
	{system_key = "core_update_debug_populate_text", target_key = "update", target_relation = "After", system = 
		function(ctx)
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
				ctx.ui.text_window:push(foo .. "?")
			end
		end
	},
}

return hooks