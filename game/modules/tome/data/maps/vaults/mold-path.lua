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

setStatusAll{no_teleport=true}

rotates = {"default", "90", "180", "270", "flipx", "flipy"}

defineTile('.', "GRASS")
defineTile('#', {"TREE","TREE2","TREE3","TREE4","TREE5","TREE6","TREE7","TREE8","TREE9","TREE10","TREE11","TREE12","TREE13","TREE14","TREE15","TREE16","TREE17","TREE18","TREE19","TREE20"})
defineTile('X', {"HARDTREE","HARDTREE2","HARDTREE3","HARDTREE4","HARDTREE5","HARDTREE6","HARDTREE7","HARDTREE8","HARDTREE9","HARDTREE10","HARDTREE11","HARDTREE12","HARDTREE13","HARDTREE14","HARDTREE15","HARDTREE16","HARDTREE17","HARDTREE18","HARDTREE19","HARDTREE20"})
defineTile('~', "POISON_DEEP_WATER")
defineTile('!', "ROCK_VAULT")

defineTile('m', "GRASS", nil, {random_filter={subtype="molds", add_levels=2}})
defineTile('j', "GRASS", nil, {random_filter={subtype="oozes", add_levels=2}})

defineTile('$', "GRASS", {random_filter={add_levels=5, tome_mod="vault"}})

startx = 19
starty = 7

return {
[[#XXXXXXXXX#####XXXX#]],
[[XXm~..~.~XXXX#XX$$XX]],
[[X~~...j..~~jXXXmmmmX]],
[[X~...mXX.j...j..jjXX]],
[[Xm..~XXXXX~~.~.jXXX#]],
[[XX.mmXXXXXXXXXXXX###]],
[[XmmmXXXXXXXXXXXXXXXX]],
[[X~..mXXXX~.mmXXm...!]],
[[XXm...m.........~mXX]],
[[#XXXX~~.mXXXm~m~XXX#]],
[[####XXXXXX#XXXXXX###]],
}
