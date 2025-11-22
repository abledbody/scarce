---@class ResourceRegistry
local m_resource_registry = {}
m_resource_registry.__index = m_resource_registry

---@class ResourceRegistrator
---@field kind string
---@field func fun(ctx: Context, value: any)

---@class Resource
---@field kind string
---@field key string
---@field value any

---@param registrator ResourceRegistrator
function m_resource_registry:define(registrator)
	self.registrators[registrator.kind] = registrator.func
end

---@param resource Resource
function m_resource_registry:register(ctx, resource)
	self.resources[resource.key] = self.registrators[resource.kind](ctx, resource.value)
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