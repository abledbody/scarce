---@param value string
---@return any
local function reg_pod(_, value)
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
local function reg_sprite_ud(_, value)
    local file, i = value.file, value.i
    if i >= 256 then return end
    
    local gfx = fetch(file) ---@type Sprite[]
    if not gfx then return end
    
    return gfx[i].bmp
end

---@param ctx Context
---@param value userdata
---@return integer
local function reg_proc_sprite(ctx, value)
    return ctx.graphics:add_sprite_raw(value)
end

---@param value string
---@return table
local function reg_config(_, value)
    return include(value)
end

---@type Importer[]
local registrators = {
    {key = "data", func = function(_, v) return v end},
    {key = "pod", func = reg_pod},
    {key = "config", func = reg_config},
    {key = "sprite", func = reg_sprite},
    {key = "sprite_ud", func = reg_sprite_ud},
    {key = "proc_sprite", func = reg_proc_sprite},
}

return registrators