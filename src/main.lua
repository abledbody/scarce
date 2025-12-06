include"src/require.lua"

-------------------------------------Dependencies--------------------------------------

local SystemRegistry = require"src/system_registry"
local ResourceRegistry = require"src/resource_registry"
local load_mods = require"src/load_mods"
local fmt = string.format
local insert = table.insert

----------------------------------------Globals----------------------------------------

WORKP = pwd()
---@diagnostic disable-next-line: lowercase-global
function require_ext(path)
	local current_wd = pwd()
	cd(WORKP)
	local out = require(path)
	cd(current_wd)
	return out
end

--------------------------------------Game State---------------------------------------

---@param mods Mod[]
---@return Context
local function new_context(mods)
	---@class MainSystemRegistry : SystemRegistry
	---@field init_systems fun(ctx: Context)[]
	---@field resources_loaded_systems fun(ctx: Context)[]
	---@field update_systems fun(ctx: Context)[]
	---@field draw_systems fun(ctx: Context)[]
	local system_reg = SystemRegistry.new({"init", "resources_loaded", "update", "draw"})
	local res = ResourceRegistry.new()
	
	for _, mod in ipairs(mods) do
		if mod.system_hooks then
			for _, hook in ipairs(mod.system_hooks) do
				system_reg:register(hook)
			end
		end
		if mod.importers then
			for _, registrator in ipairs(mod.importers) do
				res:register_importer(registrator)
			end
		end
	end
	
	local loops, orphans, hook_errors = system_reg:build_order()
	-- While there's no way to manage this in game, let's just print and stop.
	local errored = false
	
	if next(loops) then
		for _, loop in ipairs(loops) do
			local keys = {}
			for _, hook in ipairs(loop) do
				insert(keys, hook.system_key)
			end
			insert(keys, loop[1].system_key)
			print(fmt("Cyclical system dependencies: %s", table.concat(keys, " -> ")))
		end
		errored = true
	end
	
	if #orphans > 0 then
		for _, orphan in ipairs(orphans) do
			local keys = {}
			for key in pairs(orphan) do
				insert(keys, key)
			end
			print(fmt("Orphan system tree: %s", table.concat(keys, ", ")))
		end
		errored = true
	end
	
	if hook_errors then
		for _, v in ipairs(hook_errors) do
			print(v)
		end
		errored = true
	end
	
	if errored then stop() end
	
	--- @class Context
	local ctx = {
		mods = mods,
		system_reg = system_reg,
		res = res,
	}
	
	return ctx
end

----------------------------------Picotron Callbacks-----------------------------------

function _init()
	cd("src/mods")
	local mods = load_mods()
	ctx = new_context(mods)
	
	for _, system in ipairs(ctx.system_reg.init_systems) do
		system(ctx)
	end
	
	for _, mod in ipairs(ctx.mods) do
		if mod.resources then
			for _, resource in ipairs(mod.resources) do
				if ctx.res:register(ctx, resource) then
					printh("Registered resource: " .. resource.key)
				else
					printh(fmt("Failed to find resource \"%s\" with \"%s\"", resource.key, tostring(resource.value)))
				end
			end
		end
	end
	
	for _, system in ipairs(ctx.system_reg.resources_loaded_systems) do
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