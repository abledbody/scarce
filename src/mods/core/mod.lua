local Importers = require"core/importers"
local Resources = require"core/resources"
local BeforeImportsSystems = require"core/before_imports_systems"
local AfterImportsSystems = require"core/after_imports_systems"
local UpdateSystems = require"core/update_systems"
local DrawSystems = require"core/draw_systems"

---@type Mod
local mod = {
	register_systems = function(ctx)
		BeforeImportsSystems.register(ctx.before_imports:make_registrator())
		AfterImportsSystems.register(ctx.after_imports:make_registrator())
		UpdateSystems.register(ctx.updates:make_registrator())
		DrawSystems.register(ctx.draws:make_registrator())
	end,
	
	register_importers = Importers.register,
	
	import_resources = function(ctx)
		Resources.register(ctx.res:make_registrator(ctx))
	end
}

return mod