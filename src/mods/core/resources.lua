---@type Resource[]
local resources = {
    {kind = "pal", key = "core_palette", value = "core/pal/core.pal"},
    {kind = "font", key = "core_font_charcoal", value = "core/font/charcoal.font"},
    
    {kind = "coltab", key = "core_coltab_color_over", value = {file = "core/gfx/coltabs.gfx", i = 0}},
    
    {kind = "map", key = "core_map_test", value = "core/map/0.map"},
    
    {kind = "generic", key = "core_colors_ui", value = "core/colors/ui.pod"},
    {kind = "generic", key = "core_ui_config_map", value = "core/ui_config/map.pod"},
}

return resources