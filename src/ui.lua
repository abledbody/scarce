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

return {
	BORDER_WIDTH = BORDER_WIDTH,
	
	draw_with_border = draw_with_border,
}