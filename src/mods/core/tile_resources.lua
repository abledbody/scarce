local ResourceRegistry = require_ext("src/resource_registry")
local res = ResourceRegistry.new_resource

---@type Resource[]
local resources = {
	res("sprite", "core_grass", {file = "core/gfx/tiles.gfx", i = 0}),
	
	res("sprite", "core_large_brick", {file = "core/gfx/tiles.gfx", i = 64}),
	res("sprite", "core_square_cobblestone", {file = "core/gfx/tiles.gfx", i = 65}),
	res("sprite", "core_riveted_plate", {file = "core/gfx/tiles.gfx", i = 66}),
}

return resources