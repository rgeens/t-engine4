-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

load("/data/general/npcs/aquatic_critter.lua", rarity(0))
load("/data/general/npcs/aquatic_demon.lua", rarity(0))

local Talents = require("engine.interface.ActorTalents")

-- The boss of trollshaws, no "rarity" field means it will not be randomly generated
newEntity{ define_as = "UKLLMSWWIK",
	type = "dragon", subtype = "water", unique = true,
	name = "Ukllmswwik the Wise",
	faction="water-lair",
	display = "D", color=colors.VIOLET,
	desc = [[It looks like a cross between a shark and a dragon, only nastier.]],
	energy = {mod = 1.4},
	level_range = {30, 50}, exp_worth = 4,
	max_life = 250, life_rating = 27, fixed_rating = true,
	max_stamina = 85,
	stats = { str=25, dex=10, cun=48, wil=50, mag=50, con=20 },
	rank = 4,
	size_category = 4,
	can_breath={water=1},
	infravision = 20,
	move_others=true,

	instakill_immune = 1,
	teleport_immune = 1,
	confusion_immune= 1,
	combat_spellresist = 25,
	combat_mentalresist = 25,
	combat_physresist = 30,

	resists = { [DamageType.COLD] = 60, [DamageType.LIGHTNING] = 20, },

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1 },
	resolvers.drops{chance=100, nb=1, {defined="TRIDENT_TIDES", random_art_replace={chance=50, rarity=250, level_range={30, 40}}, autoreq=true} },
	resolvers.drops{chance=100, nb=5, {ego_chance=100} },
	resolvers.drops{chance=100, nb=10, {type="money"} },

	resolvers.talents{
		[Talents.T_WEAPON_COMBAT]=5,
		[Talents.T_KNOCKBACK]=3,

		[Talents.T_ICE_STORM]=4,
		[Talents.T_FREEZE]=3,

		[Talents.T_ICE_CLAW]=5,
		[Talents.T_ICY_SKIN]=5,
		[Talents.T_ICE_BREATH]=5,
		[Talents.T_LIGHTNING_BREATH]=5,
		[Talents.T_POISON_BREATH]=5,
	},
	resolvers.sustains_at_birth(),

	autolevel = "warrior",
	ai = "dumb_talented_simple", ai_state = { talent_in=2, ai_move="move_astar", },

	on_die = function(self, who)
		game.player:resolveSource():setQuestStatus("maglor", engine.Quest.COMPLETED, "kill-drake")
	end,

	can_talk = "ukllmswwik",
}
