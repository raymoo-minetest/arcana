
local casting_states = {}

hb.register_hudbar("arcana:charge", 0x000000, "Spell Charge", {
	bar = "arcana_charge_bar.png",
	icon = "arcana_charge_icon.png",
	-- bgicon = nil,
}, 0, 100, true)

minetest.register_on_joinplayer(function(player)
	casting_states[player:get_player_name()] = {}
	hb.init_hudbar(player, "arcana:charge", 0, 100, true)
end)

minetest.register_on_leaveplayer(function(player)
	casting_states[player:get_player_name()] = nil
end)

local function display_state(player, state)
	hb.unhide_hudbar(player, "arcana:charge")
	hb.change_hudbar(player, "arcana:charge", state.charge, state.cost)
end

local function hide_state(player, state)
	if not state.spell then return end
	
	hb.hide_hudbar(player, "arcana:charge")
	minetest.delete_particlespawner(state.spawner)
end

function arcana.begin_casting(player, spell, cost, item_id)
	local radius = math.max(math.sqrt(cost / 10), 0.2)
	local effect_spawner = minetest.add_particlespawner({
		amount = cost * 5,
		time = 0,
		minpos = {
			x = -radius,
			y = -1,
			z = -radius,
		},
		maxpos = {
			x = radius,
			y = -1,
			z = radius,
		},
		minvel = { x = 0, y = 0.1, z = 0 },
		maxvel = { x = 0, y = 2, z = 0 },
		attached = player,
		texture = "arcana_projectile_1.png",
		glow = 15,
	})

	local pname = player:get_player_name()
	local new_state = {
		spell = spell,
		cost = 50 + cost,
		item_id = item_id,
		charge = 0,
		spawner = effect_spawner,
	}

	hide_state(player, casting_states[pname])
	casting_states[pname] = new_state
	display_state(player, new_state)
end

local function player_item_id(player)
	return player:get_wielded_item():get_meta():get_string("arcana:id")
end

local function update_state(pname, state, dtime)
	local player = minetest.get_player_by_name(pname)

	-- Don't process inactive states.
	if not state.spell then
		return {}
	end

	-- If a player has switched or lost their casting item then reset.
	if state.item_id and player_item_id(player) ~= state.item_id then
		hide_state(player, state)
		return {}
	end

	-- If a player is not holding down LMB then reset.
	if not player:get_player_control().LMB then
		hide_state(player, state)
		return {}
	end

	state.charge = state.charge + 100 * dtime

	-- Cast the spell if it has been charged long enough.
	if state.charge > state.cost then
		state.spell:apply(arcana.Target.casted(player), {
			caster = arcana.Component.player_caster(player)
		})
		hide_state(player, state)
		return {}
	end

	-- Else just give the updated table
	display_state(player, state)
	return state
end

minetest.register_globalstep(function(dtime)
	for pname, state in pairs(casting_states) do
		casting_states[pname] = update_state(pname, state, dtime)
	end
end)
