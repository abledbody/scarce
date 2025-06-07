local m_intersection = require"src/intersection"
local m_colors = require"src/colors"
local m_ui = require"src/ui"

--- @param self GameViewport
--- @param camera_pos userdata
local function draw(self, camera_pos)
	m_ui.draw_with_border(
		function() self.bg:draw(self.pos, camera_pos) end,
		self.pos, self.size, m_colors
	)
end

local function clip_to_viewport(self, clip_previous)
	return clip(
		self.pos.x,
		self.pos.y,
		self.bg.size.x,
		self.bg.size.y,
		clip_previous
	)
end

local function screen_to_viewport(self, pt)
	return pt - self.pos
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
		size = bg_viewport.size,
		
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