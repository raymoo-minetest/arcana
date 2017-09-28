
local register = arcana.Component.register

-- Passes the target through
register({
	name = "arcana:initial",
	description = "Pass-through",
	type = "shape",
	action = function(self, target, context)
		self:apply_children(target, context)
	end,
})

-- Applies something in look direction
local telekinesis_width = 10
local telekinesis_range = 10
register({
	name = "arcana:telekinesis",
	description = "Telekinesis",
	texture = "arcana_telekinesis.png",
	type = "shape",
	action = function(self, target, context)
		local cone_pos = target.pos
		local cone_dir = target.dir
		local target = arcana.target_in_cone(cone_pos, cone_dir,
			telekinesis_width, telekinesis_range, target.ref)

		if target then
			self:apply_children(target, context)
		end
	end,
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
	action = function(self, target, context)
		local cone_pos = target.pos
		local cone_dir = target.dir
		local target = arcana.target_in_cone(cone_pos, cone_dir,
			touch_width, touch_range, target.ref)

		if target then
			self:apply_children(target, context)
		end
	end,
})

local projectile_speed = 8
local projectile_life = 10

minetest.register_entity("arcana:projectile", {
	physical = false,
	collide_with_objects = false,
	collisionbox = { 0, 0, 0, 0, 0, 0 },
	visual = "cube",
	visual_size = { x = 0, y = 0 },
	on_step = function(self, dtime)
		if not self.spell then
			self.object:remove()
			return
		end

		local pos = self.object:get_pos()
		local vel = self.object:get_velocity()
		local target = arcana.target_at_point(pos, vel, self.exclude)

		if target then
			self.spell:apply_children(target)
			self.spell = nil
		end
	end,
})

local function spawn_projectile(point, dir, spell, exclude)
	local obj = minetest.add_entity(point, "arcana:projectile")
	local ent = obj:get_luaentity()
	if not ent then return end

	obj:set_velocity(vector.multiply(vector.normalize(dir), projectile_speed))
	ent.spell = spell
	ent.life = projectile_life
	ent.exclude = exclude

	obj:set_armor_groups({ immortal = 1 })
	
	minetest.add_particlespawner({
		amount = 20,
		time = 0,
		minvel = { x = -2, y = -2, z = -2 },
		maxvel = { x = 2, y = 2, z = 2 },
		attached = obj,
		texture = "arcana_projectile_1.png",
		glow = 15,
	})
	minetest.add_particlespawner({
		amount = 20,
		time = 0,
		minvel = { x = -2, y = -2, z = -2 },
		maxvel = { x = 2, y = 2, z = 2 },
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
		spawn_projectile(target.pos, target.dir, self, target.ref)
	end,
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
})
