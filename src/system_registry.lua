local fmt = string.format
local insert = table.insert
local remove = table.remove

local new_index_map = require"src/index_map"
local default_ctor = require"src/utils".default_ctor
local new_multi_bimap = require"src/multi_bimap"

---@class Hook
---@field system_key string
---@field target_key string
---@field target_relation "Before"|"After"
---@field system fun(ctx: table)

---@class SystemRegistry
local m_system_registry = {}
m_system_registry.__index = m_system_registry

---@param key string
---@param target_relation "Before"|"After"
---@param target_key string
---@param system fun(ctx: table)
---@return SystemRegistry self
function m_system_registry:register(key, target_relation, target_key, system)
	local system_key_type = type(key)
	local target_key_type = type(target_key)
	local system_type = type(system)
	local relation_type = type(target_relation)
	local wrong_system_key_type = system_key_type != "string"
	local wrong_target_key_type = target_key_type != "string"
	local wrong_system_type = system_type != "function"
	local wrong_relation_type = relation_type != "string"
	local wrong_relation_value =
		target_relation != "Before"
		and target_relation != "After"
	
	local err
	if wrong_system_key_type then
		err = fmt("Invalid system key type %s. Must be a string.", system_key_type)
	end
	if wrong_target_key_type then
		err = (err and err .. "\n" or "") .. fmt("Invalid target key type %s. Must be a string.", target_key_type)
	end
	if wrong_system_type then
		err = (err and err .. "\n" or "") .. fmt("Invalid system type %s. Must be a function which takes a context parameter.", system_type)
	end
	if wrong_relation_type then
		err = (err and err .. "\n" or "") .. fmt("Invalid system relation type %s. Must be \"After\" or \"Before\".", relation_type)
	end
	if wrong_relation_value then
		err = (err and err .. "\n" or "") .. fmt("Invalid system relation %s. Must be \"After\" or \"Before\".", target_relation)
	end
	
	assert(not err, err)
	
	insert(self.system_hooks, {
		system_key = key,
		target_key = target_key,
		target_relation = target_relation,
		system = system
	})
	
	self.needs_rebuilt = true
	
	return self
end

---@param key2hook table<string, Hook>
---@return MultiBimap<integer, string>
---@return table<integer, string>
---@return table<integer, Hook[]>
local function identify_components(key2hook)
	local components = new_multi_bimap()
	local visited = {}
	local loops = {}
	local roots = {}
	local component_count = 0
	
	local function visit(k, chain)
		-- Existing component
		local existing_key = components.value2key[k]
		if existing_key then return "merge", existing_key end
		-- Loop
		if visited[k] then return "loop", key2hook[k] end
		
		insert(chain, k)
		visited[k] = true
		
		-- Root through non-hook
		if not key2hook[k] then return "root", k end
		
		local target_key = key2hook[k].target_key
		
		-- Root through orphanage
		if not target_key then return "root", k end
		
		return visit(key2hook[k].target_key, chain)
	end
	
	for k in pairs(key2hook) do
		if components.value2key[k] then goto continue end
		
		local chain = {}
		local result, data = visit(k, chain)
		
		local comp_id
		if result == "merge" then
			comp_id = data
		else
			component_count += 1
			
			if result == "loop" then
				loops[component_count] = {}
				
				local hook = data
				repeat
					insert(loops[component_count], hook)
					hook = key2hook[hook.target_key]
				until hook == data
			elseif result == "root" then
				roots[component_count] = data
			end
			
			comp_id = component_count
		end
		
		for _, tally_k in ipairs(chain) do
			components:insert(comp_id, tally_k)
		end
		
		visited = {}
		
		::continue::
	end
	
	return components, roots, loops
end

---@return table<integer, Hook[]>
---@return table<string, true>[]
function m_system_registry:build_order()
	-- self.system_hooks defines a directed peseudoforest.
	-- We need to:
	-- 1. Override earlier nodes of the same key with the definitions of later nodes.
	-- 2. Find each component
	--	A component is defined by either a root or a cycle.
	--	You can identify either by following targets until the target is either
	-- 	a node you've already visited, or nil.
	-- 3. Identify components by whether they are trees or loops
	-- 4. Identify the exact set of nodes that loop for components which do so
	-- 5. Produce an ordered list for each tree that:
	-- - Is ordered depth-first (children appear before siblings)
	-- - Is ordered relative to its parent depending on whether the node specifies "Before" or "After"
	-- - Breaks ties by maintaining the order of the original list

	local key2hook = {} ---@type table<string, Hook>
	local key2children_keys = {} ---@type table<string, IndexMap<string>>
	for _, hook in ipairs(self.system_hooks) do
		local system_key, target_key = hook.system_key, hook.target_key

		local override = key2hook[system_key]
		if override then
			key2children_keys[override.target_key]:remove(system_key)
			if #key2children_keys[override.target_key].keys == 0 then
				key2children_keys[override.target_key] = nil
			end
		end
		
		key2hook[system_key] = hook
		if target_key then
			default_ctor(key2children_keys, target_key, new_index_map)
				:insert(system_key)
		end
	end
	
	local components, roots, loops = identify_components(key2hook)

	local orphans = {}
	
	-- index_map population of system order.
	-- All roots which aren't the canonical root get shoved into orphans.

	for comp_id, tree in ipairs(components.key2set) do
		if roots[comp_id] != "root" then insert(orphans, tree) end
	end
	
	local function visit(tree, system_key)
		local children = key2children_keys[system_key]
		if not children then return end
		
		local before_child_hooks = {}
		local after_child_hooks = {}
		for _, k in ipairs(children.keys) do
			local hook = key2hook[k]
			if hook.target_relation == "Before" then
				insert(before_child_hooks, hook)
			elseif hook.target_relation == "After" then
				insert(after_child_hooks, hook)
			end
		end
		
		local parent_index = tree.indices[system_key]
		-- After nodes must come first, because they will not change the parent_index.
		for i = #after_child_hooks, 1, -1 do
			tree:insert(after_child_hooks[i].system_key, parent_index + 1)
		end
		
		for i = 1, #before_child_hooks do
			tree:insert(before_child_hooks[i].system_key, parent_index + i - 1)
		end
		
		for _, k in ipairs(children.keys) do
			visit(tree, k)
		end
	end

	-- Use the index maps to get the system functions out of the hooks in order.
	
	local tree = new_index_map({"root"})
	visit(tree, "root")
	
	self.systems = {}
	for _, k in ipairs(tree.keys) do
		if k != "root" then
			insert(self.systems, key2hook[k].system)
		end
	end
	
	-- Organize the loops neatly into a dense array.
	local loops_packed = {}
	for _, v in pairs(loops) do
		insert(loops_packed, v)
	end
	
	return loops, orphans
end

---@param ctx table
---@return table<integer, Hook[]>?
---@return table<string, true>[]?
function m_system_registry:execute(ctx)
	local loops, orphans
	if self.needs_rebuilt then
		loops, orphans = self:build_order()
	end
	
	for _, f in pairs(self.systems) do
		f(ctx)
	end
	
	return loops, orphans
end

function m_system_registry:make_registrator()
	return function(key, target_relation, target_key, system)
		self:register(key, target_relation, target_key, system)
	end
end

---@return SystemRegistry
local function new()
	---@class SystemRegistry
	local registry = {
		system_hooks = {},
		systems = {},
		needs_rebuilt = false
	}
	return setmetatable(registry, m_system_registry)
end

return {
	new = new,
}