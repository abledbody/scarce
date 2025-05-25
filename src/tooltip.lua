local m_text = require("src/text")

--- @param self Tooltip
local function draw(self)
	local draw_target = get_draw_target()
	local screen_size = vec(draw_target:width(), draw_target:height())
	local box_size = vec(self.box:width(), self.box:height())
	local pos = (self.pos - vec(0, box_size.y)):min(screen_size - box_size):max(0)
	blit(self.box, nil, nil, nil, pos.x, pos.y)
end

--- @param self Tooltip
--- @param text string
local function set_text(self, text)
	self.text = text
	
	local lines = self.text:split("\n")
	local block_size, sizes = m_text.get_block_size(lines)
	
	local box = userdata("u8", block_size.x+5, block_size.y+5)
	set_draw_target(box)
	
	rect(1, 1, box:width() - 2, box:height() - 2, 7)
	m_text.aprint_lines(lines, block_size, sizes, 3, 3, 7, vec(0, 0), "left")
	
	set_draw_target()
	
	self.box = box
end

--- @param self Tooltip
--- @param pos userdata
local function set_pos(self, pos)
	self.pos = pos
end

--- @return Tooltip tooltip
local function new()
	---@class Tooltip
	---@field text string
	---@field text_size userdata
	---@field pos userdata
	---@field box userdata?
	local tooltip = {
		text = "",
		text_size = vec(0, 0),
		pos = vec(0, 0),
		box = nil,
		
		set_text = set_text,
		set_pos = set_pos,
		draw = draw,
	}
	
	return tooltip
end

return {
	new = new,
}
