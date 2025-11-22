local function verbatim(_, value)
    return fetch(value)
end

---@type ResourceRegistrator[]
local registrators = {
    {kind = "pal", func = verbatim},
    {kind = "font", func = verbatim}
}

return registrators