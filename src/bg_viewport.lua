local abs,max = math.abs,math.max

--- Draws the map to the screen.
--- @param self BackgroundViewport The viewport to draw.
--- @param position userdata The position of the viewport on the screen.
--- @param cam_pos userdata The camera position.
local function draw(self, position, cam_pos)
	-- The first time we draw, there will be nothing in the buffer.
	if not self.surface then
		self.surface = userdata("u8", self.size.x, self.size.y)
		set_draw_target(self.surface)
		camera(cam_pos.x, cam_pos.y)
		
		self.draw_op()
		
		camera()
		set_draw_target()
	end
	
	blit(self.surface, nil, nil, nil, position.x, position.y)
end

--- Moves the viewport based on the change in camera position.
--- @param self BackgroundViewport The viewport to move.
--- @param cam_pos userdata The current camera position.
--- @param prev_cam_pos userdata The previous camera position.
local function move_view(self, cam_pos, prev_cam_pos)
	if not self.surface then return end
	
	-- Round the camera positions to avoid floating point issues.
	cam_pos = cam_pos // 1
	prev_cam_pos = prev_cam_pos // 1
	
	local dx, dy = cam_pos.x - prev_cam_pos.x, cam_pos.y - prev_cam_pos.y
	
	if dx == 0 and dy == 0 then return end
	
	local abs_dx, abs_dy = abs(dx), abs(dy)
	local w,h = self.surface:attribs()
	
	blit(
		self.surface, self.surface,
		max(0, dx), max(0, dy),
		max(0, -dx), max(0, -dy),
		w - abs_dx, h - abs_dy
	)
	
	set_draw_target(self.surface)
	
	-- Pillarbox redraw.
	local rx, ry, rw, rh = dx > 0 and w - dx or 0, 0, abs_dx, h
	clip(rx, ry, rw, rh)
	poke(0x5509, 0xff)
	rectfill(rx, ry, rx + rw - 1, ry + rh - 1, 0)
	poke(0x5509, 0x3f)
	camera(cam_pos.x, cam_pos.y)
	self.draw_op()
	camera()
	
	-- Letterbox redraw.
	rx, ry, rw, rh = dx < 0 and -dx or 0, dy > 0 and h - dy or 0, w - abs_dx, abs_dy
	clip(rx, ry, rw, rh)
	poke(0x5509, 0xff)
	rectfill(rx, ry, rx + rw - 1, ry + rh - 1, 0)
	poke(0x5509, 0x3f)
	camera(cam_pos.x, cam_pos.y)
	self.draw_op()
	camera()
	clip()
	
	set_draw_target()
end

--- Creates a new MapViewport.
--- @param size userdata The size of the viewport.
--- @param draw_op function The function to draw the map.
--- @return BackgroundViewport viewport A new MapViewport instance.
local function new(size, draw_op)
	--- @class BackgroundViewport A viewport for displaying and efficiently redrawing a map.
	--- @field draw_op function The function to draw the map.
	--- @field surface userdata? The draw target for the viewport. When nil, the next call to draw will create it.
	local viewport = {
		size = size,
		draw_op = draw_op,
		
		draw = draw,
		move_view = move_view,
	}

	return viewport
end

return {
	new = new
}