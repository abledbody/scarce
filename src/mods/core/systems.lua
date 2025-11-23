local InitSystems = require"core/init_systems"
local DrawSystems = require"core/draw_systems"
local insert = table.insert

local hooks = {}

for _, hook in ipairs(InitSystems) do
	insert(hooks, hook)
end
-- for _, hook in ipairs(update_systems) do
-- 	insert(init_systems, hook)
-- end
for _, hook in ipairs(DrawSystems) do
	insert(hooks, hook)
end

return hooks