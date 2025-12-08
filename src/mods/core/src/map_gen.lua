local SystemRegistry = require_ext"src/system_registry"
local Entities = require"core/src/entities"
local Math = require"core/src/math"
local random = math.random
local randomseed = math.randomseed

local hook = SystemRegistry.new_hook

---@class Tile
---@field sprite string
---@field col integer

---@param ctx MapGenerationContext
---@param tile Tile
local function fill(ctx, tile)
	local sprite = ctx.res:get("sprite", tile.sprite)
	ctx.map[4].bmp:copy(sprite, true)
	ctx.map[3].bmp:copy(ctx.res:get("sprite", "core_color_" .. tile.col), true)
end

---@param tiles userdata
---@param colors userdata
---@param tile Tile
---@param mask userdata
local function fill_masked(tiles, colors, tile, mask)
	local sprite = ctx.res:get("sprite", tile.sprite)
	local color = ctx.res:get("sprite", "core_color_" .. tile.col)
	
	tiles:add((sprite - tiles) * mask, true)
	colors:add((color - colors) * mask, true)
end

---@param data userdata
---@param threshold number
local function threshold_mask(data, threshold)
	return (data - threshold):sgn0():max(0):convert("i16")
end

---@param ctx MapGenerationContext
local function fill_basis(ctx)
	fill(ctx, ctx.params.basis_tile)
end

---@param ctx MapGenerationContext
local function ocean(ctx)
	---@class MapGenerationContext
	---@field oceanness userdata f64
	---@field ocean_mask userdata i16
	
	local tiles = ctx.map[4].bmp
	local colors = ctx.map[3].bmp
	ctx.oceanness = Math.perlin(
		tiles:width(), tiles:height() or 1,
		ctx.params.ocean_size,
		random(2^53)
	)
	ctx.ocean_mask = threshold_mask(ctx.oceanness, ctx.params.ocean_threshold)
	
	fill_masked(tiles, colors, ctx.res:get("tile", "core_ocean_water"), ctx.ocean_mask)
end

---@param ctx MapGenerationContext
local function desert(ctx)
	---@class MapGenerationContext
	---@field desertness userdata f64
	---@field desert_mask userdata i16
	
	local tiles = ctx.map[4].bmp
	local colors = ctx.map[3].bmp
	
	ctx.desertness = Math.perlin(
		tiles:width(), tiles:height() or 1,
		ctx.params.ocean_size,
		random(2^53)
	) + ctx.oceanness * ctx.params.beach_factor
	ctx.desert_mask =
		threshold_mask(ctx.desertness, ctx.params.desert_threshold)
		* (1 - ctx.ocean_mask)
	
	fill_masked(tiles, colors, ctx.res:get("tile", "core_sand_tan"), ctx.desert_mask)
end

---@param ctx MapGenerationContext
local function init_map(ctx)
	---@class MapGenerationContext
	---@field map Map
	---@field entities EntityMap
	---@field seed integer
	
	local size = ctx.params.size
	
	---@class Map
	ctx.map = {
		[1] = {bmp = userdata("i16", size.x, size.y)},
		[2] = {bmp = userdata("i16", size.x, size.y)},
		[3] = {bmp = userdata("i16", size.x, size.y)},
		[4] = {bmp = userdata("i16", size.x, size.y)},
	}
	
	ctx.entities = Entities.new_map(size.x)
	randomseed(ctx.params.seed)
end

local function register_core_hooks(ctx)
	local registry = ctx.map_gen.sys_reg
	
	registry:register(hook("core_init", "After", "generate", init_map))
	registry:register(hook("core_fill_basis", "After", "core_init", fill_basis))
	registry:register(hook("core_ocean", "After", "core_fill_basis", ocean))
	registry:register(hook("core_desert", "After", "core_ocean", desert))
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