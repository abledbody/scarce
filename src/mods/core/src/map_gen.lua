local SystemRegistry = require_ext"src/system_registry"
local Things = require"core/src/things"
local Math = require"core/src/math"
local Rng = require"core/src/rng"
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
	ctx.map.tiles:copy(sprite, true)
	ctx.map.tile_colors:copy(ctx.res:get("sprite", "core_color_" .. tile.col), true)
end

---@param ctx MapGenerationContext
---@param tiles userdata
---@param colors userdata
---@param tile Tile
---@param mask userdata
local function fill_masked(ctx, tiles, colors, tile, mask)
	local sprite = ctx.res:get("sprite", tile.sprite)
	local color = ctx.res:get("sprite", "core_color_" .. tile.col)
	
	tiles:add((sprite - tiles) * mask, true)
	colors:add((color - colors) * mask, true)
end

---@param data userdata
---@param threshold number
---@param at_most true?
local function threshold_mask(data, threshold, at_most)
	local offset = at_most and (threshold - data) or (data - threshold)
	return offset:sgn():max(0):convert("i16")
end

---@param data userdata
---@param threshold number
---@param density number
---@param at_most true?
local function statistical_mask(data, threshold, density, at_most)
	local noise = Rng.random_vec(data:width(), data:height() or 1, rnd(2^53) // 1)
	local offset = at_most and (threshold - data) or (data - threshold)
	return (offset - noise * (1 - density)):sgn():max(0):convert("i16")
end

---@param data userdata
local function normalize(data)
	local scratch = data:copy()
	local minimum = scratch:min(scratch, true, 1, 0, 1, 1, 0, #scratch)[0]
	
	data:sub(minimum, true)
	
	scratch = data:copy()
	local maximum = scratch:max(scratch, true, 1, 0, 1, 1, 0, #scratch)[0]
	if maximum == 0 then return data end
	
	data:div(maximum, true)
end

---@param ctx MapGenerationContext
local function fill_basis(ctx)
	fill(ctx, ctx.params.basis_tile)
end

---@param ctx MapGenerationContext
local function height(ctx)
	---@class MapGenerationContext
	---@field height userdata f64
	
	local w, h = ctx.map.tiles:attribs()
	ctx.height = userdata("f64", w, h)
	
	for _, v in ipairs(ctx.params.heightmap_layers) do
		ctx.height += Math.perlin(
			w, h or 1,
			v.scale,
			random(2^53)
		) * v.strength
	end
	
	normalize(ctx.height)
	
	ctx.height = ctx.height^1.5
end

---@param ctx MapGenerationContext
local function slope(ctx)
	
	---@class MapGenerationContext
	---@field slope userdata f64
	
	local height = ctx.height
	local w, h = height:attribs()
	
	local x_slope = userdata("f64", w, h)
		:add(height,     true,     1, w, w - 1, w, w, h - 1) -- NE
		:add(height * 2, true,     1, 0, w - 1, w, w, h)     -- E
		:add(height,     true, w + 1, 0, w - 1, w, w, h - 1) -- SE
		
		:sub(height,     false, 0, w + 1, w - 1, w, w, h - 1) -- NW
		:sub(height * 2, true,  0,     1, w - 1, w, w, h)     -- W
		:sub(height,     true,  w,     1, w - 1, w, w, h - 1) -- SW
		
		:div(8, true)
	
	local y_slope = userdata("f64", w, h)
		:add(height,     true, 0, w + 1, w - 1, w, w, h - 1) -- NW
		:add(height * 2, true, 0,     w, w, w, w, h - 1) -- N
		:add(height,     true, 1,     w, w - 1, w, w, h - 1) -- NE
		
		:sub(height,     false,     w, 1, w - 1, w, w, h - 1) -- SW
		:sub(height * 2, true,      w, 0, w, w, w, h - 1) -- S
		:sub(height,     true,  w + 1, 0, w - 1, w, w, h - 1) -- SE
		
		:div(8, true)
	
	local slope = (x_slope * x_slope + y_slope * y_slope)^0.5
	
	ctx.slope = slope
		:copy(slope, true, 1, 0, 1, w, w, h)
		:copy(slope, true, w - 2, w - 1, 1, w, w, h)
		:copy(slope, true, w, 0, w)
		:copy(slope, true, w * (h - 2), w * (h - 1), w)
end

---@param ctx MapGenerationContext
local function temperature(ctx)
	---@class MapGenerationContext
	---@field temperature userdata f64
	
	local w, h = ctx.map.tiles:attribs()
	ctx.temperature = userdata("f64", w, h)
	
	for _, v in ipairs(ctx.params.temperature_layers) do
		ctx.temperature += Math.perlin(
			w, h or 1,
			v.scale,
			random(2^53)
		) * v.strength
	end
	
	ctx.temperature += ctx.height * ctx.params.height_affects_temperature
	normalize(ctx.temperature)
end

---@param ctx MapGenerationContext
local function moisture(ctx)
	---@class MapGenerationContext
	---@field moisture userdata f64
	
	local w, h = ctx.map.tiles:attribs()
	ctx.moisture = userdata("f64", w, h)
	
	for _, v in ipairs(ctx.params.moisture_layers) do
		ctx.moisture += Math.perlin(
			w, h or 1,
			v.scale,
			random(2^53)
		) * v.strength
	end
	
	normalize(ctx.moisture)
end

---@param ctx MapGenerationContext
local function fertility(ctx)
	---@class MapGenerationContext
	---@field fertility userdata f64
	
	local w, h = ctx.map.tiles:attribs()
	ctx.fertility = userdata("f64", w, h)
	
	for _, v in ipairs(ctx.params.fertility_layers) do
		ctx.fertility += Math.perlin(
			w, h or 1,
			v.scale,
			random(2^53)
		) * v.strength
	end
	
	ctx.fertility *= ctx.moisture * ctx.params.fertility_moisture_influence
end

---@param ctx MapGenerationContext
local function ocean(ctx)
	---@class MapGenerationContext
	---@field ocean_mask userdata i16
	
	local tiles = ctx.map.tiles
	local colors = ctx.map.tile_colors
	ctx.ocean_mask = threshold_mask(ctx.height, ctx.params.ocean_height, true)
	
	fill_masked(ctx, tiles, colors, ctx.res:get("tile", "core_ocean_water"), ctx.ocean_mask)
end

---@param ctx MapGenerationContext
local function cliffs(ctx)
	
	---@class MapGenerationContext
	---@field cliff_mask userdata i16
	
	local tiles = ctx.map.tiles
	local colors = ctx.map.tile_colors
	ctx.cliff_mask = threshold_mask(ctx.slope, ctx.params.cliff_threshold)
	
	fill_masked(ctx, tiles, colors, ctx.res:get("tile", "core_rock_face"), ctx.cliff_mask)
end

---@param ctx MapGenerationContext
local function snow(ctx)
	---@class MapGenerationContext
	---@field snowiness userdata f64
	---@field snow_mask userdata i16
	
	local tiles = ctx.map.tiles
	local colors = ctx.map.tile_colors
	
	ctx.snowiness =
		(ctx.params.snow_temperature_threshold - ctx.temperature)
		:min(ctx.moisture - ctx.params.snow_moisture_threshold)
	
	ctx.snow_mask = threshold_mask(ctx.snowiness, 0) * (1 - ctx.cliff_mask)
	
	fill_masked(ctx, tiles, colors, ctx.res:get("tile", "core_snow"), ctx.snow_mask)
end

---@param ctx MapGenerationContext
local function desert(ctx)
	---@class MapGenerationContext
	---@field desertness userdata f64
	---@field desert_mask userdata i16
	---@field desert_cliff_mask userdata i16
	
	local tiles = ctx.map.tiles
	local colors = ctx.map.tile_colors
	
	ctx.desert_mask = threshold_mask(ctx.fertility, ctx.params.desert_threshold, true)
	ctx.desert_cliff_mask = ctx.desert_mask * ctx.cliff_mask
	
	fill_masked(ctx, tiles, colors, ctx.res:get("tile", "core_sand_tan"), ctx.desert_mask)
	fill_masked(ctx, tiles, colors, ctx.res:get("tile", "core_sandstone_face"), ctx.desert_cliff_mask)
end

---@param ctx MapGenerationContext
local function plant_saplings(ctx)
	---@class MapGenerationContext
	---@field sapling_mask userdata i16
	---@field saplingness userdata f64
	
	local tiles = ctx.map.things
	local colors = ctx.map.thing_colors
	
	ctx.saplingness = (
			ctx.params.sapling_temp_bandwidth
			- (ctx.temperature - ctx.params.sapling_ideal_temp):abs()
		):min(ctx.fertility - ctx.params.sapling_fertility_threshold)
	
	ctx.sapling_mask = statistical_mask(
		ctx.saplingness,
		0,
		ctx.params.sapling_density
	) * (1 - ctx.ocean_mask)
	
	fill_masked(ctx, tiles, colors, ctx.res:get("tile", "core_sapling_green"), ctx.sapling_mask)
end

---@param ctx MapGenerationContext
local function plant_trees(ctx)
		---@class MapGenerationContext
	---@field tree_mask userdata i16
	---@field treeness userdata f64
	
	local tiles = ctx.map.things
	local colors = ctx.map.thing_colors
	
	ctx.treeness = (
			ctx.params.tree_temp_bandwidth
			- (ctx.temperature - ctx.params.tree_ideal_temp):abs()
		):min(ctx.fertility - ctx.params.tree_fertility_threshold)
	
	ctx.tree_mask = statistical_mask(
		ctx.treeness,
		0,
		ctx.params.tree_density
	) * (1 - ctx.ocean_mask)
	
	fill_masked(ctx, tiles, colors, ctx.res:get("tile", "core_evergreen_dark"), ctx.tree_mask)
end

---@param ctx MapGenerationContext
local function init_map(ctx)
	---@class MapGenerationContext
	---@field game_ctx Context
	---@field map Map
	---@field entity_map EntityMap
	---@field seed integer
	
	local size = ctx.params.size
	
	---@class Map
	ctx.map = {
		tiles = userdata("i16", size.x, size.y),
		tile_colors = userdata("i16", size.x, size.y),
		thing_colors = userdata("i16", size.x, size.y),
		things = userdata("i16", size.x, size.y),
	}
	
	ctx.entity_map = Things.new_map(size)
	randomseed(ctx.params.seed)
end

---@param ctx Context
local function register_core_hooks(ctx)
	local import = ctx.map_gen.generate_systems:make_registrator()
	
	import("core_init", "After", "root", init_map)
	
	import("core_height", "After", "core_init", height)
	import("core_slope", "After", "core_height", slope)
	import("core_temperature", "After", "core_height", temperature)
	import("core_moisture", "After", "core_init", moisture)
	import("core_fertility", "After", "core_moisture", fertility)
	
	import("core_fill_basis", "After", "core_init", fill_basis)
	import("core_cliffs", "After", "core_init", cliffs)
	import("core_desert", "After", "core_init", desert)
	import("core_snow", "After", "core_init", snow)
	import("core_ocean", "After", "core_init", ocean)
	
	import("core_plant_saplings", "After", "core_init", plant_saplings)
	import("core_plant_trees", "After", "core_init", plant_trees)
end

---@class MapGenerator
local m_map_gen = {}
m_map_gen.__index = m_map_gen

---@param game_ctx Context
---@param params table
---@return MapGenerationContext
function m_map_gen:generate(game_ctx, params)
	---@class MapGenerationContext
	local ctx = {
		game_ctx = game_ctx,
		res = ctx.res,
		params = params,
	}
	
	self.generate_systems:execute(ctx)
	
	return ctx
end

---@return MapGenerator
local function new()
	---@class MapGenerator
	local map_gen = {
		generate_systems = SystemRegistry.new()
	}
	
	return setmetatable(map_gen, m_map_gen)
end

return {
	new = new,
	register_core_hooks = register_core_hooks,
}