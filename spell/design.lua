
local Target = arcana.Target
local Component = arcana.Component

local components_inv_callbacks = {}
function components_inv_callbacks.allow_move()
	return 0
end

function components_inv_callbacks.allow_put()
	return 0
end

function components_inv_callbacks.allow_take()
	return -1
end

local components_inv =
	minetest.create_detached_inventory("arcana:components",
		components_inv_callbacks)

local design_formspec = "\
size[5,7]\
label[0,0;Design:]\
list[context;design;0,1;5,1]\
label[0,3;Available components:]\
list[detached:arcana:components;main;0,4;5,2]\
button[1.5,6;2,1;dispense;Dispense]\
"

local effect_level = 0
local payload_level = 1
local shape_level = 2

local function valid(level_parent, level_child)
	if not level_parent then
		return true
	end
	return level_parent > level_child
		or level_parent == shape_level and level_child == shape_level
end

local level_map = {
	effect = 0,
	payload = 1,
	shape = 2,
}

local function level(comp)
	return level_map[comp:def().type]
end

local function parse_recipe(inv, list)
	local cur_level = -1
	local cur_tail = {}

	local items = inv:get_list(list)
	for i=#items, 1, -1 do
		local name = items[i]:get_name()
		if Component.exists(name) then
			local component = Component.new(items[i]:get_name())
			if valid(level(component), cur_level) then
				for _, tail_component in ipairs(cur_tail) do
					component:add_child(tail_component)
				end
				cur_tail = { component }
				cur_level = level(component)
			else
				table.insert(cur_tail, component)
				cur_level = math.max(level(component), cur_level)
			end
		end
	end

	if #cur_tail == 0 then
		return nil, "No spell components"
	else
		local spell = Component.new("arcana:initial")
		for _, tail_component in ipairs(cur_tail) do
			spell:add_child(tail_component)
		end

		return spell
	end
end

minetest.register_craftitem("arcana:wand", {
        description = "Test wand",
        inventory_image = "default_stick.png",
	stack_max = 1,
        range = 0,
        on_use = function(itemstack, user, pointed_thing)
                if user and user:is_player() then
			local meta = itemstack:get_meta()
			local serialized = meta:get_string("spell")
			local spell = Component.deserialize(serialized)

			if spell then
				local target = Target.casted(user)
				spell:apply(target, {
					caster = Component.player_caster(user)
				})
			end
                end
        end,
})

minetest.register_node("arcana:design_table", {
		description = "Spell design table",
		groups = { choppy = 3 },
		tiles = {
			"arcana_design_table_top.png", 
			"default_wood.png",
			"arcana_design_table_side.png",
		},
		sounds = default.node_sound_wood_defaults(),
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", design_formspec)
			local inv = meta:get_inventory()
			inv:set_size("design", 5)
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			local inv = minetest.get_meta(pos):get_inventory()
			local spell, err = parse_recipe(inv, "design")
			if fields.dispense and spell and sender:is_player() then
				local item = ItemStack("arcana:wand")
				item:get_meta():set_string("spell", spell:serialize())
				sender:get_inventory():add_item("main", item)
			else
				print("Spell design failed: ", err)
			end
		end,
})

minetest.after(0, function()
	local components = {}
	for _, def in pairs(Component.registered) do
		table.insert(components, def.name)
	end
	components_inv:set_size("main", #components)
	for _, component in ipairs(components) do
		components_inv:add_item("main", component)
	end
end)
