local Text = require("core/src/text")

---@class Tooltip
local m_tooltip = {}
m_tooltip.__index = m_tooltip

function m_tooltip:draw()
	if not self.text then return end
	
	local box = self.box
	
	local draw_target = get_draw_target()
	local screen_size = vec(draw_target:width(), draw_target:height())
	local box_size = vec(box:width(), box:height())
	local pos = (self.pos - vec(0, box_size.y)):min(screen_size - box_size):max(0)
	blit(box, nil, nil, nil, pos.x, pos.y)
end

---@param text string?
function m_tooltip:set_text(text)
	if (text == self.text) then return end
	
	self.text = text
	if not text then return end
	
	local lines = self.text:split("\n")
	local block_size, sizes = Text.get_block_size(lines)
	
	local box = userdata("u8", block_size.x+5, block_size.y+5)
	set_draw_target(box)
	
	rect(1, 1, box:width() - 2, box:height() - 2, 7)
	Text.aprint_lines(lines, block_size, sizes, 3, 3, 7, vec(0, 0), "left")
	
	set_draw_target()
	
	self.box = box
end

---@param pos userdata
function m_tooltip:set_pos(pos)
	self.pos = pos
end

---@return Tooltip tooltip
local function new()
	---@class Tooltip
	---@field text string?
	---@field text_size userdata
	---@field pos userdata
	---@field box userdata
	local tooltip = {
		text = "",
		text_size = vec(0, 0),
		pos = vec(0, 0),
	}
	
	return setmetatable(tooltip, m_tooltip)
end

return new