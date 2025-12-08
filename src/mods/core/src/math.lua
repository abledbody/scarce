local Rng = require"core/src/rng"

local i_sqrt2 = 0.5 / 2 ^ (1 / 2)

local function lerp(a, b, t)
	return a + (b - a) * t
end

---@param width integer
---@param height integer
---@param scale number
---@param seed integer?
---@return userdata
local function perlin(width, height, scale, seed)
	seed = seed or 1
	
	math.randomseed(seed)
	local seed_b = math.random(-2^53, 2^53)
	
	local vectors_size = vec(-((width + 1) // -scale), -((height + 1) // -scale))
	
	-- Note that vectors are not evenly distributed on the unit circle.
	-- Whatever.
	local vectors_x = Rng.random_vec(vectors_size.x, vectors_size.y, seed) * 2 - 1
	local vectors_y = Rng.random_vec(vectors_size.x, vectors_size.y, seed_b) * 2 - 1
	local vector_magnitudes = (vectors_x * vectors_x + vectors_y * vectors_y) ^ 0.5
	vectors_x:div(vector_magnitudes, true)
	vectors_y:div(vector_magnitudes, true)
	
	local pos_x = userdata("f64", width, height)
		:copy(1, true, 0, 1, 1, 0, 1, width - 1)
	pos_x:add(pos_x, true, 1, 2, 1, 1, 1, width - 2)
		:copy(pos_x, true, 0, width, width, width, width, height - 1)
	
	local pos_y = userdata("f64", height, width)
		:copy(1, true, 0, 1, 1, 0, 1, height - 1)
	pos_y:add(pos_y, true, 1, 2, 1, 1, 1, height - 2)
		:copy(pos_y, true, 0, height, height, height, height, width - 1)
	pos_y:transpose(true)
	
	local parent_vec_x = pos_x:div(scale)
	local parent_vec_y = pos_y:div(scale)
	
	local parent_i_nw = parent_vec_x:convert("i32") + parent_vec_y:convert("i32") * vectors_size.x
	local parent_i_ne = parent_i_nw + 1
	local parent_i_sw = parent_i_nw + vectors_size.x
	local parent_i_se = parent_i_ne + vectors_size.x
	
	local nw_x = vectors_x:take(parent_i_nw)
	local ne_x = vectors_x:take(parent_i_ne)
	local sw_x = vectors_x:take(parent_i_sw)
	local se_x = vectors_x:take(parent_i_se)
	local nw_y = vectors_y:take(parent_i_nw)
	local ne_y = vectors_y:take(parent_i_ne)
	local sw_y = vectors_y:take(parent_i_sw)
	local se_y = vectors_y:take(parent_i_se)
	
	local frac_x = parent_vec_x:mod(1)
	local frac_y = parent_vec_y:mod(1)
	
	local dot_nw = nw_x * frac_x       + nw_y * frac_y
	local dot_ne = ne_x * (frac_x - 1) + ne_y * frac_y
	local dot_sw = sw_x * frac_x       + sw_y * (frac_y - 1)
	local dot_se = se_x * (frac_x - 1) + se_y * (frac_y - 1)
	
	local tx = 6 * frac_x ^ 5 - 15 * frac_x ^ 4 + 10 * frac_x ^ 3
	local ty = 6 * frac_y ^ 5 - 15 * frac_y ^ 4 + 10 * frac_y ^ 3
	
	local lerped_n = (dot_ne - dot_nw) * tx + dot_nw
	local lerped_s = (dot_se - dot_sw) * tx + dot_sw
	local lerped = (lerped_s - lerped_n) * ty + lerped_n
	return lerped * 0.35355339059 + 0.5 -- Normalize from +-sqrt(2) to [0,1]
end

return {
	lerp = lerp,
	perlin = perlin,
}