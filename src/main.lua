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

---@param registry SystemRegistry
local function execute_and_handle(registry, ctx)
	local loops, orphans = registry:execute(ctx)
	
	if not (loops and orphans) then return end
	
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
	
	if errored then stop() end
end

---@return Context
local function new_context()
	--- @class Context
	local ctx = {
		before_imports = SystemRegistry.new(),
		after_imports  = SystemRegistry.new(),
		updates        = SystemRegistry.new(),
		draws          = SystemRegistry.new(),
		res = ResourceRegistry.new(),
	}
	
	return ctx
end

----------------------------------Picotron Callbacks-----------------------------------

function _init()
	cd("src/mods")
	local mods = load_mods()
	---@diagnostic disable-next-line: lowercase-global
	ctx = new_context()
	
	for _, mod in ipairs(mods) do
		if mod.register_systems then mod.register_systems(ctx) end
	end
	
	for _, mod in ipairs(mods) do
		if mod.register_importers then mod.register_importers(ctx.res) end
	end
	
	execute_and_handle(ctx.before_imports, ctx)
	for _, mod in ipairs(mods) do
		if mod.import_resources then mod.import_resources(ctx) end
	end
	execute_and_handle(ctx.after_imports, ctx)
end

function _update()
	execute_and_handle(ctx.updates, ctx)
end

function _draw()
	execute_and_handle(ctx.draws, ctx)
end

include"src/error_explorer.lua"