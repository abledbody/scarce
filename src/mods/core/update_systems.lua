local Mouse = require"core/src/mouse"
local Math = require"core/src/math"
local Player = require"core/src/player"
local Things = require"core/src/things"
local SystemRegistry = require_ext"src/system_registry"
local hook = SystemRegistry.new_hook

---@type Hook[]
local hooks = {
	hook("core_update_mouse", "After", "update",
		function()
			Mouse.frame_start()
		end
	),
	
	hook("core_update_player_inputs", "After", "update", Player.interpret_inputs),
	
	hook("core_update_apply_movement", "After", "update", Things.apply_movement),
	
	hook("core_update_animate_positions", "After", "update", Things.animate_movement),
	
	hook("core_update_tooltip", "After", "update", 
		function(ctx)
			local map_config = ctx.res:get("config", "core_map")
			local mouse_pos = Mouse.position()
			local mouse_map_coords =
				(ctx.ui.viewport:screen_to_viewport(mouse_pos) + ctx.camera_pos - 1) // map_config.tile_size
				
			local entity = ctx.ui.viewport:point_inside(mouse_pos)
				and ctx.entity_map:get(mouse_map_coords) or nil
			
			ctx.ui.tooltip:set_text(entity and entity[1] and entity[1].tooltip)
			ctx.ui.tooltip:set_pos(mouse_pos)
		end
	),
	
	hook("core_update_camera", "After", "update", 
		function(ctx)
			local map_config = ctx.res:get("config", "core_map")
			local last_cam_pos = ctx.camera_pos:copy()
	
			ctx.camera_pos = Math.lerp(
				ctx.camera_pos,
				(ctx.player.grid_pos + 0.5) * map_config.tile_size - ctx.ui.viewport.bg.size * 0.5 + 0.5,
				0.2
			)
			
			ctx.ui.viewport.bg:move_view(ctx.camera_pos, last_cam_pos)
		end
	),
	
	hook("core_update_scroll_text", "After", "update", 
		function(ctx)
			ctx.ui.text_window:scroll(Mouse.scroll_delta().y * -5)
		end
	),
	
	hook("core_update_debug_populate_text", "After", "update", 
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
	),
}

return hooks