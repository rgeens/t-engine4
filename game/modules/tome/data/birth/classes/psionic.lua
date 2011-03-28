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

newBirthDescriptor{
	type = "class",
	name = "Psionic",
	desc = {
		"Psionics find their power within themselves. Their highly trained minds can harness energy from many different sources and manipulate it to produce physical effects.",
	},
	descriptor_choices =
	{
		subclass =
		{
			__ALL__ = "disallow",
			Mindslayer = function() return profile.mod.allow_build.psionic_mindslayer and "allow" or "disallow" end,
		},
	},
	copy = {

	},
	body = { PSIONIC_FOCUS = 1, QS_PSIONIC_FOCUS = 1,},
}

newBirthDescriptor{
	type = "subclass",
	name = "Mindslayer",
	desc = {
		"Mindslayers specialize in direct and brutal application of mental forces to their immediate surroundings.",
		"When Mindslayers do battle, they will most often be found in the thick of the fighting, vast energies churning around them and telekinetically-wielded weapons hewing nearby foes at the speed of thought.",
		"Their most important stats are: Willpower and Cunning",
		"#GOLD#Stat modifiers:",
		"#LIGHT_BLUE# * +1 Strength, +0 Dexterity, +0 Constitution",
		"#LIGHT_BLUE# * +0 Magic, +4 Willpower, +3 Cunning",
	},
	stats = { str=1, wil=4, cun=3, },
	talents_types = {
		["psionic/absorption"]={true, 0.3},
		["psionic/projection"]={true, 0.3},
		["psionic/psi-fighting"]={true, 0.3},
		["psionic/focus"]={false, 0.3},
		["psionic/augmented-mobility"]={false, 0},
		["psionic/voracity"]={true, 0.3},
		["psionic/finer-energy-manipulations"]={false, 0},
		["psionic/mental-discipline"]={true, 0.3},
		["cunning/survival"]={true, 0},
		["technique/combat-training"]={true, 0},
	},
	talents = {
		[ActorTalents.T_KINETIC_SHIELD] = 1,
		[ActorTalents.T_KINETIC_AURA] = 1,
		[ActorTalents.T_KINETIC_LEECH] = 1,
		[ActorTalents.T_BEYOND_THE_FLESH] = 1,
		[ActorTalents.T_TRAP_DETECTION] = 1,
		[ActorTalents.T_TELEKINETIC_GRASP] = 1,
		[ActorTalents.T_TELEKINETIC_SMASH] = 1,
	},
	copy = {
		max_life = 110,
		resolvers.equip{ id=true,
			{type="armor", subtype="cloth", name="linen robe", autoreq=true, ego_chance=-1000},
			{type="weapon", subtype="greatsword", name="iron greatsword", autoreq=true, ego_chance=-1000},
		},
		resolvers.generic(function(self)
			-- Make and wield some alchemist gems
			local gs = game.zone:makeEntity(game.level, "object", {type="weapon", subtype="greatsword", name="iron greatsword", ego_chance=-1000}, nil, true)
			if gs then
				local pf = self:getInven("PSIONIC_FOCUS")
				self:addObject(pf, gs)
				gs:identify(true)
			end
		end),
	},
	copy_add = {
		life_rating = -4,
	},
}
