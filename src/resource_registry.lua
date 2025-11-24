local insert = table.insert

---@class ResourceRegistry
local m_resource_registry = {}
m_resource_registry.__index = m_resource_registry

---@class ResourceRegistrator
---@field kind string
---@field func fun(ctx: Context, value: any): any


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
	if not kind then
		kind = {}
		self.kinds[resource.kind] = kind
	end
	
	kind[resource.key] = res
	return true
end

---@param kind_key string
---@param key string
---@return any
function m_resource_registry:get(kind_key, key)
	local kind = self.kinds[kind_key]
	return kind and kind[key]
end

---@return ResourceRegistry
local function new()
	---@class ResourceRegistry
	local reg = {
		kinds = {},
		registrators = {},
	}
	
	return setmetatable(reg, m_resource_registry)
end

---@param kind string
---@param key string
---@param value boolean|number|userdata|table|function|string
local function new_resource(kind, key, value)
	---@class Resource
	local resource = {
		kind = kind,
		key = key,
		value = value,
	}
	
	return resource
end

return {
	new = new,
	new_resource = new_resource,
}