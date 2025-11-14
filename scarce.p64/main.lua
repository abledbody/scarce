--[[pod_format="raw",created="2025-05-21 04:11:58",modified="2025-06-08 04:31:16",revision=1013]]
DATP = ""
if not fetch"src/main.lua" then
	cd("/projects/games/scarce")
	DATP = "scarce.p64/"
end
include"src/main.lua"