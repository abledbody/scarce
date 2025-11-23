local insert = table.insert

---@class ResourceRegistry
local m_resource_registry = {}
m_resource_registry.__index = m_resource_registry

---@class ResourceRegistrator
---@field kind string
---@field func fun(ctx: Context, value: any): any

---@class Resource
---@field kind string
---@field key string
---@field value boolean|number|userdata|table|function|string

---@param registrator ResourceRegistrator
function m_resource_registry:define(registrator)
	self.registrators[registrator.kind] = registrator.func
end

---@param ctx Context
---@param resource Resource
function m_resource_registry:register(ctx, resource)
	local res = self.registrators[resource.kind](ctx, resource.value)
	if res == nil then return false end
	
	local kind = self.kinds[resource.kind]
	if not kind then kind = {} self.kinds[resource.kind] = kind end
	insert(kind, res)

	self.resources[resource.key] = res
	return true
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
		kinds = {},
		registrators = {},
	}
	
	return setmetatable(reg, m_resource_registry)
end