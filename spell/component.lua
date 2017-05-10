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
-- @tparam SpellContext context
-- @function ActionCallback

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
	if p_type == "userdata" and p_type:is_player() then
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
-- @tparam SpellContext context
-- @function Component:apply
function comp_meta:apply(target, context)
	assert(target)
	self:def().action(self, target, context, {})
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

-- Internal component for when a spell is cast
arcana.Component.register({
	name = "initial", -- Exception for prefix rule
	description = "Spell Core",
	texture = "default_stone.png",
	type = "shape",
	action = function(self, target, context)
		for i, child in ipairs(children) do
			child:apply(target, context)
		end
	end,
})
