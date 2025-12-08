local max_f64_int = 2^53

local condensers = {
	f64 = function(ud)
		return ud:shr(10, true):convert("f64"):div(max_f64_int, true)
	end,
	i64 = function(ud) return ud end,
	i32 = function(ud) return ud:convert("i32") end,
	i16 = function(ud) return ud:convert("i16") end,
	u8 = function(ud) return ud:convert("u8") end,
}

---@param width integer
---@param height integer?
---@param seed integer?
---@param ud_type "f64"|"i64"|"i32"|"i16"|"u8"?
---@return userdata
local function random_vec(width, height, seed, ud_type)
	height = height or 1
	seed = seed or 1
	ud_type = ud_type or "f64"
	
	local size = width * height
	
	local values = userdata("i64", width, height)
		:copy(1, true, 0, 1, 1, 0, 1, size)
	values:add(values, true, 0, 1, 1, 1, 1, size)
		:mul(0x9e3779b97f4a7c15, true)
		:bxor(values >> 32, true)
		:add(seed, true)
		:mul(0x9e3779b97f4a7c15, true)
		:bxor(values >> 32, true)
	
	return condensers[ud_type](values)
end

return {
	random_vec = random_vec,
}