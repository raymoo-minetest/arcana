
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
