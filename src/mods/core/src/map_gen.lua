local SystemRegistry = require_ext"src/system_registry"
local Entities = require"core/src/entities"

local hook = SystemRegistry.new_hook

---@param ctx MapGenerationContext
local function fill(ctx)
	local fill_tile = ctx.params.fill_tile
	local grass_sprite = ctx.res:get("sprite", fill_tile.sprite)
	ctx.map[4].bmp:copy(grass_sprite, true)
	ctx.map[3].bmp:copy(ctx.res:get("sprite", "core_color_" .. fill_tile.col), true)
end

---@param ctx MapGenerationContext
local function init_map(ctx)
	---@class MapGenerationContext
	---@field map Map
	---@field entities EntityMap
	
	local size = ctx.params.size
	
	---@class Map
	ctx.map = {
		[1] = {bmp = userdata("i16", size.x, size.y)},
		[2] = {bmp = userdata("i16", size.x, size.y)},
		[3] = {bmp = userdata("i16", size.x, size.y)},
		[4] = {bmp = userdata("i16", size.x, size.y)},
	}
	
	ctx.entities = Entities.new_map(size.x)
end

local function register_core_hooks(ctx)
	local registry = ctx.map_gen.sys_reg
	
	registry:register(hook("core_init", "After", "generate", init_map))
	registry:register(hook("core_fill", "After", "core_init", fill))
end

---@class MapGenerator
local m_map_gen = {}
m_map_gen.__index = m_map_gen

---@param res ResourceRegistry
---@param params table
---@return Map
function m_map_gen:generate(res, params)
	local _, _, errs = self.sys_reg:build_order()
	if errs then
		error(errs[1])
	end
	
	---@class MapGenerationContext
	local ctx = {
		res = res,
		params = params,
	}
	
	for _, system in ipairs(self.sys_reg.generate_systems) do
		system(ctx)
	end
	
	return ctx.map
end

---@return MapGenerator
local function new()
	---@class MapGenerator
	local map_gen = {
		---@class MapGeneratorSystemRegistry : SystemRegistry
		---@field generate_systems fun(ctx: MapGenerationContext)[]
		sys_reg = SystemRegistry.new({"generate"})
	}
	
	return setmetatable(map_gen, m_map_gen)
end

return {
	new = new,
	register_core_hooks = register_core_hooks,
}