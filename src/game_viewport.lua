local m_intersection = require"src/intersection"
local m_colors = require"src/colors"

local BORDER_WIDTH = 3

--- @param self GameViewport
--- @param camera_pos userdata
local function draw(self, camera_pos)
	local cx, cy = camera(-self.pos.x, -self.pos.y)
	rect(0, 0, self.size.x - 1, self.size.y - 1, m_colors.UI_MID)
	rect(1, 1, self.size.x - 2, self.size.y - 2, m_colors.UI_LIGHT)
	rect(2, 2, self.size.x - 3, self.size.y - 3, m_colors.UI_DARK)
	self.bg:draw(self.pos + BORDER_WIDTH, camera_pos)
	camera(cx, cy)
end

local function clip_to_viewport(self, clip_previous)
	return clip(
		self.pos.x + BORDER_WIDTH,
		self.pos.y + BORDER_WIDTH,
		self.bg.size.x,
		self.bg.size.y,
		clip_previous
	)
end

local function screen_to_viewport(self, pt)
	return pt - self.pos - BORDER_WIDTH
end

local function point_inside(self, pos)
	return m_intersection.point_aabb(
		self:screen_to_viewport(pos), vec(0,0), self.bg.size
	)
end

--- @param pos userdata
--- @param bg_viewport BackgroundViewport
--- @return GameViewport
local function new(pos, bg_viewport)
	--- @class GameViewport
	local viewport = {
		pos = pos,
		bg = bg_viewport,
		size = bg_viewport.size + BORDER_WIDTH * 2,
		
		draw = draw,
		clip = clip_to_viewport,
		point_inside = point_inside,
		screen_to_viewport = screen_to_viewport,
	}
	return viewport
end

return {
	new = new,
}