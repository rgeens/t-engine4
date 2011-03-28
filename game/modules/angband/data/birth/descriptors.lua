-- ToME - Tales of Middle-Earth
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

newBirthDescriptor{
	type = "base",
	name = "base",
	desc = {
	},
	experience = 1.0,

	copy = {
		max_level = 50,
		max_life = 25,
		resolvers.inventory{ id=true, {type="food", name="& Ration~ of Food"} },
		resolvers.inventory{ id=true, {type="light", name="& Wooden Torch~"} },
	},
}

local PlayerRaces = require("mod.class.info.PlayerRaces")
local list = PlayerRaces:parse("/data/angband_edits/p_race.txt")
for i = 1, #list do if list[i].name then newBirthDescriptor(list[i]) end end

local PlayerClasses = require("mod.class.info.PlayerClasses")
local list = PlayerClasses:parse("/data/angband_edits/p_class.txt")
for i = 1, #list do if list[i].name then newBirthDescriptor(list[i]) end end
