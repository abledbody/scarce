local function default_ctor(tab, key, constructor, ...)
	local value = tab[key]
	if not value then
		value = constructor(...)
		tab[key] = value
	end
	return value
end

return {
	default_ctor = default_ctor,
}