--- Targets
-- @module arcana.Target
-- @author raymoo

local zero = { x = 0, y = 0, z = 0 }

local Target = {}
Target.__index = Target

local function metad(f)
	return function(...)
		local tab = f(...)
		setmetatable(tab, Target)
		return tab
	end
end

--- Targets, passed to spell components.
-- @section target

--- Specifiers for where a spell component should apply
-- @string type The type of target, either "pos" or "object"
-- @tparam vector pos The targeted position
-- @tparam ?ObjectRef ref The object, if this target is associated with one
-- @table Target

--- Functions.
-- @section functions

--- Construct a target with only a position and direction
-- @tparam vector pos
-- @tparam vector dir
-- @treturn Target
-- @function arcana.Target.pos
Target.pos = metad(function(pos, dir)
	if dir == nil or vector.equals(dir, zero) then
		dir = { x = 0, y = 1, z = 0 }
	end
	return {
		type = "pos",
		pos = pos,
		dir = vector.normalize(dir),
	}
end)

--- Construct a target using an object
-- @tparam vector pos
-- @tparam ?vector dir
-- @tparam ObjectRef ref
-- @treturn Target
-- @function arcana.Target.object
Target.object = metad(function(pos, dir, ref)
	if dir == nil or vector.equals(dir, zero) then
		dir = { x = 0, y = 1, z = 0 }
	end
	return {
		type = "object",
		pos = pos,
		dir = vector.normalize(dir),
		ref = ref,
	}
end)

--- Construct a casting target for a player
-- @tparam ObjectRef player
function Target.casted(player)
	local cast_pos = vector.add(player:get_pos(), arcana.look_offset)
	local cast_dir = player:get_look_dir()

	return Target.object(cast_pos, cast_dir, player)
end

--- Get the "look position" of a target.
-- @treturn vector
function Target:look_position()
	if self.type == "object" and self.ref:is_player() then
		return vector.add(self.ref:get_pos(), arcana.look_offset)
	else
		return self.pos
	end
end

arcana.Target = Target
