local fmt = string.format

---@class ResourceRegistry
local m_resource_registry = {}
m_resource_registry.__index = m_resource_registry

---@param key string
---@param func fun(ctx: table, value: any): any
---@return ResourceRegistry self
function m_resource_registry:register_importer(key, func)
	self.importers[key] = func
	
	return self
end

---@param ctx table
---@param importer string
---@param kind string
---@param key string
---@param value boolean|number|userdata|table|function|string
---@return ResourceRegistry self
function m_resource_registry:register(ctx, importer, kind, key, value)
	local res = self.importers[importer](ctx, value)
	
	if res == nil then
		printh(fmt("Failed to find resource \"%s\" with \"%s\"", key, tostring(value)))
	end
	
	local kind_array = self.kinds[kind]
	if not kind_array then
		kind_array = {}
		self.kinds[kind] = kind_array
	end
	
	kind_array[key] = res
	
	printh("Registered resource: " .. key)
	
	return self
end

---@param kind_key string
---@param key string
---@return any
function m_resource_registry:get(kind_key, key)
	local kind = self.kinds[kind_key]
	local value = kind and kind[key]
	if not value then
		error(fmt("Failed to fetch resource \"%s\" of kind \"%s\"", tostr(key), tostr(kind_key)))
	end
	return value
end

---@param ctx table
---@return fun(importer: string, kind: string, key: string, value: boolean|number|userdata|table|function|string)
function m_resource_registry:make_registrator(ctx)
	return function(importer, kind, key, resource)
		self:register(ctx, importer, kind, key, resource)
	end
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

return {
	new = new,
}