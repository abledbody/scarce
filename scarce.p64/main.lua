--[[pod_format="raw",created="2025-05-21 04:11:58",modified="2025-06-07 02:30:34",revision=807]]
DATP = ""
if not include"src/game.lua" then
	cd("/projects/scarce")
	DATP = "scarce.p64/"
	include"src/game.lua"
end