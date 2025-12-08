local ResourceRegistry = require_ext("src/resource_registry")
local res = ResourceRegistry.new_resource

---@type Resource[]
local resources = {
	res("sprite", "sprite", "core_grass", {file = "core/gfx/tiles.gfx", i = 0}),
	res("sprite", "sprite", "core_wavy", {file = "core/gfx/tiles.gfx", i = 1}),
	res("sprite", "sprite", "core_seafoam", {file = "core/gfx/tiles.gfx", i = 2}),
	res("sprite", "sprite", "core_small_waves", {file = "core/gfx/tiles.gfx", i = 3}),
	
	res("sprite", "sprite", "core_large_brick", {file = "core/gfx/tiles.gfx", i = 64}),
	res("sprite", "sprite", "core_square_cobblestone", {file = "core/gfx/tiles.gfx", i = 65}),
	res("sprite", "sprite", "core_riveted_plate", {file = "core/gfx/tiles.gfx", i = 66}),
	
	res("data", "tile", "core_grass_green", {sprite = "core_grass", col = 11}),
	res("data", "tile", "core_sand_tan", {sprite = "core_wavy", col = 15}),
	res("data", "tile", "core_ocean_water", {sprite = "core_small_waves", col = 12}),
}

return resources