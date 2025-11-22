include"src/require.lua"

-------------------------------------Dependencies--------------------------------------

local new_system_registry = require"src/system_registry"
local new_resource_registry = require"src/resource_registry"
local load_mods = require"src/load_mods"
local fmt = string.format
local insert = table.insert

---------------------------------------Constants---------------------------------------



--------------------------------------Game State---------------------------------------

local ctx --- @type Context

---@param mods Mod[]
---@return Context
local function new_context(mods)
	local system_reg = new_system_registry()
	local res = new_resource_registry()
	
	for _, mod in ipairs(mods) do
		if mod.system_hooks then
			for _, hook in ipairs(mod.system_hooks) do
				system_reg:register(hook)
			end
		end
		if mod.res_registrators then
			for _, registrator in ipairs(mod.res_registrators) do
				res:define(registrator)
			end
		end
	end
	
	local loops, orphans, duplicates, hook_errors = system_reg:build_order()
	-- While there's no way to manage this in game, let's just print and stop.
	local errored = false
	
	if next(loops) then
		for _, loop in ipairs(loops) do
			local keys = {}
			for _, hook in ipairs(loop) do
				insert(keys, hook.system_key)
			end
			insert(keys, loop[1].system_key)
			print(fmt("Orphan system tree: %s", table.concat(keys, " -> ")))
		end
		errored = true
	end
	
	if #orphans > 0 then
		for _, orphan in ipairs(orphans) do
			print(fmt("Orphan system tree: %s", table.concat(orphan.keys, ", ")))
		end
		errored = true
	end
	
	if #duplicates > 0 then
		for _, v in hook_errors do
			print(fmt("Duplicate key: %s", v))
		end
		errored = true
	end
	
	if hook_errors then
		for _, v in hook_errors do
			print(v)
		end
		errored = true
	end
	
	if errored then stop() end
	
	--- @class Context
	local ctx = {
		system_reg = system_reg,
		res = res,
	}
	
	for _, mod in ipairs(mods) do
		if mod.resources then
			for _, resource in ipairs(mod.resources) do
				res:register(ctx, resource)
			end
		end
	end
	
	return ctx
end

----------------------------------Picotron Callbacks-----------------------------------

function _init()
	local mods = load_mods()
	
	ctx = new_context(mods)
	
	for _, system in ipairs(ctx.system_reg.init_systems) do
		system(ctx)
	end
end

function _update()
	for _, system in ipairs(ctx.system_reg.update_systems) do
		system(ctx)
	end
end

function _draw()
	for _, system in ipairs(ctx.system_reg.draw_systems) do
		system(ctx)
	end
end

include"src/error_explorer.lua"