---@param value string
---@return any
local function verbatim(_, value)
    return fetch(value)
end

---@param ctx Context
---@param value {file: string, i: integer}
---@return integer?
local function reg_sprite(ctx, value)
    local file, i = value.file, value.i
    if i >= 256 then return end
    
    local gfx = fetch(file) ---@type Sprite[]
    if not gfx then return end
    
    return ctx.graphics:add_sprite(gfx[i])
end

---@param value {file: string, i: integer}
---@return userdata?
local function reg_coltab(_, value)
    local file, i = value.file, value.i
    if i >= 256 then return end
    
    local gfx = fetch(file) ---@type Sprite[]
    if not gfx then return end
    
    return gfx[i].bmp
end

---@param value string
---@return table
local function reg_config(_, value)
    return include(value)
end

---@type ResourceRegistrator[]
local registrators = {
    {kind = "config", func = reg_config},
    {kind = "pal", func = verbatim},
    {kind = "font", func = verbatim},
    {kind = "map", func = verbatim},
    {kind = "sprite", func = reg_sprite},
    {kind = "coltab", func = reg_coltab},
}

return registrators