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

local Stats = require "engine.interface.ActorStats"

newEntity{
	power_source = {technique=true},
	name = " of the badger", suffix=true,
	level_range = {1, 50},
	rarity = 7,
	cost = 20,
	resolvers.generic(function(e) e.digspeed = math.ceil(e.digspeed / 2) end),
}

newEntity{
	power_source = {technique=true},
	name = " of strength", suffix=true, instant_resolve=true,
	level_range = {10, 50},
	rarity = 6,
	cost = 10,
	wielder = {
		inc_stats = { [Stats.STAT_STR] = resolvers.mbonus_material(4, 1, function(e, v) return v * 3 end) },
	},
}

newEntity{
	power_source = {technique=true},
	name = " of delving", suffix=true, instant_resolve=true,
	level_range = {30, 50},
	greater_ego = 1,
	rarity = 20,
	cost = 20,
	wielder = {
		lite = 1,
		inc_stats = { [Stats.STAT_STR] = resolvers.mbonus_material(3, 1, function(e, v) return v * 3 end), [Stats.STAT_CON] = resolvers.mbonus_material(3, 1, function(e, v) return v * 3 end) },
	},
}

newEntity{
	power_source = {technique=true},
	name = " of endurance", suffix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 6,
	cost = 5,
	wielder = {
		fatigue = resolvers.mbonus_material(6, 4, function(e, v) return v * 1, -v end),
	},
}

newEntity{
	power_source = {technique=true},
	name = "miner's ", prefix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 6,
	cost = 5,
	wielder = {
		infravision = resolvers.mbonus_material(2, 1, function(e, v) return v * 1.4 end),
	},
}

newEntity{
	power_source = {nature=true},
	name = "woodsman's ", prefix=true, instant_resolve=true,
	level_range = {1, 50},
	rarity = 6,
	cost = 5,
	wielder = {
		resists = { [DamageType.NATURE] = resolvers.mbonus_material(5, 10, function(e, v) return v * 0.15 end), }
	},
}

newEntity{
	power_source = {technique=true},
	name = " of the Iron Throne", suffix=true, instant_resolve=true,
	level_range = {20, 50},
	greater_ego = 1,
	rarity = 15,
	cost = 15,
	wielder = {
		max_life = resolvers.mbonus_material(20, 20, function(e, v) return v * 0.1 end),
		max_stamina = resolvers.mbonus_material(15, 15, function(e, v) return v * 0.1 end),
	},
	resolvers.generic(function(e) e.digspeed = math.ceil(e.digspeed / 3) end),
}

newEntity{
	power_source = {technique=true},
	name = " of Reknor", suffix=true, instant_resolve=true,
	level_range = {20, 50},
	greater_ego = 1,
	rarity = 15,
	cost = 15,
	wielder = {
		resists={
			[DamageType.FIRE] = resolvers.mbonus_material(5, 5, function(e, v) return v * 0.15 end),
			[DamageType.DARKNESS] = resolvers.mbonus_material(5, 5, function(e, v) return v * 0.15 end),
		},
	},
	resolvers.generic(function(e) e.digspeed = math.ceil(e.digspeed / 3) end),
}

newEntity{
	power_source = {technique=true},
	name = "brutal ", prefix=true, instant_resolve=true,
	level_range = {40, 50},
	greater_ego = 1,
	rarity = 20,
	cost = 70,
	wielder = {
		combat_dam = resolvers.mbonus_material(5, 5, function(e, v) return v * 3 end),
		combat_apr = resolvers.mbonus_material(4, 4, function(e, v) return v * 0.3 end),
		combat_critical_power = resolvers.mbonus_material(10, 10, function(e, v) return v * 2, v end),
	},
	resolvers.generic(function(e) e.digspeed = math.ceil(e.digspeed / 3) end),
}

newEntity{
	power_source = {technique=true},
	name = "builder's ", prefix=true, instant_resolve=true,
	level_range = {30, 50},
	greater_ego = 1,
	rarity = 15,
	cost = 15,
	wielder = {
		inc_stats = {
			[Stats.STAT_CUN] = resolvers.mbonus_material(2, 2, function(e, v) return v * 3 end),
			},
		confusion_immune = resolvers.mbonus_material(3, 2, function(e, v) v=v/10 return v * 8, v end),
	},
	resolvers.generic(function(e) e.digspeed = math.ceil(e.digspeed / 3) end),
}

newEntity{
	power_source = {technique=true},
	name = "soldier's ", prefix=true, instant_resolve=true,
	level_range = {30, 50},
	greater_ego = 1,
	rarity = 15,
	cost = 15,
	wielder = {
		combat_def = resolvers.mbonus_material(4, 4, function(e, v) return v * 1 end),
		combat_armor = resolvers.mbonus_material(3, 2, function(e, v) return v * 1 end),
	},
	resolvers.generic(function(e) e.digspeed = math.ceil(e.digspeed / 3) end),
}


