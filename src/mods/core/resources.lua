local tile_resources = require"core/tile_resources"
local insert = table.insert

---@type Resource[]
local resources = {
    {kind = "pal", key = "core_main", value = "core/pal/core.pal"},
    {kind = "font", key = "core_charcoal", value = "core/font/charcoal.font"},
    
    {kind = "coltab", key = "core_color_over", value = {file = "core/gfx/coltabs.gfx", i = 0}},
    
    {kind = "map", key = "core_test", value = "core/map/0.map"},
    
    {kind = "config", key = "core_ui_colors", value = "core/configs/colors.lua"},
    {kind = "config", key = "core_ui_map", value = "core/configs/map.lua"},
    
	{kind = "sprite", key = "core_anthro_canine", value = {file = "core/gfx/things.gfx", i = 0}},
	{kind = "sprite", key = "core_anthro_draconic", value = {file = "core/gfx/things.gfx", i = 1}},
    
	{kind = "sprite", key = "core_bush", value = {file = "core/gfx/things.gfx", i = 64}},
    
	{kind = "sprite", key = "core_drawstring_bag", value = {file = "core/gfx/things.gfx", i = 128}},
    
	{kind = "sprite", key = "core_ui_text_detached", value = {file = "core/gfx/ui.gfx", i = 0}},
}

for _, resource in ipairs(tile_resources) do
    insert(resources, resource)
end

return resources