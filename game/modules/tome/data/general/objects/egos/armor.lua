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

local Talents = require("engine.interface.ActorTalents")
local Stats = require "engine.interface.ActorStats"

newEntity{
	power_source = {technique=true},
	name = " of fire resistance", suffix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 5,
	cost = 6,
	wielder = {
		resists={[DamageType.FIRE] = resolvers.mbonus_material(30, 10, function(e, v) return v * 0.15 end)},
	},
}
newEntity{
	power_source = {technique=true},
	name = " of cold resistance", suffix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 5,
	cost = 6,
	wielder = {
		resists={[DamageType.COLD] = resolvers.mbonus_material(30, 10, function(e, v) return v * 0.15 end)},
	},
}
newEntity{
	power_source = {technique=true},
	name = " of acid resistance", suffix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 5,
	cost = 6,
	wielder = {
		resists={[DamageType.ACID] = resolvers.mbonus_material(30, 10, function(e, v) return v * 0.15 end)},
	},
}
newEntity{
	power_source = {technique=true},
	name = " of lightning resistance", suffix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 5,
	cost = 6,
	wielder = {
		resists={[DamageType.LIGHTNING] = resolvers.mbonus_material(30, 10, function(e, v) return v * 0.15 end)},
	},
}
newEntity{
	power_source = {nature=true},
	name = " of nature resistance", suffix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 5,
	cost = 6,
	wielder = {
		resists={[DamageType.NATURE] = resolvers.mbonus_material(30, 10, function(e, v) return v * 0.15 end)},
	},
}

newEntity{
	power_source = {technique=true},
	name = " of stability", suffix=true, instant_resolve=true,
	level_range = {10, 50},
	rarity = 7,
	cost = 6,
	wielder = {
		stun_immune = resolvers.mbonus_material(40, 30, function(e, v) v=v/100 return v * 80, v end),
		knockback_immune = resolvers.mbonus_material(40, 30, function(e, v) v=v/100 return v * 80, v end),
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
	power_source = {technique=true},
	name = "spiked ", prefix=true, instant_resolve=true,
	level_range = {5, 50},
	rarity = 6,
	cost = 7,
	wielder = {
		on_melee_hit={[DamageType.PHYSICAL] = resolvers.mbonus_material(10, 10, function(e, v) return v * 0.6 end)},
	},
}

newEntity{
	power_source = {arcane=true},
	name = "searing ", prefix=true, instant_resolve=true,
	level_range = {10, 50},
	rarity = 10,
	cost = 7,
	wielder = {
		melee_project={
			[DamageType.FIRE] = resolvers.mbonus_material(8, 8, function(e, v) return v * 0.7 end),
			[DamageType.ACID] = resolvers.mbonus_material(8, 8, function(e, v) return v * 0.7 end),
		},
	},
}

newEntity{
	power_source = {nature=true},
	name = "rejuvenating ", prefix=true, instant_resolve=true,
	level_range = {15, 50},
	rarity = 10,
	cost = 15,
	wielder = {
		stamina_regen = resolvers.mbonus_material(50, 20, function(e, v) v=v/100 return v * 100, v end),
	},
}

newEntity{
	power_source = {nature=true},
	name = "radiant ", prefix=true, instant_resolve=true,
	level_range = {20, 50},
	greater_ego = true,
	rarity = 18,
	cost = 15,
	wielder = {
		melee_project={[DamageType.LIGHT] = resolvers.mbonus_material(10, 4, function(e, v) return v * 0.7 end),},
		resists={
			[DamageType.BLIGHT] = resolvers.mbonus_material(20, 10, function(e, v) return v * 0.15 end),
			[DamageType.DARKNESS] = resolvers.mbonus_material(20, 10, function(e, v) return v * 0.15 end),
		},
		inc_stats = {
			[Stats.STAT_WIL] = resolvers.mbonus_material(5, 1, function(e, v) return v * 3 end),
			[Stats.STAT_LCK] = resolvers.mbonus_material(10, 1, function(e, v) return v * 3 end),
		},
	},
}

newEntity{
	power_source = {technique=true},
	name = "insulating ", prefix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 9,
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
	rarity = 9,
	cost = 10,
	wielder = {
		resists={
			[DamageType.LIGHTNING] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
		},
		stun_immune = resolvers.mbonus_material(2, 2, function(e, v) v=v/10 return v * 8, v end),
	},
}

newEntity{
	power_source = {technique=true},
	name = "anchoring ", prefix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 9,
	cost = 10,
	wielder = {
		resists={
			[DamageType.TEMPORAL] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
		},
		teleport_immune = resolvers.mbonus_material(2, 2, function(e, v) v=v/10 return v * 8, v end),
	},
}

newEntity{
	power_source = {nature=true},
	name = "cleansing ", prefix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 9,
	cost = 5,
	wielder = {
		resists={
			[DamageType.ACID] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
			[DamageType.POISON] = resolvers.mbonus_material(10, 5, function(e, v) return v * 0.15 end),
		},
	},
}

newEntity{
	power_source = {technique=true},
	name = "fortifying ", prefix=true, instant_resolve=true,
	level_range = {20, 50},
	greater_ego = true,
	rarity = 18,
	cost = 35,
	wielder = {
		inc_stats = {
			[Stats.STAT_CON] = resolvers.mbonus_material(5, 2, function(e, v) return v * 3 end),
			[Stats.STAT_STR] = resolvers.mbonus_material(5, 2, function(e, v) return v * 3 end),
		},
		max_life=resolvers.mbonus_material(70, 30, function(e, v) return v * 0.1 end),
	},
}


newEntity{
	power_source = {technique=true},
	name = "hardened ", prefix=true, instant_resolve=true,
	level_range = {40, 50},
	greater_ego = true,
	rarity = 29,
	cost = 47,
	wielder = {
		resists={
			[DamageType.ACID] = resolvers.mbonus_material(8, 5, function(e, v) return v * 0.15 end),
			[DamageType.LIGHTNING] = resolvers.mbonus_material(8, 5, function(e, v) return v * 0.15 end),
			[DamageType.FIRE] = resolvers.mbonus_material(8, 5, function(e, v) return v * 0.15 end),
			[DamageType.COLD] = resolvers.mbonus_material(8, 5, function(e, v) return v * 0.15 end),
			[DamageType.PHYSICAL] = resolvers.mbonus_material(8, 5, function(e, v) return v * 0.15 end),
		},
		combat_armor = resolvers.mbonus_material(5, 5, function(e, v) return v * 1 end),
	},
}



newEntity{
	power_source = {nature=true},
	name = " of resilience", suffix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 9,
	cost = 10,
	wielder = {
		max_life = resolvers.mbonus_material(40, 40, function(e, v) return v * 0.1 end),
	},
}



newEntity{
	power_source = {arcane=true},
	name = " of the sky", suffix=true, instant_resolve=true,
	level_range = {20, 50},
	greater_ego = true,
	rarity = 20,
	cost = 35,
	wielder = {
		resists={
			[DamageType.ACID] = resolvers.mbonus_material(8, 5, function(e, v) return v * 0.15 end),
			[DamageType.LIGHTNING] = resolvers.mbonus_material(8, 5, function(e, v) return v * 0.15 end),
			[DamageType.FIRE] = resolvers.mbonus_material(8, 5, function(e, v) return v * 0.15 end),
			[DamageType.COLD] = resolvers.mbonus_material(8, 5, function(e, v) return v * 0.15 end),
		},
		inc_stats = {
			[Stats.STAT_DEX] = resolvers.mbonus_material(6, 2, function(e, v) return v * 3 end),
		},
	},
}

newEntity{
	power_source = {nature=true},
	name = " of Eyal", suffix=true, instant_resolve=true,
	level_range = {20, 50},
	greater_ego = true,
	rarity = 16,
	cost = 30,
	wielder = {
		max_life=resolvers.mbonus_material(60, 40, function(e, v) return v * 0.1 end),
		life_regen = resolvers.mbonus_material(15, 5, function(e, v) v=v/10 return v * 10, v end),
		healing_factor = resolvers.mbonus_material(20, 10, function(e, v) v=v/100 return v * 80, v end),
	},
}

newEntity{
	power_source = {technique=true},
	name = " of Toknor", suffix=true, instant_resolve=true,
	level_range = {20, 50},
	greater_ego = true,
	rarity = 16,
	cost = 30,
	wielder = {
		combat_dam = resolvers.mbonus_material(5, 5, function(e, v) return v * 3 end),
		combat_physcrit = resolvers.mbonus_material(3, 3, function(e, v) return v * 1.4 end),
		combat_critical_power = resolvers.mbonus_material(10, 10, function(e, v) v=v/100 return v * 200, v end),
	},
}

newEntity{
	power_source = {technique=true},
	name = " of implacability", suffix=true, instant_resolve=true,
	level_range = {20, 50},
	greater_ego = true,
	rarity = 16,
	cost = 30,
	wielder = {
		stun_immune = resolvers.mbonus_material(20, 10, function(e, v) v=v/100 return v * 80, v end),
		pin_immune = resolvers.mbonus_material(20, 10, function(e, v) v=v/100 return v * 80, v end),
		combat_armor = resolvers.mbonus_material(6, 4, function(e, v) return v * 1 end),
		fatigue = resolvers.mbonus_material(6, 4, function(e, v) return v * 1, -v end),
	},
}
