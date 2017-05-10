
local zero = { x = 0, y = 0, z = 0 }

local Target = {}
Target.__index = Target

local function metad(f)
	return function(...)
		local tab = f(...)
		setmetatable(tab, Target)
	end
end

Target.pos_target = metad(function(pos, dir)
	if vector.equals(dir, zero) then
		dir = { x = 0, y = 1, z = 0 }
	end
	return {
		type = "pos",
		pos = pos,
		dir = vector.normalize(dir),
	}
end)

Target.object_target = metad(function(ref, dir)
	if vector.equals(dir, zero) then
		dir = { x = 0, y = 1, z = 0 }
	end
	return {
		type = "object",
		ref = ref,
		dir = vector.normalize(dir),
	}
end)

arcana.Target = Target
