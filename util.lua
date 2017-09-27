
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
		local entity_dir = arcana.direction(cone_pos, entity:get_pos())

		-- Dot product of two unit vectors is their cosine. Higher
		-- cosines are closer together.
		if arcana.dot(cone_dir, entity_dir) > bound then
			table.insert(contained_entities, entity)
		end
	end

	return contained_entities
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
		local distance = vector.distance(cone_pos, entity:get_pos())
		if distance < entity_distance and entity ~= exclude then
			entity_distance = distance
			closest_entity = entity
		end
	end

	local entity_target
	local entity_distance
	if closest_entity then
		local entity_pos = closest_entity:get_pos()
		local entity_dir = arcana.direction(cone_pos, entity_pos)
		entity_target =
			arcana.Target.object(entity_pos, entity_dir, closest_entity)
		entity_distance = vector.distance(cone_pos, entity_pos)
	end

	local dir_norm = vector.normalize(cone_dir)
	local look_end = vector.add(cone_pos, vector.multiply(dir_norm, range))
	local no_node, node_pos = minetest.line_of_sight(cone_pos, look_end, 0.1)

	local node_target
	local node_distance
	if not no_node then
		local node_dir = arcana.direction(cone_pos, node_pos)
		node_target = arcana.Target.pos(node_pos, node_dir)
		node_distance = vector.distance(cone_pos, node_pos)
	end

	if no_node then
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
