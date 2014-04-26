-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2014 Nicolas Casalini
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

base_size = 64

local speed = speed or 0.023
local a = a or 60
local basesize = 2 * radius * (engine.Map.tile_w + engine.Map.tile_h) / 2 + engine.Map.tile_w * 1.8 * (oversize or 1)

return {
	system_rotation = 0, system_rotationv = speed,

	base = 1000,

	angle = { 0, 0 }, anglev = { 0, 0 }, anglea = { 0, 0 },

	life = { 100, 100 },
	size = { basesize, basesize }, sizev = {0, 0}, sizea = {0, 0},

	r = {255, 255}, rv = {0, 0}, ra = {0, 0},
	g = {255, 255}, gv = {0, 0}, ga = {0, 0},
	b = {255, 255}, bv = {0, 0}, ba = {0, 0},
	a = {a, a}, av = {0, 0}, aa = {0, 0},

}, function(self)
	self.ps:emit(1)
end, 1, "particles_images/"..img, true
