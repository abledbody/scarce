local insert = table.insert
local fmt = string.format

---@class Mod
---@field system_hooks Hook[]?
---@field resources Resource[]?
---@field res_registrators ResourceRegistrator[]?
---@field dir string?

return function()
	-- Mod order is a list of the names of mods in the order they should be loaded and executed.
	local mod_order = fetch"/appdata/scarce/mod_order.pod"
	if not mod_order then
		mod_order = {"core"}
		store("/appdata/scarce/mod_order.pod", mod_order)
	end
	
	local working_directory = pwd()
	local mods = {}
	for _, mod_name in ipairs(mod_order) do
		local mod_directory_path = fmt("src/mods/%s/", mod_name)
		local mod_file_path = mod_directory_path .. "mod"
		local mod = fetch(mod_file_path .. ".lua")
		
		if not mod then
			printh(fmt("Mod not found: \"%s\". Skipping.", mod_file_path))
			goto continue
		end
		cd(mod_directory_path)
		mod = require("mod")
		cd(working_directory)
		mod.dir = mod_directory_path
		insert(mods, mod)
		::continue::
	end
	
	return mods
end