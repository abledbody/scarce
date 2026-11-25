local insert = table.insert
local fmt = string.format

---@param self Entity
local function destroy_entity(self)
	self._parent:destroy(self)
end

---@class Entities
local m_entities = {}
m_entities.__index = m_entities

---@param entity Entity
function m_entities:insert(entity)
	for k in pairs(entity._components) do
		local list = self.component_lookup[k]
		if not list then
			list = {}
			self.component_lookup[k] = list
		end
		
		insert(list, entity)
		entity._indices[k] = #list
	end
end

---@param components table<string, any>
---@return Entity
function m_entities:instantiate(components)
	---@class Entity
	---@field _components table<string, any>
	---@field _indices table<string, integer>
	---@field destroy fun(self: Entity)
	---@field [any] any
	local entity = {
		_components = components,
		_indices = {},
		_parent = self
	}
	
	local m_proxy = {}
	local proxy = setmetatable({}, m_proxy)
	
	-- Redirects to functions, then entity fields, then components.
	m_proxy.__index = function(_, key)
		if key == "destroy" then return destroy_entity end
		
		return entity[key] or entity._components[key]
	end
	-- Blocks overwriting interals. Overwrites existing components. Adds new
	-- components. Removes components set to nil.
	m_proxy.__newindex = function(_, key, value)
		if key == "destroy" or entity[key] then
			error(fmt("Key \"%s\" is reserved as an internal field, and cannot be overwritten", key))
		end
		
		if entity._components[key] then
			if value == nil then
				entity._parent:remove_component(proxy, key)
			else
				entity._components[key] = value
			end
		else
			if value == nil then return end
			entity._parent:add_component(proxy, key, value)
		end
	end
	
	if self.iterating > 0 then
		insert(self.to_instantiate, proxy)
		return proxy
	end
	
	self:insert(proxy)
	
	return proxy
end

---@param entity Entity
function m_entities:destroy(entity)
	if self.iterating > 0 then
		insert(self.to_destroy, entity)
		return
	end
	
	for k, i in pairs(entity._indices) do
		local siblings = self.component_lookup[k]
		
		siblings[i] = siblings[#siblings]
		siblings[i]._indices[k] = i
		siblings[#siblings] = nil
	end
end

---@param entity Entity
---@param key any
---@param value any
function m_entities:add_component(entity, key, value)
	if self.iterating > 0 then
		insert(self.to_add, {entity, key, value})
		return
	end
	
	entity._components[key] = value
	
	local list = self.component_lookup[key]
	if not list then
		list = {}
		self.component_lookup[key] = list
	end
	
	insert(list, entity)
	entity._indices[key] = #list
end

---@param entity Entity
---@param key any
function m_entities:remove_component(entity, key)
	if self.iterating > 0 then
		insert(self.to_remove, {entity, key})
		return
	end
	
	entity._components[key] = nil
	local i = entity._indices[key]
	local siblings = self.component_lookup[key]
	
	siblings[i] = siblings[#siblings]
	siblings[i]._indices[key] = i
	siblings[#siblings] = nil
end

function m_entities:flush_changes()
	if #self.to_remove > 0 then
		for _, args in ipairs(self.to_remove) do
			self:remove_component(unpack(args))
		end
		self.to_remove = {}
	end
	
	if #self.to_add > 0 then
		for _, args in ipairs(self.to_add) do
			self:add_component(unpack(args))
		end
		self.to_add = {}
	end
	
	if #self.to_instantiate > 0 then
		for _, entity in ipairs(self.to_instantiate) do
			self:insert(entity)
		end
		self.to_instantiate = {}
	end
	
	if #self.to_destroy > 0 then
		for _, entity in ipairs(self.to_destroy) do
			self:destroy(entity)
		end
		self.to_destroy = {}
	end
end

---@param ... string
---@return fun():Entity?
function m_entities:query(...)
	local component_keys = {...}
	local component_count = #component_keys
	
	local by_frequency = userdata("i64", 2, component_count)
	for i = 1, component_count do
		local lookup = self.component_lookup[component_keys[i]]
		if not lookup then return function() end end
		by_frequency:set(0, i - 1, #lookup, i)
	end
	by_frequency:sort()
	
	local rarest_list = self.component_lookup[component_keys[by_frequency[1]]]
	
	local entity_i = 1
	
	self.iterating += 1
	return function()
		local entity
		
		while entity_i <= #rarest_list do
			entity = rarest_list[entity_i]
			entity_i += 1
			
			local comps = entity._components
			local valid = true
			for i = 1, component_count - 1 do
				valid = comps[component_keys[by_frequency:get(1, i)]]
				if not valid then break end
			end
			if valid then return entity end
		end
		
		self.iterating -= 1
		if self.iterating == 0 then
			self:flush_changes()
		end
	end
end

---@return Entities
local function new()
	---@class Entities
	---@field component_lookup table<string, Entity[]>
	---@field iterating integer
	---@field to_instantiate Entity[]
	---@field to_destroy Entity[]
	---@field to_add {[0]: Entity, [1]: any, [2]: any}[]
	---@field to_remove {[0]: Entity, [1]: any}[]
	local entities = {
		component_lookup = {},
		
		iterating = 0,
		to_instantiate = {},
		to_destroy = {},
		to_add = {},
		to_remove = {},
	}
	
	return setmetatable(entities, m_entities)
end

return {
	new = new
}