local insert = table.insert
local fmt = string.format

---@class Mod
---@field register_systems fun(ctx: Context)?
---@field register_importers fun(res: ResourceRegistry)?
---@field import_resources fun(ctx: Context)?

---@return Mod[]
return function()
	-- Mod order is a list of the names of mods in the order they should be loaded and executed.
	mkdir("/appdata/scarce")
	local mod_order = unpod(fetch"/appdata/scarce/mod_order.txt")
	if type(mod_order) != "table" then
		mod_order = {"core"}
		---@diagnostic disable-next-line param-type-mismatch
		store("/appdata/scarce/mod_order.txt", pod(mod_order, 0))
	end
	
	local mods = {}
	for _, mod_name in ipairs(mod_order) do
		local mod_file_path = mod_name .. "/mod"
		local mod = fetch(mod_file_path .. ".lua")
		
		if not mod then
			printh(fmt("Mod not found: \"%s\". Skipping.", mod_file_path))
			goto continue
		end
		mod = require(mod_file_path)
		mod.dir = mod_name
		insert(mods, mod)
		::continue::
	end
	
	return mods
end