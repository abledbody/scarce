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

---@param ctx Context
---@param value {file: string, i: integer}
---@return userdata?
local function reg_coltab(ctx, value)
    local file, i = value.file, value.i
    if i >= 256 then return end
    
    local gfx = fetch(file) ---@type Sprite[]
    if not gfx then return end
    
    return gfx[i].bmp
end

---@type ResourceRegistrator[]
local registrators = {
    {kind = "generic", func = verbatim},
    {kind = "pal", func = verbatim},
    {kind = "font", func = verbatim},
    {kind = "map", func = verbatim},
    {kind = "sprite", func = reg_sprite},
    {kind = "coltab", func = reg_coltab},
}

return registrators