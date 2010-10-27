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

load("/data/general/objects/objects-far-east.lua")

newEntity{ base = "BASE_GEM",
	define_as = "RESONATING_DIAMOND", no_unique_lore=true,
	name = "Resonating Diamond", color=colors.VIOLET, quest=true, unique=true, identified=true,

	on_pickup = function(self, who)
		if who == game.player then
			who:setQuestStatus("west-portal", engine.Quest.COMPLETED, "gem")
			return true
		end
	end,
}
