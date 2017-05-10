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
-- @table ComponentDefinition

--- How to apply a component to a target
-- @tparam Component self
-- @tparam Target target
-- @function ActionCallback

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
end

--- Spell components
-- @type Component

local comp_meta = {}
comp_meta.__index = comp_meta

--- Construct a component
-- @string name The name of the registered component
-- @treturn Component
function arcana.Component.new(name)
	if not Component.registered[name] then
		error("Non existent component " .. name)
	end
	local comp = { name = name }
	setmetatable(comp, comp_meta)
	return comp
end

function comp_meta:def()
	return Component.registered[self.name]
end

--- Apply a component
-- @tparam Target target
-- @function Component:apply
function comp_meta:apply(target)
	assert(target)
	self:def().action(self, target)
end

--- Serialize a component
-- @treturn string
-- @function Component:serialize
function comp_meta:serialize()
	return minetest.serialize({ name = self.name })
end

--- Deserialize a component
-- @string str
-- @treturn ?Component nil if invalid
function arcana.Component.deserialize(str)
	local tab = minetest.deserialize(str)
	if not tab.name or not Component.registered[tab.name] then
		return nil
	end
	return Component.new(tab.name)
end
