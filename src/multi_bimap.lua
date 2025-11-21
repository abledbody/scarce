---@class MultiBimap<K, V>
---@field key2set table<`K`, table<`V`, true>>
---@field value2key table<`V`, `K`>
local m_multi_bimap = {}
m_multi_bimap.__index = m_multi_bimap

---@generic K, V
---@param key `K`
---@param value `V`
---@return boolean
function m_multi_bimap:insert(key, value)
	if self.value2key[value] then return false end
	
	local set = self.key2set[key]
	if not set then
		set = {}
		self.key2set[key] = set
	end
	set[value] = true
	
	self.value2key[value] = key
	return true
end

---@generic K, V
---@param self MultiBimap<`K`, `V`>
---@param value V
---@return boolean
function m_multi_bimap:remove(value)
	local key = self.value2key[value]
	if not key then return false end
	
	self.value2key[value] = nil
	self.key2set[key][value] = nil
	if not next(self.key2set[key]) then
		self.key2set[key] = nil
	end
	
	return true
end

---@generic K, V
---@return MultiBimap<K, V>
local function new()
	local multi_bimap = {
		key2set = {},
		value2key = {},
	}
	return setmetatable(multi_bimap, m_multi_bimap)
end

return new