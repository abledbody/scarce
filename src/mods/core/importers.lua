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

---@param res ResourceRegistry
local function register(res)
    res:register_importer("data", function(_, v) return v end)
        :register_importer("pod", reg_pod)
        :register_importer("config", reg_config)
        :register_importer("sprite", reg_sprite)
        :register_importer("sprite_ud", reg_sprite_ud)
        :register_importer("proc_sprite", reg_proc_sprite)
end

return {
    register = register,
}