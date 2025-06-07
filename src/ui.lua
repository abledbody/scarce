local floor = math.floor
local BORDER_WIDTH = 3

---@param draw_op function
---@param pos userdata
---@param size userdata
---@param cols {ui_border_light: integer, ui_border_mid: integer, ui_border_dark: integer}
local function draw_with_border(draw_op, pos, size, cols)
	local cx, cy = camera(-pos.x, -pos.y)
	rect(-3, -3, size.x + 2, size.y + 2, cols.ui_border_mid)
	rect(-2, -2, size.x + 1, size.y + 1, cols.ui_border_light)
	rect(-1, -1, size.x, size.y, cols.ui_border_dark)
	draw_op()
	camera(cx, cy)
end

---@param str string A single line of text to justify.
---@param spaces integer The number of gaps between words.
---@param width integer The width to justify to.
---@return string str The justified string.
local function justify_margin(str, spaces, width)
	if spaces <= 0 then return str end
	local cx, cy = camera(-1000)
	
	str = str:match("(.-)%s*$")
	
	local w = print(str, 0, 0) or 0
	local err = 0
	-- Error may not be fully accurate. Epsilon prevents off by one.
	local space_width = (width + 0.0001 - w) / spaces
	local line = ""
	for section in str:gmatch("%S+%s*") do
		err += space_width % 1
		local extra_space = floor(space_width) + floor(err)
		line = line .. section
		
		-- Lua is inclusive inclusive. We only want to add an offset if extra_space > 0.
		for i = 0, (extra_space - 1) // 3 do
			---@diagnostic disable-next-line: err-esc
			line = line .. "\-" .. chr(103 + min(extra_space - i * 3, 3))
		end
		
		err %= 1
	end
	
	camera(cx, cy)
	return line
end

return {
	BORDER_WIDTH = BORDER_WIDTH,
	
	draw_with_border = draw_with_border,
	justify_margin = justify_margin,
}