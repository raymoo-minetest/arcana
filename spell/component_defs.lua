
-- Passes the target through
arcana.Component.register({
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
arcana.Component.register({
	name = "arcana:telekinesis",
	description = "Telekinesis",
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
arcana.Component.register({
	name = "arcana:touch",
	description = "Touch",
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

arcana.Component.register({
	name = "arcana:mini_explosion",
	description = "Mini Explosion",
	type = "effect",
	action = function(self, target)
		tnt.boom(target.pos, {
			radius = 2,
			damage_radius = 4,
		})
	end,
})
