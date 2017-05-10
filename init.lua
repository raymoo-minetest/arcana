
arcana = {}
local modpath = minetest.get_modpath("arcana") .. "/"

function arcana.load(path)
	return dofile(modpath .. path)
end

arcana.load("spell.lua")
