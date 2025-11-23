local fmt = string.format

---@class GraphicsData
local m_graphics_data = {}
m_graphics_data.__index = m_graphics_data

---@class Sprite
---@field bmp userdata
---@field flags integer

---@param sprite Sprite
---@return integer
function m_graphics_data:add_sprite(sprite)
	local i = self.sprite_i
	
	set_spr(i, sprite.bmp)
	assert(sprite.bmp)
	fset(i, sprite.flags)
	
	self.sprite_i += 1
	return i
end

local function new_graphics_data()
	---@class GraphicsData
	local graphics = {
		sprite_i = 0
	}
	
	return setmetatable(graphics, m_graphics_data)
end

return new_graphics_data