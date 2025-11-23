local Intersection = require"core/src/intersection"
local UI = require"core/src/ui"

---@class GameViewport
local m_game_viewport = {}
m_game_viewport.__index = m_game_viewport

---@param camera_pos userdata
function m_game_viewport:draw(camera_pos, colors)
	UI.draw_with_border(
		function() self.bg:draw(self.pos, camera_pos) end,
		self.pos, self.size, colors
	)
end

---@param clip_previous boolean?
---@return integer x
---@return integer y
---@return integer w
---@return integer h
function m_game_viewport:clip(clip_previous)
	return clip(
		self.pos.x,
		self.pos.y,
		self.bg.size.x,
		self.bg.size.y,
		clip_previous
	)
end

---@param pt userdata
---@return userdata
function m_game_viewport:screen_to_viewport(pt)
	return pt - self.pos
end

---@param pos userdata
---@return boolean
function m_game_viewport:point_inside(pos)
	return Intersection.point_aabb(
		self:screen_to_viewport(pos), vec(0,0), self.bg.size
	)
end

---@param pos userdata
---@param bg_viewport BackgroundViewport
---@return GameViewport
local function new(pos, bg_viewport)
	--- @class GameViewport
	local viewport = {
		pos = pos,
		bg = bg_viewport,
		size = bg_viewport.size,
	}
	
	return setmetatable(viewport, m_game_viewport)
end

return new