local fmt = string.format
local insert = table.insert

local new_index_map = require"src/index_map"
local default_ctor = require"src/utils".default_ctor
local new_multi_bimap = require"src/multi_bimap"

---@class Hook
---@field target_relation "Before"|"After"
---@field target_key string
---@field system_key string
---@field system fun(ctx: GameState)

---@class Registry
---@field system_hooks Hook[]
---@field init_systems fun(ctx: GameState)[]
---@field update_systems fun(ctx: GameState)[]
local m_registry = {}
m_registry.__index = m_registry

---@param hook Hook
function m_registry:register(hook)
	insert(self.system_hooks, hook)
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

function m_registry:build_order()
	-- self.system_hooks defines a directed peseudoforest.
	-- We need to:
	-- 1. Find each component
	--	A component is defined by either a root or a cycle.
	--	You can identify either by following targets until the target is either
	-- 	a node you've already visited, or nil.
	-- 2. Identify components by whether they are trees or loops
	-- 3. Identify the exact set of nodes that loop for components which do so
	-- 4. Produce an ordered list for each tree that:
	-- - Is ordered depth-first (children appear before siblings)
	-- - Is ordered relative to its parent depending on whether the node specifies "Before" or "After"
	-- - Breaks ties by maintaining the order of the original list

	local key2hook = {} ---@type table<string, Hook>
	local key2children_keys = {} ---@type table<string, IndexMap<string>>
	local duplicates = {}
	for _, hook in ipairs(self.system_hooks) do
		local system_key, target_key = hook.system_key, hook.target_key
		if key2hook[system_key] then insert(duplicates, system_key) goto continue end
		key2hook[system_key] = hook
		if target_key then
			default_ctor(key2children_keys, target_key, new_index_map)
				:insert(system_key)
		end
		::continue::
	end
	
	local components, roots, loops = identify_components(key2hook)
	
	-- Breadth-first index_map population of system order to be saved into
	-- self.init_systems and self.update_systems
	-- All roots which don't match get shoved into orphans.
	
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
		for i = 1, #before_child_hooks do
			tree:insert(before_child_hooks[i].system_key, parent_index + i - 1)
		end
		
		for i = #after_child_hooks, 1, -1 do
			tree:insert(after_child_hooks[i].system_key, parent_index + 1)
		end
		
		for _, k in ipairs(children.keys) do
			visit(tree, k)
		end
	end
	
	local orphans = {}
	local init_systems, update_systems
	
	for comp_id in pairs(components.key2set) do
		if loops[comp_id] then goto continue end
		
		local root_key = roots[comp_id]
		local tree = new_index_map({root_key})
		visit(tree, root_key)
		
		if root_key == "init" then
			init_systems = tree
		elseif root_key == "update" then
			update_systems = tree
		else
			insert(orphans, tree)
		end
		
		::continue::
	end
	
	-- Use the index maps to get the system functions out of the hooks in order.
	self.init_systems = {}
	if init_systems then
		for _, k in ipairs(init_systems.keys) do
			if k != "init" then
				insert(self.init_systems, key2hook[k].system)
			end
		end
	end
	
	self.update_systems = {}
	if update_systems then
		for _, k in ipairs(update_systems.keys) do
			if k != "update" then
				insert(self.update_systems, key2hook[k].system)
			end
		end
	end
	
	-- Organize the loops neatly into a dense array.
	local loops_packed = {}
	for k, v in pairs(loops) do
		insert(loops_packed, v)
	end
	
	return loops_packed, orphans, duplicates
end

local function new()
	return setmetatable({
		system_hooks = {},
	}, m_registry)
end

return {
	new = new,
}