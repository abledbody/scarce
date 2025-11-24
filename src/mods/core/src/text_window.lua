local UI = require"core/src/ui"
local insert, remove = table.insert, table.remove
local ceil, floor, max, min = math.ceil, math.floor, math.max, math.min


---@class TextWindow
local m_text_window = {}
m_text_window.__index = m_text_window

---@param res ResourceRegistry
function m_text_window:draw(res)
	local colors = res:get"core_colors_ui"
	UI.draw_with_border(
		function()
			if self.buffer_dirty then
				self:redraw_buffer(colors)
				self.buffer_dirty = false
			end
			blit(self.buffer, nil, nil, nil, self.pos.x, self.pos.y)
			if self.line_i != #self.lines then
				local sprite = get_spr(res:get"core_sprite_ui_text_detached")
				spr(
					sprite,
					self.size.x - sprite:width() - 1,
					self.size.y - sprite:height() - 1
				)
			end
		end,
		self.pos, self.size, colors
	)
end

---@param msg string
function m_text_window:add_msg_wrapped(msg)
	local cx, cy = camera(-1000)
	
	insert(self.lines, "") -- Add a new line to separate messages.
	
	local line = msg:match("^%s*")
	local x = print(line, 0, 0) or 0
	for word, whitespace in msg:gmatch("(%S+)(%s*)") do
		-- If a word goes over the edge of the window, put it on the next line.
		local w = print(word, 0, 0) or 0
		if x + w >= self.size.x - 1 then
			-- In this case, we definitely have a space before this we don't want to count.
			insert(self.lines, line)
			line, x = word, w
		else
			x += w
			line = line .. word
		end
		
		-- If a space goes over the edge of the window, just start a new line.
		w = print(whitespace, 0, 0) or 0
		if x + w >= self.size.x - 1 then
			insert(self.lines, line)
			line, x = "", 0
		else
			x += w
			line = line .. whitespace
		end
	end
	
	if line ~= "" then
		insert(self.lines, line)
	end
	
	camera(cx, cy)
	
	local removed = max(0, #self.lines - self.max_history)
	for _ = 1, #self.lines - self.max_history do
		remove(self.lines, 1)
	end
	return removed
end

function m_text_window:redraw_buffer(colors)
	local cx, cy = camera()
	set_draw_target(self.buffer)
	
	cls(colors.ui_background)
	local max_lines = ceil(self.size.y / self.line_height)
	local line_count = min(#self.lines, max_lines)
	for i = 1, line_count do
		local line = self.lines[self.line_i - i + 1]
		local y = self.size.y - i * self.line_height
		---@diagnostic disable-next-line: err-esc
		print("\^o0ff" .. line, 1, y, 7)
	end
	
	set_draw_target()
	camera(cx, cy)
end

---@param msg string
function m_text_window:push(msg)
	local following = self.line_i == #self.lines
	local removed = self:add_msg_wrapped(msg)
	if following then
		self:set_line(#self.lines)
	else
		self:scroll(-removed)
	end
end

---@param line_i integer
function m_text_window:set_line(line_i)
	local max_lines = floor(self.size.y / self.line_height)
	self.line_i = min(max(line_i, 1 + max_lines), #self.lines)
	self.buffer_dirty = true
end

---@param dline integer
function m_text_window:scroll(dline)
	if dline == 0 then return end
	self:set_line(self.line_i + dline)
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
		buffer_dirty = true,
	}
	
	return setmetatable(text_window, m_text_window)
end

return new