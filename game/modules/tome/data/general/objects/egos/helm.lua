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
local Stats = require "engine.interface.ActorStats"
local DamageType = require "engine.DamageType"

--load("/data/general/objects/egos/charged-attack.lua")
--load("/data/general/objects/egos/charged-defensive.lua")
--load("/data/general/objects/egos/charged-utility.lua")


newEntity{
	power_source = {technique=true},
	name = " of strength (#STATBONUS#)", suffix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 6,
	cost = 4,
	wielder = {
		inc_stats = { [Stats.STAT_STR] = resolvers.mbonus_material(8, 2, function(e, v) return v * 3 end) },
	},
}
newEntity{
	power_source = {technique=true},
	name = " of constitution (#STATBONUS#)", suffix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 6,
	cost = 4,
	wielder = {
		inc_stats = { [Stats.STAT_CON] = resolvers.mbonus_material(8, 2, function(e, v) return v * 3 end) },
	},
}
newEntity{
	power_source = {technique=true},
	name = " of dexterity (#STATBONUS#)", suffix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 6,
	cost = 4,
	wielder = {
		inc_stats = { [Stats.STAT_DEX] = resolvers.mbonus_material(8, 2, function(e, v) return v * 3 end) },
	},
}
newEntity{
	power_source = {arcane=true},
	name = " of greater telepathy", suffix=true,
	level_range = {40, 50},
	greater_ego = true,
	rarity = 50,
	cost = 25,
	wielder = {
		life_regen = -3,
		esp = {all=1},
	},
}
newEntity{
	power_source = {arcane=true},
	name = " of telepathic range", suffix=true,
	level_range = {40, 50},
	rarity = 15,
	cost = 15,
	wielder = {
		esp = {range=10},
	},
}
newEntity{
	power_source = {arcane=true},
	name = "shaloran ", prefix=true, instant_resolve=true,
	level_range = {25, 50},
	greater_ego = true,
	rarity = 10,
	cost = 10,
	wielder = {
		inc_stats = { [Stats.STAT_WIL] = resolvers.mbonus_material(2, 1, function(e, v) return v * 3 end) },
		disease_immune = resolvers.mbonus_material(15, 10, function(e, v) return v * 0.15, v/100 end),
		stun_immune = resolvers.mbonus_material(2, 2, function(e, v) v=v/10 return v * 8, v end),
	},
}
newEntity{
	power_source = {nature=true},
	name = "prismatic ", prefix=true, instant_resolve=true,
	level_range = {10, 50},
	rarity = 10,
	cost = 7,
	wielder = {
		resists={
			[DamageType.LIGHT] = resolvers.mbonus_material(10, 10, function(e, v) return v * 0.15 end),
			[DamageType.DARKNESS] = resolvers.mbonus_material(10, 10, function(e, v) return v * 0.15 end),
		},
	},
}

newEntity{
	power_source = {nature=true},
	name = " of precognition", suffix=true, instant_resolve=true,
	level_range = {30, 50},
	greater_ego = true,
	rarity = 18,
	cost = 25,
	wielder = {
		combat_atk = resolvers.mbonus_material(4, 2, function(e, v) return v * 0.3 end),
		combat_def = resolvers.mbonus_material(4, 2, function(e, v) return v * 0.3 end),
		inc_stats = { [Stats.STAT_CUN] = 4, },
	},
}

newEntity{
	power_source = {nature=true},
	name = " of the depths", suffix=true,
	level_range = {15, 50},
	rarity = 7,
	cost = 10,
	wielder = {
		can_breath = {water=1},
	},
}

newEntity{
	power_source = {technique=true},
	name = " of absorption", suffix=true, instant_resolve=true,
	level_range = {20, 50},
	rarity = 10,
	cost = 20,
	wielder = {
		stamina_regen_on_hit = resolvers.mbonus_material(23, 7, function(e, v) v=v/10 return v * 3, v end),
		equilibrium_regen_on_hit = resolvers.mbonus_material(23, 7, function(e, v) v=v/10 return v * 3, v end),
		mana_regen_on_hit = resolvers.mbonus_material(23, 7, function(e, v) v=v/10 return v * 3, v end),
	},
}

newEntity{
	power_source = {technique=true},
	name = "miner's ", prefix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 6,
	cost = 5,
	wielder = {
		infravision = resolvers.mbonus_material(2, 2, function(e, v) return v * 1.4 end),
	},
}

newEntity{
	power_source = {technique=true},
	name = "insulating ", prefix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 6,
	cost = 5,
	wielder = {
		resists={
			[DamageType.FIRE] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
			[DamageType.COLD] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
		},
	},
}

newEntity{
	power_source = {technique=true},
	name = "grounding ", prefix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 6,
	cost = 5,
	wielder = {
		resists={
			[DamageType.LIGHTNING] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
		},
		stun_immune = resolvers.mbonus_material(20, 10, function(e, v) v=v/100 return v * 80, v end),
	},
}

newEntity{
	power_source = {technique=true},
	name = "stabilizing ", prefix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 6,
	cost = 5,
	wielder = {
		stun_immune = resolvers.mbonus_material(20, 10, function(e, v) v=v/100 return v * 80, v end),
		knockback_immune = resolvers.mbonus_material(20, 10, function(e, v) v=v/100 return v * 80, v end),
	},
}

newEntity{
	power_source = {nature=true},
	name = "cleansing ", prefix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 9,
	cost = 9,
	wielder = {
		resists={
			[DamageType.ACID] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
		},
		poison_immune = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15, v/100 end),
		disease_immune = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15, v/100 end),
	},
}


newEntity{
	power_source = {arcane=true},
	name = " of knowledge", suffix=true, instant_resolve=true,
	level_range = {15, 50},
	greater_ego = true,
	rarity = 15,
	cost = 20,
	wielder = {
		combat_spellcrit = resolvers.mbonus_material(3, 3, function(e, v) return v * 0.4 end),
		inc_stats = {
			[Stats.STAT_MAG] = resolvers.mbonus_material(3, 2, function(e, v) return v * 3 end),
			[Stats.STAT_WIL] = resolvers.mbonus_material(3, 2, function(e, v) return v * 3 end),
			},
	},
}


newEntity{
	power_source = {technique=true},
	name = " of might", suffix=true, instant_resolve=true,
	level_range = {15, 50},
	greater_ego = true,
	rarity = 15,
	cost = 20,
	wielder = {
		combat_physcrit = resolvers.mbonus_material(3, 3, function(e, v) return v * 1.4 end),
		inc_stats = {
			[Stats.STAT_STR] = resolvers.mbonus_material(3, 2, function(e, v) return v * 3 end),
			[Stats.STAT_CON] = resolvers.mbonus_material(3, 2, function(e, v) return v * 3 end),
			},
	},
}

newEntity{
	power_source = {technique=true},
	name = " of trickery", suffix=true, instant_resolve=true,
	level_range = {15, 50},
	greater_ego = true,
	rarity = 13,
	cost = 20,
	wielder = {
		combat_apr = resolvers.mbonus_material(4, 4, function(e, v) return v * 0.3 end),
		inc_stats = {
			[Stats.STAT_DEX] = resolvers.mbonus_material(3, 2, function(e, v) return v * 3 end),
			[Stats.STAT_CUN] = resolvers.mbonus_material(3, 2, function(e, v) return v * 3 end),
			},
	},
}

newEntity{
	power_source = {nature=true},
	name = "warlord's ", prefix=true, instant_resolve=true,
	level_range = {40, 50},
	greater_ego = true,
	rarity = 17,
	cost = 50,
	wielder = {
		combat_dam = resolvers.mbonus_material(6, 6, function(e, v) return v * 3 end),
		pin_immune = resolvers.mbonus_material(3, 3, function(e, v) v=v/10 return v * 8, v end),
		inc_stats = {
			[Stats.STAT_WIL] = resolvers.mbonus_material(4, 3, function(e, v) return v * 3 end),
			},
	},
}

newEntity{
	power_source = {technique=true},
	name = "defender's ", prefix=true, instant_resolve=true,
	level_range = {40, 50},
	greater_ego = true,
	rarity = 17,
	cost = 50,
	wielder = {
		combat_armor = resolvers.mbonus_material(5, 4, function(e, v) return v * 1 end),
		combat_def = resolvers.mbonus_material(4, 4, function(e, v) return v * 1 end),
		combat_physresist = resolvers.mbonus_material(15, 5, function(e, v) return v * 0.15 end),
	},
}

newEntity{
	power_source = {technique=true},
	name = "dragonslayer's ", prefix=true, instant_resolve=true,
	level_range = {40, 50},
	greater_ego = true,
	rarity = 17,
	cost = 50,
	wielder = {
		resists={
			[DamageType.ACID] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
			[DamageType.LIGHTNING] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
			[DamageType.FIRE] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
			[DamageType.COLD] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
		},
	},
}

