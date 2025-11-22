local _modules = {}

function require(name)
	local path = fullpath(name:gsub('%.', '/') .. '.lua')
	if _modules[path] == nil then
		_modules[path] = include(path)
	end
	return _modules[path]
end
