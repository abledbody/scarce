---@param pt userdata
---@param min_in userdata
---@param max_ex userdata
---@return boolean
local function point_aabb(pt, min_in, max_ex)
	return
		pt.x >= min_in.x and pt.x < max_ex.x and
		pt.y >= min_in.y and pt.y < max_ex.y
end

return {
	point_aabb = point_aabb,
}
