---@diagnostic disable: redefined-local

local Things = require"core/src/things"

---@param hook fun(key: string, target_relation: "Before"|"After", target_key: string, system: fun(ctx: Context))
local function register(hook)
	hook("core_apply_movement", "After", "root", Things.apply_movement)
end

return {
	register = register,
}