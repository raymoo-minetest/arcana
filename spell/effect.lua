--- Spell effects
-- @module arcana.Effect
-- @author raymoo

local Effect = {}
arcana.Effect = Effect

--- Externals.
-- @section externals

--- Spell targets (spell/target.lua)
-- @table Target

--- Spell effect definitions.
-- @section definitions

--- A definition specifying a spell effect
-- @string name A unique ID, prefixed with a mod name as in "arcana:punch"
-- @string description The name that is displayed to the user
-- @string texture A texture displayed to the user
-- @tparam ActionCallback action How to apply an effect
-- @table EffectDefinition

--- How to apply an effect to a target
-- @tparam Effect self
-- @tparam Target target
-- @function ActionCallback

Effect.effects = {}

--- Registration.
-- @section registration

--- Register an effect
-- @tparam EffectDefinition def
function arcana.Effect.register(def)
	local name = def.name
	if type(name) ~= "string" then
		error("Effect definitions must have a name.")
	end
	Effect.effects[name] = def
end

--- Spell effects
-- @string test
-- @type Effect

local effect_meta = {}
effect_meta.__index = effect_meta

--- Construct an effect
-- @string name The name of the registered effect definition
-- @treturn Effect
function arcana.Effect.new(name)
	if not Effect.effects[name] then
		error("Non existent effect " .. name)
	end
	local effect = { name = name }
	setmetatable(effect, effect_meta)
	return effect
end

function effect_meta:def()
	return Effect.effects[self.name]
end

--- Apply an effect
-- @tparam Target target
-- @function Effect:apply
function effect_meta:apply(target)
	assert(target)
	self:def().action(self, target)
end

--- Serialize an effect
-- @treturn string
-- @function Effect:serialize
function effect_meta:serialize()
	return minetest.serialize({ name = self.name })
end

--- Deserialize an effect
-- @string str
-- @treturn ?Effect nil if invalid
function arcana.Effect.deserialize(str)
	local tab = minetest.deserialize(str)
	if not tab.name or not Effect.effects[tab.name] then
		return nil
	end
	return Effect.new(tab.name)
end
