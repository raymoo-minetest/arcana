--- Spells
-- @module arcana.Spell
-- @author raymoo

arcana.load("spell/target.lua")
arcana.load("spell/component.lua")
arcana.load("spell/player_casting.lua")
arcana.load("spell/design.lua")
arcana.load("spell/component_defs.lua")

local Component = arcana.Component

local Spell = {}
arcana.Spell = Spell

--- Externals.
-- @section externals

--- Spell targets (spell/target.lua)
-- @table Target

--- Spell components (spell/component.lua)
-- @table Component
