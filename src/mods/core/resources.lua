local TileResources = require"core/tile_resources"

---@param import fun(importer: string, kind: string, key: string, resource: any)
local function register(import)
	import("pod", "pal", "core_main", "core/pal/core.pal")
	import("pod", "font", "core_charcoal", "core/font/charcoal.font")
	
	import("sprite_ud", "coltab", "core_color_over", {file = "core/gfx/coltabs.gfx", i = 0})
	
	import("config", "config", "core_ui_colors", "core/configs/colors.lua")
	import("config", "config", "core_viewport", "core/configs/viewport.lua")
	import("config", "config", "core_map", "core/configs/map.lua")
	
	import("sprite", "sprite", "core_anthro_canine", {file = "core/gfx/things.gfx", i = 0})
	import("sprite", "sprite", "core_anthro_draconic", {file = "core/gfx/things.gfx", i = 1})
	
	import("sprite", "sprite", "core_bush", {file = "core/gfx/things.gfx", i = 64})
	import("sprite", "sprite", "core_evergreen", {file = "core/gfx/things.gfx", i = 65})
	import("sprite", "sprite", "core_sapling", {file = "core/gfx/things.gfx", i = 66})
	import("sprite", "sprite", "core_boulder", {file = "core/gfx/things.gfx", i = 67})
	
	import("sprite", "sprite", "core_drawstring_bag", {file = "core/gfx/things.gfx", i = 128})
	
	import("sprite", "sprite", "core_ui_text_detached", {file = "core/gfx/ui.gfx", i = 0})
	
	for i = 0, 63 do
		import("proc_sprite", "sprite", "core_color_" .. i, userdata("u8",1,1):copy(i, true))
	end
	
	TileResources.register(import)
end

return {
	register = register,
}