---@class ResourceRegistry
local m_resource_registry = {}
m_resource_registry.__index = m_resource_registry

---@class Resource
---@field kind string
---@field key string
---@field value any

---@param resource_type string
---@param registrator fun(value: any)
function m_resource_registry:define(resource_type, registrator)
	self.registrators[resource_type] = registrator
end

---@param resource Resource
function m_resource_registry:register(resource)
	self.resources[resource.key] = self.registrators[resource.kind](resource.value)
end

---@param key string
---@return any
function m_resource_registry:get(key)
	return self.resources[key]
end

---@return ResourceRegistry
return function()
	---@class ResourceRegistry
	local reg = {
		resources = {},
		registrators = {},
	}
	
	return setmetatable(reg, m_resource_registry)
end