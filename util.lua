
arcana.look_offset = {
	x = 0,
	y = 1.625,
	z = 0,
}

function arcana.direction(v1, v2)
	return vector.normalize(vector.subtract(v2, v1))
end

function arcana.dot(v1, v2)
	return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

function arcana.object_center(obj)
	if obj:is_player() then
		return vector.add(obj:get_pos(), { x = 0, y = 1, z = 0 })
	else
		return obj:get_pos()
	end
end

function arcana.within(low, high, point, radius)
	radius = radius or 0
	return low.x < point.x + radius and high.x > point.x - radius
		and low.y < point.y + radius and high.y > point.y - radius
		and low.z < point.z + radius and high.z > point.z - radius
end

function arcana.point_in_object(point, obj, radius)
	local obj_center = arcana.object_center(obj)
	local collisionbox = obj:get_properties().collisionbox

	local low = {
		x = obj_center.x + collisionbox[1],
		y = obj_center.y + collisionbox[2],
		z = obj_center.z + collisionbox[3],
	}

	local high = {
		x = obj_center.x + collisionbox[4],
		y = obj_center.y + collisionbox[5],
		z = obj_center.z + collisionbox[6],
	}

	return arcana.within(low, high, point, radius)
end

--- Returns a list of entities in a specified cone.
-- @tparam vector cone_pos
-- @tparam vector cone_dir
-- @number width_deg The width in degrees
-- @number range
-- @treturn table List of entities in cone
function arcana.entities_in_cone(cone_pos, cone_dir, width_deg, range)
	local width = math.rad(width_deg)
	local bound = math.cos(width)
	local cone_dir_norm = vector.normalize(cone_dir)
	local entities_in_range =
		minetest.get_objects_inside_radius(cone_pos, range)

	local contained_entities = {}
	for _, entity in ipairs(entities_in_range) do
		local entity_dir = arcana.direction(cone_pos,
						    arcana.object_center(entity))

		-- Dot product of two unit vectors is their cosine. Higher
		-- cosines are closer together.
		if arcana.dot(cone_dir, entity_dir) > bound then
			table.insert(contained_entities, entity)
		end
	end

	return contained_entities
end

-- Casts for a node target, ignoring the first
-- dir should be normalized
local function node_cast(pos, dir, distance)
	local iter = arcana.line_iterator(pos, dir, distance)
	iter()
	for t, node_pos in iter do
		local node = minetest.get_node(node_pos)
		local node_def = minetest.registered_nodes[node.name]
		if node_def.walkable then
			local hit_pos = vector.add(pos, vector.multiply(dir, t))
			return t, arcana.Target.pos(hit_pos, dir)
		end
	end
end

--- Finds the closest target in a cone.
-- @tparam vector cone_pos
-- @tparam vector cone_dir
-- @number width_deg The width in degrees
-- @number range
-- @tparam ObjectRef exclude An object to exclude from targetting
-- @treturn ?Target
function arcana.target_in_cone(cone_pos, cone_dir, width_deg, range, exclude)
	local potential_hits =
		arcana.entities_in_cone(cone_pos, cone_dir, width_deg, range)
	
	local entity_distance = range + 1
	local closest_entity
	
	for _, entity in ipairs(potential_hits) do
		local distance = vector.distance(cone_pos, arcana.object_center(entity))
		if distance < entity_distance and entity ~= exclude then
			entity_distance = distance
			closest_entity = entity
		end
	end

	local entity_target
	local entity_distance
	if closest_entity then
		local entity_pos = arcana.object_center(closest_entity)
		local entity_dir = arcana.direction(cone_pos, entity_pos)
		entity_target =
			arcana.Target.object(entity_pos, entity_dir, closest_entity)
		entity_distance = vector.distance(cone_pos, entity_pos)
	end

	local dir_norm = vector.normalize(cone_dir)
	local node_distance, node_target = node_cast(cone_pos, dir_norm, range)

	if not node_target then
		return entity_target
	elseif not closest_entity then
		return node_target
	else
		if entity_distance < node_distance then
			return entity_target
		else
			return node_target
		end
	end
end

--- Returns the target at a point. Favors entities.
-- @tparam vector point
-- @tparam vector dir
-- @treturns ?Target
function arcana.target_at_point(point, dir, radius, exclude)
	local objects = minetest.get_objects_inside_radius(point, 5)
	local object_target
	for _, object in ipairs(objects) do
		if arcana.point_in_object(point, object) and object ~= exclude then
			return arcana.Target.object(point, dir, object)
		end
	end

	-- If there was no valid object
	local node_def = minetest.registered_items[minetest.get_node(point).name]
	if node_def.walkable then
		return arcana.Target.pos(point, dir)
	end

	-- If there was nothing to hit we return nothing
end

