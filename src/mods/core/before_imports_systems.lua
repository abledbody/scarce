---@diagnostic disable: redefined-local

local new_graphics_data = require"core/src/graphics"
local MapGeneration = require"core/src/map_gen"
local Ecs = require"core/src/ecs"

---@param hook fun(key: string, target_relation: "Before"|"After", target_key: string, system: fun(ctx: Context))
local function register(hook)
	hook("core_root", "After", "root", 
		function(ctx)
			window()
			
			---@class Context
			---@field graphics GraphicsData
			---@field camera_pos userdata
			---@field entities Entities
			---@field map_gen MapGenerator
			
			ctx.graphics = new_graphics_data()
			ctx.camera_pos = vec(0, 0)
			ctx.entities = Ecs.new()
			ctx.map_gen = MapGeneration.new()
		end
	)
end

return {
	register = register,
}