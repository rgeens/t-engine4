-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
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

local Talents = require("engine.interface.ActorTalents")

newEntity{
	define_as = "BASE_NPC_BONE_GIANT",
	type = "undead", subtype = "giant",
	blood_color = colors.GREY,
	display = "K", color=colors.WHITE,

	combat = { dam=resolvers.levelup(resolvers.mbonus(45, 20), 1, 1), atk=15, apr=10, dammod={str=0.8} },

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1 },

	infravision = 20,
	life_rating = 12,
	max_stamina = 90,
	rank = 2,
	size_category = 4,

	autolevel = "warrior",
	ai = "dumb_talented_simple", ai_state = { ai_move="move_dmap", talent_in=2, },
	energy = { mod=1 },
	stats = { str=20, dex=52, mag=16, con=16 },

	resists = { [DamageType.PHYSICAL] = 20, [DamageType.BLIGHT] = 20, [DamageType.COLD] = 50, },

	open_door = 1,
	no_breath = 1,
	confusion_immune = 1,
	poison_immune = 1,
	blind_immune = 1,
	fear_immune = 1,
	stun_immune = 1,
	see_invisible = resolvers.mbonus(15, 5),
	undead = 1,
	on_die = function(self, who)
		local part = "BONE_GOLEM_DUST"
		if game.player:hasQuest("brotherhood-of-alchemists") then 
			game.player:hasQuest("brotherhood-of-alchemists"):need_part(who, part, self)
		end
	end,
}

newEntity{ base = "BASE_NPC_BONE_GIANT",
	name = "bone giant", color=colors.WHITE,
	desc = [[A towering creature, made from the bones of hundreds of dead bodies. It is covered by an unholy aura.]],
	level_range = {25, nil}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(100,120),
	combat_armor = 20, combat_def = 0,
	on_melee_hit = {[DamageType.BLIGHT]=resolvers.mbonus(15, 5)},
	melee_project = {[DamageType.BLIGHT]=resolvers.mbonus(15, 5)},
	resolvers.talents{ [Talents.T_BONE_ARMOUR]={base=3, every=10, max=5}, [Talents.T_STUN]={base=3, every=10, max=5}, },
}

newEntity{ base = "BASE_NPC_BONE_GIANT",
	name = "eternal bone giant", color=colors.GREY,
	desc = [[A towering creature, made from the bones of hundreds of dead bodies. It is covered by an unholy aura.]],
	level_range = {33, nil}, exp_worth = 1,
	rarity = 3,
	max_life = resolvers.rngavg(100,120),
	combat_armor = 40, combat_def = 20,
	on_melee_hit = {[DamageType.BLIGHT]=resolvers.mbonus(15, 5)},
	melee_project = {[DamageType.BLIGHT]=resolvers.mbonus(15, 5)},
	autolevel = "warriormage",
	resists = {all = 50},
	resolvers.talents{ [Talents.T_BONE_ARMOUR]={base=5, every=10, max=7}, [Talents.T_STUN]={base=3, every=10, max=5}, [Talents.T_SKELETON_REASSEMBLE]=5, },
}

newEntity{ base = "BASE_NPC_BONE_GIANT",
	name = "heavy bone giant", color=colors.LIGHT_UMBER,
	desc = [[A towering creature, made from the bones of hundreds of dead bodies. It is covered by an unholy aura.]],
	level_range = {35, nil}, exp_worth = 1,
	rarity = 3,
	max_life = resolvers.rngavg(100,120),
	combat_armor = 20, combat_def = 0,
	on_melee_hit = {[DamageType.BLIGHT]=resolvers.mbonus(15, 5)},
	melee_project = {[DamageType.BLIGHT]=resolvers.mbonus(15, 5)},
	resolvers.talents{ [Talents.T_BONE_ARMOUR]={base=3, every=10, max=5}, [Talents.T_THROW_BONES]={base=4, every=10, max=7}, [Talents.T_STUN]={base=3, every=10, max=5}, },
}
