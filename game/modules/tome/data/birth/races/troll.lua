-- ToME - Tales of Middle-Earth
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

---------------------------------------------------------
--                       Trolls                       --
---------------------------------------------------------
newBirthDescriptor{
	type = "race",
	name = "Troll",
	desc = {
		"",
	},
	descriptor_choices =
	{
		subrace =
		{
			__ALL__ = "disallow",
			Troll = "allow",
		},
		sex =
		{
			__ALL__ = "disallow",
			Male = "allow",
		},
	},
	stats = { str=4, con=3, wil=3, mag=-2, dex=-2 },
	talents = {
--		[ActorTalents.T_DWARF_RESILIENCE]=1,
	},
	copy = {
		faction = "orc-pride",
		type = "humanoid", subtype="troll",
		default_wilderness = {43, 18, "wilderness-arda-fareast"},
		starting_zone = "trollshaws",
		starting_quest = "start-dunadan",
		starting_intro = "dwarf",
		life_rating=10,
	},
	experience = 1.1,
}

---------------------------------------------------------
--                       Dwarves                       --
---------------------------------------------------------
newBirthDescriptor
{
	type = "subrace",
	name = "Troll",
	desc = {
		"",
	},
}
