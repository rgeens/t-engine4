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

newEntity{
	define_as = "UP",
	name = "previous level",
	display = '<', color_r=255, color_g=255, color_b=0, back_color=colors.DARK_GREY,
	notice = true,
	always_remember = true,
	change_level = -1,
}

newEntity{
	define_as = "DOWN",
	name = "next level",
	display = '>', color_r=255, color_g=255, color_b=0, back_color=colors.DARK_GREY,
	notice = true,
	always_remember = true,
	change_level = 1,
}

newEntity{
	define_as = "FLOOR",
	name = "floor", image = "terrain/marble_floor.png",
	display = ' ', color_r=255, color_g=255, color_b=255, back_color=colors.DARK_GREY,
	always_remember = true,
}

newEntity{
	define_as = "WALL",
	name = "wall", image = "terrain/granite_wall1.png",
	display = '#', color_r=255, color_g=255, color_b=255, back_color=colors.DARK_GREY,
	always_remember = true,
	does_block_move = true,
	block_sight = true,
}
