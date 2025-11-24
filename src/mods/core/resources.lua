local tile_resources = require"core/tile_resources"
local insert = table.insert

---@type Resource[]
local resources = {
    {kind = "pal", key = "core_palette", value = "core/pal/core.pal"},
    {kind = "font", key = "core_font_charcoal", value = "core/font/charcoal.font"},
    
    {kind = "coltab", key = "core_coltab_color_over", value = {file = "core/gfx/coltabs.gfx", i = 0}},
    
    {kind = "map", key = "core_map_test", value = "core/map/0.map"},
    
    {kind = "generic", key = "core_colors_ui", value = "core/colors/ui.pod"},
    {kind = "generic", key = "core_ui_config_map", value = "core/ui_config/map.pod"},
    
	{kind = "sprite", key = "core_sprite_anthro_canine", value = {file = "core/gfx/things.gfx", i = 0}},
	{kind = "sprite", key = "core_sprite_anthro_draconic", value = {file = "core/gfx/things.gfx", i = 1}},
    
	{kind = "sprite", key = "core_sprite_bush", value = {file = "core/gfx/things.gfx", i = 64}},
    
	{kind = "sprite", key = "core_sprite_drawstring_bag", value = {file = "core/gfx/things.gfx", i = 128}},
    
	{kind = "sprite", key = "core_sprite_ui_text_detached", value = {file = "core/gfx/ui.gfx", i = 0}},
}

for _, resource in ipairs(tile_resources) do
    insert(resources, resource)
end

return resources