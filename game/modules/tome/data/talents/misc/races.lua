-- ToME - Tales of Maj'Eyal
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

-- Generic requires for racial based on talent level
racial_req1 = {
	level = function(level) return 0 + (level-1)  end,
}
racial_req2 = {
	level = function(level) return 8 + (level-1)  end,
}
racial_req3 = {
	level = function(level) return 16 + (level-1)  end,
}
racial_req4 = {
	level = function(level) return 24 + (level-1)  end,
}

------------------------------------------------------------------
-- Highers's powers
------------------------------------------------------------------
newTalentType{ type="race/higher", name = "higher", generic = true, description = "The various racial bonuses a character can have." }

newTalent{
	short_name = "HIGHER_HEAL",
	name = "Gift of the Highborn",
	type = {"race/higher", 1},
	require = racial_req1,
	points = 5,
	no_energy = true,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 5 end,
	tactical = { HEAL = 2 },
	action = function(self, t)
		self:setEffect(self.EFF_REGENERATION, 10, {power=5 + self:getWil() * 0.5})
		return true
	end,
	info = function(self, t)
		return ([[Call upon the gift of the highborn to regenerate your body for %d life every turn for 10 turns.
		The life healed will increase with the Willpower stat]]):format(5 + self:getWil() * 0.6)
	end,
}

newTalent{
	name = "Overseer of Nations",
	type = {"race/higher", 2},
	require = racial_req2,
	points = 5,
	mode = "passive",
	on_learn = function(self, t)
		self.sight = self.sight + 1
	end,
	on_unlearn = function(self, t)
		self.sight = self.sight - 1
	end,
	info = function(self, t)
		return ([[While Highers are not meant to rule other humans - and show no particular will to do so - they are frequently called to higher duties.
		Their nature grants them better sense than other humans.
		Increase maximun sight range by %d.]]):format(self:getTalentLevelRaw(t))
	end,
}

newTalent{
	name = "Born into Magic",
	type = {"race/higher", 3},
	require = racial_req3,
	points = 5,
	mode = "passive",
	on_learn = function(self, t)
		self.combat_spellresist = self.combat_spellresist + 3
		self.resists[DamageType.ARCANE] = (self.resists[DamageType.ARCANE] or 0) + 5
	end,
	on_unlearn = function(self, t)
		self.combat_spellresist = self.combat_spellresist - 3
		self.resists[DamageType.ARCANE] = (self.resists[DamageType.ARCANE] or 0) - 5
	end,
	info = function(self, t)
		return ([[Highers have originaly been created during the Age of Allure by the human Conclave. They are imbued with magic at the very core of their being.
		Increase spell save by +%d and Arcane resistance by %d%%.]]):format(self:getTalentLevelRaw(t) * 3, self:getTalentLevelRaw(t) * 5)
	end,
}

newTalent{
	name = "Highborn's Bloom",
	type = {"race/higher", 4},
	require = racial_req4,
	points = 5,
	no_energy = true,
	cooldown = function(self, t) return 100 - self:getTalentLevel(t) * 5 end,
	tactical = { MANA = 2, VIM = 2, EQUILIBRIUM = 2, STAMINA = 2, POSITIVE = 2, NEGATIVE = 2, PARADOX = 2, PSI = 2 },
	getData = function(self, t)
		local base = self:combatTalentStatDamage(t, "con", 10, 90)
		return {
			stamina = base,
			mana = base * 1.8,
			equilibrium = -base * 1.5,
			vim = base,
			positive = base / 2,
			negative = base / 2,
			paradox = -base * 1.5,
			psi = base * 0.7,
		}
	end,
	action = function(self, t)
		local data = t.getData(self, t)
		for name, v in pairs(data) do
			local inc = "inc"..name:capitalize()
			if self[inc] then self[inc](self, v) end
		end
		return true
	end,
	info = function(self, t)
		local d = t.getData(self, t)
		return ([[Activate some of your inner magic, manipulating the world to be in a better shape for you.
		Restores %d stamina, %d mana, %d equilibrium, %d vim, %d positive and negative energies, %d paradox and %d psi energy.
		The effect increases with your Constitution.]]):format(d.stamina, d.mana, d.equilibrium, d.vim, d.positive, d.paradox, d.psi)
	end,
}

------------------------------------------------------------------
-- Shaloren's powers
------------------------------------------------------------------
newTalentType{ type="race/shalore", name = "shalore", generic = true, is_spell=true, description = "The various racial bonuses a character can have." }
newTalent{
	short_name = "SHALOREN_SPEED",
	name = "Grace of the Eternals",
	type = {"race/shalore", 1},
	require = racial_req1,
	points = 5,
	no_energy = true,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 4 end,
	tactical = { DEFEND = 1 },
	action = function(self, t)
		local power = 0.1 + self:getDex() / 210
		self:setEffect(self.EFF_SPEED, 8, {power=1 - 1 / (1 + power)})
		return true
	end,
	info = function(self, t)
		return ([[Call upon the grace of the Eternals to increase your general speed by %d%% for 8 turns.
		The speed bonus will increase with the Dexterity stat]]):format((0.1 + self:getDex() / 210) * 100)
	end,
}

newTalent{
	name = "Magic of the Eternals",
	type = {"race/shalore", 2},
	require = racial_req2,
	points = 5,
	mode = "passive",
	on_learn = function(self, t)
		self.combat_physcrit = self.combat_physcrit + 2
		self.combat_spellcrit = self.combat_spellcrit + 2
		self.combat_mindcrit = self.combat_mindcrit + 2
	end,
	on_unlearn = function(self, t)
		self.combat_physcrit = self.combat_physcrit - 2
		self.combat_spellcrit = self.combat_spellcrit - 2
		self.combat_mindcrit = self.combat_mindcrit - 2
	end,
	info = function(self, t)
		return ([[Reality bends slightly in the presence of a Shaloren due to their inherent magical nature.
		Increases critical chance by %d%%.]]):format(self:getTalentLevelRaw(t) * 2)
	end,
}

newTalent{
	name = "Secrets of the Eternals",
	type = {"race/shalore", 3},
	require = racial_req3,
	points = 5,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 3 end,
	mode = "sustained",
	activate = function(self, t)
		self.invis_on_hit_disable = self.invis_on_hit_disable or {}
		game:playSoundNear(self, "talents/spell_generic2")
		local ret = {
			invis = self:addTemporaryValue("invis_on_hit", self:getTalentLevelRaw(t) * 5),
			power = self:addTemporaryValue("invis_on_hit_power", 5 + self:getMag(20)),
			talent = self:addTemporaryValue("invis_on_hit_disable", {[t.id]=1}),
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("invis_on_hit", p.invis)
		self:removeTemporaryValue("invis_on_hit_power", p.power)
		self:removeTemporaryValue("invis_on_hit_disable", p.talent)
		return true
	end,
	info = function(self, t)
		return ([[As the only immortal race of Eyal, Shaloren have learnt, over the long years, to use their innate inner magic to protect themselves.
		%d%% chances to become invisible (power %d) for 5 turns when hit by a blow doing at least 15%% of their total life.]]):
		format(self:getTalentLevelRaw(t) * 5, 5 + self:getMag(20))
	end,
}

newTalent{
	name = "Timeless",
	type = {"race/shalore", 4},
	require = racial_req4,
	points = 5,
	no_energy = true,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 3 end,
	tactical = { ATTACK = 2 },
	action = function(self, t)
		local target = self
		for eff_id, p in pairs(target.tmp) do
			local e = target.tempeffect_def[eff_id]
			if e.status == "beneficial" then
				p.dur = p.dur + self:getTalentLevelRaw(t)
			elseif e.status == "detrimental" then
				p.dur = p.dur - self:getTalentLevelRaw(t) * 2
			end
		end

		game:playSoundNear(self, "talents/spell_generic")
		return true
	end,
	info = function(self, t)
		return ([[The world grows old as you stand the ages. To you time is different.
		Reduces the time remaining on detrimental effects by %d and increases the time remaining on beneficial effects by %d.]]):
		format(self:getTalentLevelRaw(t) * 2, self:getTalentLevelRaw(t))
	end,
}

------------------------------------------------------------------
-- Thaloren powers
------------------------------------------------------------------
newTalentType{ type="race/thalore", name = "thalore", generic = true, description = "The various racial bonuses a character can have." }
newTalent{
	short_name = "THALOREN_WRATH",
	name = "Wrath of the Woods",
	type = {"race/thalore", 1},
	require = racial_req1,
	points = 5,
	no_energy = true,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 5 end,
	tactical = { ATTACK = 1, DEFEND = 1 },
	action = function(self, t)
		self:setEffect(self.EFF_ETERNAL_WRATH, 5, {power=7 + self:getWil(10)})
		return true
	end,
	info = function(self, t)
		return ([[Call upon the power of the Eternals, increasing all damage by %d%% and reducing all damage taken by %d%% for 5 turns.
		The bonus will increase with the Willpower stat]]):format(7 + self:getWil(10), 7 + self:getWil(10))
	end,
}

newTalent{
	name = "Unshackled",
	type = {"race/thalore", 2},
	require = racial_req2,
	points = 5,
	mode = "passive",
	on_learn = function(self, t)
		self.combat_physresist = self.combat_physresist + 5
		self.combat_mentalresist = self.combat_mentalresist + 5
	end,
	on_unlearn = function(self, t)
		self.combat_physresist = self.combat_physresist - 5
		self.combat_mentalresist = self.combat_mentalresist - 5
	end,
	info = function(self, t)
		return ([[Thaloren have always been a free people, living in their beloved forest, never carrying much about the world outside.
		Increase physical and mental save by +%d.]]):format(self:getTalentLevelRaw(t) * 5)
	end,
}

newTalent{
	name = "Guardian of the Wood",
	type = {"race/thalore", 3},
	require = racial_req3,
	points = 5,
	mode = "passive",
	on_learn = function(self, t)
		self.disease_immune = self.disease_immune + 0.12
		self.resists[DamageType.BLIGHT] = (self.resists[DamageType.BLIGHT] or 0) + 4
	end,
	on_unlearn = function(self, t)
		self.disease_immune = self.disease_immune - 0.12
		self.resists[DamageType.BLIGHT] = (self.resists[DamageType.BLIGHT] or 0) - 4
	end,
	info = function(self, t)
		return ([[You are part of the wood, it shields you from corruption.
		Increase diseases immunity by %d%% and Blight resistance by %d%%.]]):format(self:getTalentLevel(t) * 12, self:getTalentLevel(t) * 4)
	end,
}

newTalent{
	name = "Nature's Pride",
	type = {"race/thalore", 4},
	require = racial_req4,
	points = 5,
	no_energy = true,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 3 end,
	tactical = { ATTACK = 2 },
	action = function(self, t)
		local tg = {type="bolt", nowarning=true, range=self:getTalentRange(t), nolock=true, talent=t}
		local tx, ty, target = self:getTarget(tg)
		if not tx or not ty then return nil end
		local _ _, tx, ty = self:canProject(tg, tx, ty)
		target = game.level.map(tx, ty, Map.ACTOR)
		if target == self then target = nil end

		-- Find space
		for i = 1, 2 do
			local x, y = util.findFreeGrid(tx, ty, 5, true, {[Map.ACTOR]=true})
			if not x then
				game.logPlayer(self, "Not enough space to summon!")
				return
			end

			local NPC = require "mod.class.NPC"
			local m = NPC.new{
				type = "immovable", subtype = "plants",
				display = "#",
				name = "treant", color=colors.GREEN,
				desc = "A very strong near-sentient tree.",

				body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1 },

				rank = 3,
				life_rating = 13,
				max_life = resolvers.rngavg(50,80),
				infravision = 20,

				autolevel = "none",
				ai = "summoned", ai_real = "tactical", ai_state = { talent_in=2, },
				stats = {str=0, dex=0, con=0, cun=0, wil=0, mag=0},
				combat = { dam=resolvers.levelup(resolvers.rngavg(15,25), 1, 1.3), atk=resolvers.levelup(resolvers.rngavg(15,25), 1, 1.3), dammod={str=1.1} },
				inc_stats = { str=25 + self:getWil() * self:getTalentLevel(t) / 5, dex=18, con=10 + self:getTalentLevel(t) * 2, },

				level_range = {1, nil}, exp_worth = 0,
				silent_levelup = true,

				combat_armor = 13, combat_def = 8,
				resolvers.talents{ [Talents.T_STUN]=3, [Talents.T_KNOCKBACK]=2, },

				faction = self.faction,
				summoner = self, summoner_gain_exp=true,
				summon_time = 6,
				ai_target = {actor=target}
			}
			setupSummon(self, m, x, y)
		end

		game:playSoundNear(self, "talents/spell_generic")
		return true
	end,
	info = function(self, t)
		return ([[Nature is with you, you can always feel the call of the woods.
		Summons two elite Treants to your side for 6 turns.
		Their strength increase with your Willpower stat]]):format()
	end,
}

------------------------------------------------------------------
-- Dwarvess powers
------------------------------------------------------------------
newTalentType{ type="race/dwarf", name = "dwarf", generic = true, description = "The various racial bonuses a character can have." }
newTalent{
	short_name = "DWARF_RESILIENCE",
	name = "Resilience of the Dwarves",
	type = {"race/dwarf", 1},
	require = racial_req1,
	points = 5,
	no_energy = true,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 5 end,
	tactical = { DEFEND = 2 },
	action = function(self, t)
		self:setEffect(self.EFF_DWARVEN_RESILIENCE, 8, {
			armor=5 + self:getCon() / 5,
			physical=10 + self:getCon() / 5,
			spell=10 + self:getCon() / 5,
		})
		return true
	end,
	info = function(self, t)
		return ([[Call upon the legendary resilience of the Dwarven race to increase your armor(+%d), spell(+%d) and physical(+%d) saves for 8 turns.
		The bonus will increase with the Constitution stat]]):format(5 + self:getCon() / 5, 10 + self:getCon() / 5, 10 + self:getCon() / 5)
	end,
}

------------------------------------------------------------------
-- Halflings powers
------------------------------------------------------------------
newTalentType{ type="race/halfling", name = "halfling", generic = true, description = "The various racial bonuses a character can have." }
newTalent{
	short_name = "HALFLING_LUCK",
	name = "Luck of the Little Folk",
	type = {"race/halfling", 1},
	require = racial_req1,
	points = 5,
	no_energy = true,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 5 end,
	tactical = { ATTACK = 2 },
	action = function(self, t)
		self:setEffect(self.EFF_HALFLING_LUCK, 5, {
			physical=10 + self:getCun() / 2,
			spell=10 + self:getCun() / 2,
		})
		return true
	end,
	info = function(self, t)
		return ([[Call upon the luck and cunning of the Little Folk to increase your physical and spell critical strike chance by %d%% for 5 turns.
		The bonus will increase with the Cunning stat]]):format(10 + self:getCun() / 5, 10 + self:getCun() / 5)
	end,
}

------------------------------------------------------------------
-- Orcs powers
------------------------------------------------------------------
newTalentType{ type="race/orc", name = "orc", generic = true, description = "The various racial bonuses a character can have." }
newTalent{
	short_name = "ORC_FURY",
	name = "Orcish Fury",
	type = {"race/orc", 1},
	require = racial_req1,
	points = 5,
	no_energy = true,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 5 end,
	tactical = { ATTACK = 2 },
	action = function(self, t)
		self:setEffect(self.EFF_ORC_FURY, 5, {power=10 + self:getWil(20)})
		return true
	end,
	info = function(self, t)
		return ([[Summons your lust for blood and destruction, increasing all damage by %d%% for 5 turns.
		The bonus will increase with the Willpower stat]]):format(10 + self:getWil(20))
	end,
}

------------------------------------------------------------------
-- Yeeks powers
------------------------------------------------------------------
newTalentType{ type="race/yeek", name = "yeek", generic = true, description = "The various racial bonuses a character can have." }
newTalent{
	short_name = "YEEK_WILL",
	name = "Dominant Will",
	type = {"race/yeek", 1},
	require = racial_req1,
	points = 5,
	no_energy = true,
	cooldown = function(self, t) return 50 - self:getTalentLevel(t) * 3 end,
	range = 4,
	no_npc_use = true,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if not target then return end
			if not target:canBe("instakill") or target.rank > 2 or target.undead or not target:checkHit(self:getWil(20) + self.level * 1.5, target.level) then
				game.logSeen(target, "%s resists the mental assault!", target.name:capitalize())
				return
			end
			target:setEffect(target.EFF_DOMINANT_WILL, 4 + self:getWil(10), {src=self})
		end)
		return true
	end,
	info = function(self, t)
		return ([[Shatters the mind of your victim, giving your full control over its actions for %s turns.
		When the effect ends you pull out your mind and the victim's body colapses dead.
		This effect does not work on elite or undeads.
		The duration will increase with the Willpower stat]]):format(4 + self:getWil(10))
	end,
}

-- Yeek's power: ID
newTalent{
	short_name = "YEEK_ID",
	name = "Knowledge of the Way",
	type = {"race/yeek", 1},
	no_npc_use = true,
	on_learn = function(self, t) self.auto_id = 2 end,
	action = function(self, t)
		local Chat = require("engine.Chat")
		local chat = Chat.new("elisa-orb-scrying", {name="The Way"}, self, {version="yeek"})
		chat:invoke()
		return true
	end,
	info = function(self, t)
		return ([[You merge your mind with the rest of the Way for a brief moment, the sum of all yeek knowledge gathers in your mind
		and allows you to identify any item you could not recognize yourself.]])
	end,
}
