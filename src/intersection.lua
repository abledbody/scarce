---@param pt userdata
---@param min_in userdata
---@param max_in userdata
---@return boolean
local function point_aabb(pt, min_in, max_in)
	return
		pt.x >= min_in.x and pt.x < max_in.x and
		pt.y >= min_in.y and pt.y < max_in.y
end

return {
	point_aabb = point_aabb,
}
