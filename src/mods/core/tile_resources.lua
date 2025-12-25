---@param import fun(importer: string, kind: string, key: string, resource: any)
local function register(import)
	import("sprite", "sprite", "core_grass", {file = "core/gfx/tiles.gfx", i = 0})
	import("sprite", "sprite", "core_wavy", {file = "core/gfx/tiles.gfx", i = 1})
	import("sprite", "sprite", "core_seafoam", {file = "core/gfx/tiles.gfx", i = 2})
	import("sprite", "sprite", "core_small_waves", {file = "core/gfx/tiles.gfx", i = 3})
	import("sprite", "sprite", "core_rocky", {file = "core/gfx/tiles.gfx", i = 4})
	import("sprite", "sprite", "core_geometric_rocks", {file = "core/gfx/tiles.gfx", i = 5})
	
	import("sprite", "sprite", "core_large_brick", {file = "core/gfx/tiles.gfx", i = 64})
	import("sprite", "sprite", "core_square_cobblestone", {file = "core/gfx/tiles.gfx", i = 65})
	import("sprite", "sprite", "core_riveted_plate", {file = "core/gfx/tiles.gfx", i = 66})
	
	import("data", "tile", "core_grass_green", {sprite = "core_grass", col = 11})
	import("data", "tile", "core_sand_tan", {sprite = "core_wavy", col = 15})
	import("data", "tile", "core_ocean_water", {sprite = "core_small_waves", col = 12})
	import("data", "tile", "core_snow", {sprite = "core_wavy", col = 7})
	import("data", "tile", "core_rock_face", {sprite = "core_rocky", col = 22})
	import("data", "tile", "core_sandstone_face", {sprite = "core_geometric_rocks", col = 15})
	
	import("data", "tile", "core_evergreen_dark", {sprite = "core_evergreen", col = 3})
	import("data", "tile", "core_sapling_green", {sprite = "core_sapling", col = 11})
	import("data", "tile", "core_boulder_grey", {sprite = "core_boulder", col = 22, random_flip_x = true})
end

return {
	register = register,
}