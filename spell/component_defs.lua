
local register = arcana.Component.register

local function multiplier_cost(multiplier)
	return function(self)
		return self:children_cost() * multiplier
	end
end

-- Passes the target through
register({
	name = "arcana:initial",
	description = "Pass-through",
	type = "shape",
	action = function(self, target, context)
		self:apply_children(target, context)
	end,
	cost = multiplier_cost(1)
})

local function cone_action(width, range, strike_air)
	return function(self, target, context)
		local cone_pos = target.pos
		local cone_dir = target.dir
		local target = arcana.target_in_cone(cone_pos, cone_dir,
			width, range, target.ref)

		if target then
			self:apply_children(target, context)
		elseif strike_air then
			local backup_pos =
				vector.add(cone_pos, vector.multiply(cone_dir, range))
			self:apply_children(arcana.Target.pos(backup_pos, cone_dir))
		end

	end
end

-- Applies something in look direction
local telekinesis_width = 10
local telekinesis_range = 10
register({
	name = "arcana:telekinesis",
	description = "Telekinesis",
	texture = "arcana_telekinesis.png",
	type = "shape",
	action = cone_action(telekinesis_width, telekinesis_range, true),
	cost = multiplier_cost(2),
})

-- Applies something in front
-- Technically more like short-range telekinesis
local touch_width = 60
local touch_range = 2
register({
	name = "arcana:touch",
	description = "Touch",
	texture = "arcana_touch.png",
	type = "shape",
	action = cone_action(touch_width, touch_range),
	cost = multiplier_cost(1.5),
})

local cone_width = 45
local cone_range = 5

local function make_cone_particlespawners(low, high, amount)
	minetest.add_particlespawner({
		amount = amount,
		time = 0.1,
		minpos = low,
		maxpos = high,
		minexptime = 0.5,
		maxexptime = 2,
		texture = "arcana_projectile_1.png",
		glow = 15,
	})
	minetest.add_particlespawner({
		amount = amount,
		time = 0.1,
		minpos = low,
		maxpos = high,
		minexptime = 0.5,
		maxexptime = 2,
		texture = "arcana_projectile_2.png",
		glow = 15,
	})
end

register({
	name = "arcana:cone",
	description = "Cone",
	texture = "arcana_cone.png",
	type = "shape",
	action = function(self, target, context)
		local entities =
			arcana.entities_in_cone(target.pos, target.dir, cone_width, cone_range)
		for _, object in ipairs(entities) do
			if object ~= target.ref then
				local pos = arcana.object_center(object)
				local dir = vector.normalize(vector.subtract(pos, target.pos))
				local target = arcana.Target.object(pos, dir, object)
				self:apply_children(target, context)
			end
		end

		-- Special effects
		local midpoint =
			vector.add(vector.multiply(target.dir, 0.5 * cone_range), target.pos)
		local endpoint =
			vector.add(vector.multiply(target.dir, cone_range), target.pos)
		local small_low, small_high = vector.sort(target.pos, midpoint)
		local large_low, large_high = vector.sort(midpoint, endpoint)

		make_cone_particlespawners(small_low, small_high, 10)
		make_cone_particlespawners(large_low, large_high, 30)
	end,
	cost = multiplier_cost(2),
})
	
local projectile_speed = 8
local projectile_life = 10
local projectile_radius = 0.2
local ape = "arcana_projectile_entity.png"

minetest.register_entity("arcana:projectile", {
	physical = false,
	collide_with_objects = false,
	collisionbox = { 0, 0, 0, 0, 0, 0 },
	visual = "cube",
	visual_size = { x = 2 * projectile_radius, y = 2 * projectile_radius },
	textures = { ape, ape, ape, ape, ape, ape },
	on_step = function(self, dtime)
		if not self.spell then
			self.object:remove()
			return
		end

		local pos = self.object:get_pos()
		local vel = self.object:get_velocity()
		local target = arcana.target_at_point(pos, vel, projectile_radius, self.exclude)

		if target then
			self.spell:apply_children(target, self.context)
			self.spell = nil
		end
	end,
})

local function spawn_projectile(point, dir, spell, context, exclude)
	local obj = minetest.add_entity(point, "arcana:projectile")
	local ent = obj:get_luaentity()
	if not ent then return end

	obj:set_velocity(vector.multiply(vector.normalize(dir), projectile_speed))
	ent.spell = spell
	ent.life = projectile_life
	ent.context = context
	ent.exclude = exclude

	obj:set_armor_groups({ immortal = 1 })

	local p_r = projectile_radius
	minetest.add_particlespawner({
		amount = 400 * p_r,
		time = 0,
		minpos = { x = -p_r, y = -p_r, z = -p_r },
		maxpos = { x = p_r, y = p_r, z = p_r },
		minexptime = 0.2,
		maxexptime = 0.5,
		attached = obj,
		texture = "arcana_projectile_1.png",
		glow = 15,
	})
	minetest.add_particlespawner({
		amount = 400 * p_r,
		time = 0,
		minpos = { x = -p_r, y = -p_r, z = -p_r },
		maxpos = { x = p_r, y = p_r, z = p_r },
		minexptime = 0.2,
		maxexptime = 0.5,
		attached = obj,
		texture = "arcana_projectile_2.png",
		glow = 15,
	})
end

register({
	name = "arcana:projectile",
	description = "Projectile",
	texture = "arcana_projectile.png",
	type = "shape",
	action = function(self, target, context)
		spawn_projectile(target.pos, target.dir, self, context, target.ref)
	end,
	cost = multiplier_cost(2),
})
	
local heal_amount = 5
register({
	name = "arcana:heal",
	description = "Heal (2.5)",
	texture = "arcana_heal.png",
	type = "effect",
	action = function(self, target)
		if target.type == "object" then
			local old_hp = target.ref:get_hp()
			-- Don't heal dead people
			if old_hp > 0 then
				target.ref:set_hp(old_hp + heal_amount)
			end
		end
	end,
	cost = heal_amount * 3,
})

local harm_amount = 5
register({
	name = "arcana:punch",
	description = "Damage (2.5)",
	texture = "arcana_punch.png",
	type = "effect",
	action = function(self, target)
		if target.type == "object" then
			target.ref:punch(target.ref, 1, {
				full_punch_interval = 1,
				damage_groups = { fleshy = harm_amount },
				}, nil)
		end
	end,
	cost = harm_amount,
})

register({
	name = "arcana:mini_explosion",
	description = "Mini Explosion",
	texture = "arcana_mini_explosion.png",
	type = "effect",
	action = function(self, target)
		tnt.boom(target.pos, {
			radius = 2,
			damage_radius = 4,
		})
	end,
	cost = 20,
})

local function find_close_node(pos, n)
	n = n or 2
	for i = 1, n do
		local candidate = minetest.find_node_near(pos, n, "air")
		if candidate then
			return candidate
		end
	end

	return nil
end

local function teleport_object(object, pos)
	local node = minetest.get_node(pos)
	local teleport_pos = pos
	if minetest.registered_nodes[node.name].walkable then
		local close_node = find_close_node(pos, 3)
		if close_node then
			teleport_pos = close_node
		end
	end
	object:set_pos(teleport_pos)

end

register({
	name = "arcana:teleport_self",
	description = "Teleport Self to Target",
	texture = "arcana_teleport_self.png",
	type = "effect",
	action = function(self, target, context)
		local pname = context.caster.name
		local player = pname and minetest.get_player_by_name(pname)
		
		if not player then return end -- Only teleport online players
		
		teleport_object(player, target.pos)
	end,
	cost = 25,
})

register({
	name = "arcana:teleport_target",
	description = "Teleport Target to Self",
	texture = "arcana_teleport_target.png",
	type = "effect",
	action = function(self, target, context)
		local pname = context.caster.name
		local player = pname and minetest.get_player_by_name(pname)
		
		if not player then return end -- Only teleport to online players
		
		if target.type == "object" then
			teleport_object(target.ref, player:get_pos())
		end
	end,
	cost = 25,
})
