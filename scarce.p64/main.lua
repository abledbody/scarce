--[[pod_format="raw",created="2025-05-21 04:11:58",modified="2025-06-08 04:31:16",revision=1013]]
DATP = ""
if not include"src/game.lua" then
	cd("/projects/scarce")
	DATP = "scarce.p64/"
	include"src/game.lua"
end