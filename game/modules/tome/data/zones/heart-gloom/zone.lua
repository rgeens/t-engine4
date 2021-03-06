-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2019 Nicolas Casalini
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

local layout = game.state:alternateZone(short_name, {"PURIFIED", 2})
local is_purified = layout == "PURIFIED"

return {
	name = "Heart of the Gloom",
	level_range = {1, 7},
	level_scheme = "player",
	max_level = 3,
	decay = {300, 800},
	actor_adjust_level = function(zone, level, e) return zone.base_level + level.level-1 + e:getRankLevelAdjust() + 1 end,
	width = 50, height = 50,
	tier1 = true,
	tier1_escort = 1,
--	all_remembered = true,
	all_lited = true,
	persistent = "zone",
	ambient_music = "Taking flight.ogg",
	max_material_level = 1,
	is_purified = is_purified,
	generator =  {
		map = {
			class = "engine.generator.map.Octopus",
			main_radius = {0.3, 0.4},
			arms_radius = {0.1, 0.2},
			arms_range = {0.7, 0.8},
			nb_rooms = {5, 9},
			['#'] = {
				"TREE",
				"UNDERGROUND_TREE",
				"UNDERGROUND_TREE",
				"UNDERGROUND_TREE",
				"UNDERGROUND_TREE",
				"UNDERGROUND_TREE",
				"UNDERGROUND_TREE",
				"UNDERGROUND_TREE",
				"UNDERGROUND_TREE",
				"UNDERGROUND_TREE",
				"UNDERGROUND_TREE",
				"UNDERGROUND_TREE",
			},
			['.'] = {
				"UNDERGROUND_FLOOR",
				"UNDERGROUND_FLOOR",
				"UNDERGROUND_FLOOR",
				"UNDERGROUND_FLOOR",
				"UNDERGROUND_FLOOR",
				"UNDERGROUND_FLOOR",
				"UNDERGROUND_FLOOR",
				"UNDERGROUND_CREEP",
			},
			up = "UNDERGROUND_LADDER_UP",
			down = "UNDERGROUND_LADDER_DOWN",
			door = "UNDERGROUND_FLOOR",
		},
		actor = {
			class = "mod.class.generator.actor.Random",
			nb_npc = {20, 30},
			filters = { {max_ood=2}, },
			guardian = is_purified and "DREAMING_ONE" or "WITHERING_THING",
		},
		object = {
			class = "engine.generator.object.Random",
			nb_object = {6, 9},
		},
		trap = {
			class = "engine.generator.trap.Random",
			nb_trap = {0, 0},
		},
	},
	levels =
	{
		[1] = {
			generator = { map = {
				up = "UNDERGROUND_LADDER_UP_WILDERNESS",
			}, },
		},
	},

	post_process = function(level)
		local Map = require "engine.Map"
		level.foreground_particle = require("engine.Particles").new(is_purified and "fulldream" or "fullgloom", 1, {radius=(Map.viewport.mwidth + Map.viewport.mheight) / 2})
	end,

	foreground = function(level, x, y, nb_keyframes)
		if not level.foreground_particle then return end
		level.foreground_particle.ps:toScreen(x + level.map.viewport.width / 2, y + level.map.viewport.height / 2, true, 1)
	end,
}
