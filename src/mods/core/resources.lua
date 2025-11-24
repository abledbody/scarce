local ResourceRegistry = require_ext("src/resource_registry")
local tile_resources = require"core/tile_resources"
local insert = table.insert
local res = ResourceRegistry.new_resource

---@type Resource[]
local resources = {
    res("pal", "core_main", "core/pal/core.pal"),
    res("font", "core_charcoal", "core/font/charcoal.font"),
    
    res("coltab", "core_color_over", {file = "core/gfx/coltabs.gfx", i = 0}),
    
    res("map", "core_test", "core/map/0.map"),
    
    res("config", "core_ui_colors", "core/configs/colors.lua"),
    res("config", "core_ui_map", "core/configs/map.lua"),
    
	res("sprite", "core_anthro_canine", {file = "core/gfx/things.gfx", i = 0}),
	res("sprite", "core_anthro_draconic", {file = "core/gfx/things.gfx", i = 1}),
    
	res("sprite", "core_bush", {file = "core/gfx/things.gfx", i = 64}),
    
	res("sprite", "core_drawstring_bag", {file = "core/gfx/things.gfx", i = 128}),
    
	res("sprite", "core_ui_text_detached", {file = "core/gfx/ui.gfx", i = 0}),
}

for _, resource in ipairs(tile_resources) do
    insert(resources, resource)
end

return resources