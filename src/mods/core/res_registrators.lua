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

---@type ResourceRegistrator[]
local registrators = {
    {kind = "pal", func = verbatim},
    {kind = "font", func = verbatim},
    {kind = "map", func = verbatim},
    {kind = "sprite", func = reg_sprite},
    {kind = "generic", func = verbatim}
}

return registrators