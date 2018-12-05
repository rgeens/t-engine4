-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2018 Nicolas Casalini
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

local BSP = require "engine.tilemaps.BSP"

-- rng.seed(2)

local tm = Tilemap.new(self.mapsize, '=', 1)

local bsp = BSP.new(10, 10, 8):make(50, 50, '.', '#')

local rooms = {}
for _, room in ipairs(bsp.rooms) do
	rooms[#rooms+1] = room.map
end

tm:merge(1, 1, bsp)

if not loadMapScript("lib/connect_rooms_multi", {map=tm, rooms=rooms, tunnel_char='.', tunnel_through={'#'}, edges_surplus=0}) then return self:regenerate() end

-- if tm:eliminateByFloodfill{'T','#'} < 800 then return self:regenerate() end

return tm
