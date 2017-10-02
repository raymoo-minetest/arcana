--- Spell components
-- @module arcana.Component
-- @author raymoo

local Component = {}
arcana.Component = Component

--- Externals.
-- @section externals

--- Spell targets (spell/target.lua)
-- @table Target

--- Spell component definitions.
-- @section definitions

--- A definition specifying a spell component
-- @string name A unique ID, prefixed with a mod name as in "arcana:punch"
-- @string description The name that is displayed to the user
-- @string texture A texture displayed to the user
-- @string type One of "effect", "payload", or "shape".
-- Effects cannot chain any spell components after it, payloads can only chain
-- effects, and shapes can chain any kind of component, including other shapes.
-- @tparam ActionCallback action How to apply a component
-- @tparam CostCalculator|number cost The cost of a component
-- @table ComponentDefinition

--- How to apply a component to a target
-- @tparam Component self
-- @tparam Target target
-- @tparam SpellContext context
-- @function ActionCallback

--- How to calculate the cost of using a component
-- @tparam Component self
-- @treturn number
-- @function CostCalculator

--- Spell context
-- @section context

--- Useful context for spell components
-- @tparam Caster caster
-- @table SpellContext

--- Table to specify what cast a spell
-- @tparam string type One of "player", "node", or "none"
-- @tparam ?string name For players, is the player name.
-- @tparam ?string key For nodes, is a random key that should also be stored in
-- the node meta in the "arcana_key" field.
-- @tparam ?vector ?pos When the caster is a node, this is its position.
-- @table Caster

--- Construct a nonspecific caster
-- @treturn Caster
function arcana.Component.null_caster()
	return {
		type = "none",
	}
end

--- Construct a player caster
-- @tparam ObjectRef player
-- @treturn Caster
function arcana.Component.player_caster(player)
	local p_type = type(player)
	local pname
	if p_type == "userdata" and player:is_player() then
		pname = player:get_player_name()
	elseif p_type == "string" then
		pname = player
	else
		error("Expected a player name or ObjectRef")
	end
	return {
		type = "player",
		name = pname,
	}
end

Component.registered = {}

--- Registration.
-- @section registration

--- Register a component
-- @tparam ComponentDefinition def
function arcana.Component.register(def)
	local name = def.name
	if type(name) ~= "string" then
		error("Component definitions must have a name.")
	end
	Component.registered[name] = def

	minetest.register_craftitem(def.name, {
		description = def.description,
		inventory_image = def.texture or "arcana_component.png",
		stack_max = 1,
	})
end

--- Spell components
-- @type Component

local comp_meta = {}
comp_meta.__index = comp_meta

--- Check if a component exists
-- @string name
-- @treturn bool
function arcana.Component.exists(name)
	return Component.registered[name] ~= nil
end

--- Construct a component
-- @string name The name of the registered component
-- @treturn Component
function arcana.Component.new(name)
	if not Component.registered[name] then
		error("Non existent component " .. name)
	end
	local comp = {
		name = name,
		child_components = {},
	}
	setmetatable(comp, comp_meta)
	return comp
end

function comp_meta:def()
	return Component.registered[self.name]
end

--- Apply a component
-- @tparam Target target
-- @tparam SpellContext context
-- @function Component:apply
function comp_meta:apply(target, context)
	assert(target)
	self:def().action(self, target, context, {})
end

--- Apply the children of a component
-- @tparam Target target
-- @tparam SpellContext context
-- @function Component:apply_children
function comp_meta:apply_children(target, context)
	Component.apply_list(self.child_components, target, context)
end

--- Apply a list of components
-- @table components
-- @tparam Target target
-- @tparam SpellContext context
function arcana.Component.apply_list(components, target, context)
	for i, comp in ipairs(components) do
		comp:apply(target, context)
	end
end

local function valid_chain(parent, child)
	if parent == "effect" then
		return false
	elseif parent == "payload" then
		return child == "effect"
	elseif parent == "shape" then
		return true
	else
		error("Invalid component type: " .. parent)
	end
end

--- Chain a child component
-- @tparam component
-- @function Component:add_child
function comp_meta:add_child(component)
	assert(getmetatable(component) == comp_meta)
	assert(valid_chain(self:def().type, component:def().type))
	assert(self ~= component) -- Make sure no loops
	table.insert(self.child_components, component)
end

--- Gets a list of children
-- @treturn table
-- @function Component:children
function comp_meta:children()
	return self.child_components
end

--- Get the cost of a component
-- @treturn number
-- @function Component:cost
function comp_meta:cost()
	local cost = self:def().cost
	local cost_type = type(cost)
	if cost_type == "number" then
		return cost
	elseif cost_type == "function" then
		return cost(self)
	else
		error("Invalid cost")
	end
end

--- Get the sum of the child costs
-- @treturn number
-- @function Component:children_cost
function comp_meta:children_cost()
	local total = 0
	for _, child in ipairs(self:children()) do
		total = total + child:cost()
	end
	return total
end

--- Serialize a component
-- @treturn string
-- @function Component:serialize
function comp_meta:serialize()
	local child_strs = {}
	for i, child in ipairs(self.child_components) do
		child_strs[i] = child:serialize()
	end
	return minetest.serialize({
		name = self.name,
		child_strs = child_strs,
	})
end

--- Deserialize a component
-- @string str
-- @treturn ?Component nil if invalid
function arcana.Component.deserialize(str)
	local tab = minetest.deserialize(str)
	if not tab.name or not Component.registered[tab.name] then
		return nil
	end
	local child_strs = tab.child_strs or {}
	local comp = Component.new(tab.name)
	for i, child_str in ipairs(child_strs) do
		local child = arcana.Component.deserialize(child_str)
		if child then
			comp:add_child(child)
		end
	end
	return comp
end
