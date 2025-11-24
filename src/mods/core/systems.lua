local InitSystems = require"core/init_systems"
local DrawSystems = require"core/draw_systems"
local UpdateSystems = require"core/update_systems"
local insert = table.insert

local hooks = {}

for _, hook in ipairs(InitSystems) do
	insert(hooks, hook)
end
for _, hook in ipairs(UpdateSystems) do
	insert(hooks, hook)
end
for _, hook in ipairs(DrawSystems) do
	insert(hooks, hook)
end

return hooks