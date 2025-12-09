local fmt = string.format

---@class ResourceRegistry
local m_resource_registry = {}
m_resource_registry.__index = m_resource_registry

---@class Importer
---@field key string
---@field func fun(ctx: Context, value: any): any


---@param importer Importer
function m_resource_registry:register_importer(importer)
	self.importers[importer.key] = importer.func
end

---@param ctx Context
---@param resource Resource
function m_resource_registry:register(ctx, resource)
	local res = self.importers[resource.importer](ctx, resource.value)
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
	local value = kind and kind[key]
	if not value then
		error(fmt("Failed to fetch resource \"%s\" of kind \"%s\"", key, kind_key))
	end
	return value
end

---@return ResourceRegistry
local function new()
	---@class ResourceRegistry
	local reg = {
		importers = {},
		kinds = {},
	}
	
	return setmetatable(reg, m_resource_registry)
end

---@param importer string
---@param kind string
---@param key string
---@param value boolean|number|userdata|table|function|string
local function new_resource(importer, kind, key, value)
	---@class Resource
	local resource = {
		importer = importer,
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