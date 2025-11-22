---@type Hook[]
local hooks = {
	{system_key = "core_init", target_key = "init", target_relation = "After", system = 
		function(_)
			window()
		end
	},
	{system_key = "core_init_palette", target_key = "core_init", target_relation = "After", system =
		function(ctx)
			memmap(ctx.res:get"core_palette", 0x5000)
		end
	},
	{system_key = "core_init_font", target_key = "core_init", target_relation = "After", system =
		function(ctx)
			ctx.res:get"core_font_charcoal":poke(0x4000)
		end
	},
}

return hooks