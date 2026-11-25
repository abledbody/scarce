---@diagnostic disable: redefined-local

local Mouse = require"core/src/mouse"
local Math = require"core/src/math"
local Player = require"core/src/player"
local Things = require"core/src/things"

---@param hook fun(key: string, target_relation: "Before"|"After", target_key: string, system: fun(ctx: Context))
local function register(hook)
	hook("core_mouse", "After", "root",
		function()
			Mouse.frame_start()
		end
	)
	
	hook("core_player_inputs", "After", "root", Player.interpret_inputs)
	
	hook("core_time_step", "After", "root",
		function(ctx)
			ctx.step_systems:execute(ctx)
		end
	)
	
	hook("core_animate_positions", "After", "root", Things.animate_movement)
	
	hook("core_tooltip", "After", "root", 
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
	)
	
	hook("core_camera", "After", "root", 
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
	)
	
	hook("core_scroll_text", "After", "root", 
		function(ctx)
			ctx.ui.text_window:scroll(Mouse.scroll_delta().y * -5)
		end
	)
	
	hook("core_debug_populate_text", "After", "root", 
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
	)
end

return {
	register = register,
}