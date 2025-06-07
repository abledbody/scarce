local insert, remove = table.insert, table.remove
local ceil, floor, max, min = math.ceil, math.floor, math.max, math.min

local m_colors = require"src/colors"
local m_ui = require"src/ui"

local function draw(self)
	m_ui.draw_with_border(
		function()
			blit(self.buffer, nil, nil, nil, self.pos.x, self.pos.y)
			if self.line_i != #self.lines then
				local sprite = get_spr(128)
				spr(sprite, self.size.x - sprite:width(), self.size.y - sprite:height())
			end
		end,
		self.pos, self.size, m_colors
	)
end

local function add_msg_wrapped(self, msg)
	local cx, cy = camera(-1000)
	
	insert(self.lines, "") -- Add a new line to separate messages.
	
	local line = ""
	local x = 0
	for word, whitespace in msg:gmatch("(%S+)(%s*)") do
		-- If a word goes over the edge of the window, put it on the next line.
		local w = print(word, 0, 0) or 0
		if x + w >= self.size.x then
			insert(self.lines, line)
			x = w
			line = word
		else
			x += w
			line = line .. word
		end
		
		-- If a space goes over the edge of the window, just start a new line.
		w = print(whitespace, 0, 0) or 0
		if x + w >= self.size.x then
			insert(self.lines, line)
			x = 0
			line = ""
		else
			x += w
			line = line .. whitespace
		end
	end
	
	if line ~= "" then
		insert(self.lines, line)
	end
	
	camera(cx, cy)
	
	local removed = 0
	for _ = 1, #self.lines - self.max_history do
		remove(self.lines, 1)
		removed += 1
	end
	return removed
end

---@param self TextWindow
local function redraw_buffer(self)
	set_draw_target(self.buffer)
	cls(m_colors.ui_background)
	local max_lines = ceil(self.size.y / self.line_height)
	local line_count = min(#self.lines, max_lines)
	for i = 1, line_count do
		local line = self.lines[self.line_i - i + 1]
		local y = self.size.y - i * self.line_height
		print(line, 0, y, 7)
	end
	set_draw_target()
end

---@param self TextWindow
---@param msg string
local function push(self, msg)
	local last_line_count = #self.lines
	local removed = self:add_msg_wrapped(msg)
	-- If we're at the bottom of the history, scroll with the new message.
	if self.line_i == last_line_count then
		self.line_i = #self.lines
	else
		self:scroll(-removed)
	end
	
	self:redraw_buffer()
end

---@param self TextWindow
---@param dline integer
local function scroll(self, dline)
	if dline == 0 then return end
	local max_lines = floor(self.size.y / self.line_height)
	self.line_i = min(max(self.line_i + dline, 1 + max_lines), #self.lines)
	self:redraw_buffer()
end

local function new(pos, size, line_height, max_history)
	---@class TextWindow
	local text_window = {
		pos = pos,
		size = size,
		line_height = line_height or 11,
		lines = {},
		line_i = 0,
		max_history = max_history or 1000,
		buffer = userdata("u8", size.x, size.y),
		
		draw = draw,
		redraw_buffer = redraw_buffer,
		add_msg_wrapped = add_msg_wrapped,
		push = push,
		scroll = scroll,
	}
	
	return text_window
end

return {
	new = new,
}