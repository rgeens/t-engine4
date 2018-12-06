-- ToME - Tales of Middle-Earth
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

newTalent{
	name = "Instill Fear",
	type = {"cursed/fears", 1},
	require = cursed_wil_req1,
	points = 5,
	random_ego = "attack",
	cooldown = 6,
	hate = 8,
	range = 8,
	radius = function(self, t) return 2 end,
	tactical = { DISABLE = 2 },
	getDuration = function(self, t)
		return 8
	end,
	getParanoidAttackChance = function(self, t)
		return math.min(60, self:combatTalentMindDamage(t, 30, 50))
	end,
	getDespairStatChange = function(self, t)
		return -self:combatTalentMindDamage(t, 15, 40)
	end,
	getTerrifiedPower = function(self,t)
		return math.floor(self:combatTalentMindDamage(t, 25, 60))
	end,
	getHauntedDamage = function(self, t)
		return self:combatTalentMindDamage(t, 40, 60)
	end,
	hasEffect = function(self, t, target)
		if not target then return false end
		if target:hasEffect(target.EFF_PARANOID) then return true end
		if target:hasEffect(target.EFF_DISPAIR) then return true end
		if target:hasEffect(target.EFF_TERRIFIED) then return true end
		if target:hasEffect(target.EFF_HAUNTED) then return true end
		return false
	end,
	applyEffect = function(self, t, target, no_fearRes)
		
		--tyrant mindpower bonus
		local tTyrant = nil
		if self:knowTalent(self.T_TYRANT) then tTyrant = self:getTalentFromId(self.T_TYRANT) end
		local mindpowerChange = tTyrant and tTyrant.getMindpowerChange(self, tTyrant) or 0
		
		--mindpower check
		local mindpower = self:combatMindpower(1, mindpowerChange)
		if not target:checkHit(mindpower, target:combatMentalResist()) then
			game.logSeen(target, "%s resists the fear!", target.name:capitalize())
			return nil
		end
		
		--apply heighten fear
		local tHeightenFear = nil
		if self:knowTalent(self.T_HEIGHTEN_FEAR) then tHeightenFear = self:getTalentFromId(self.T_HEIGHTEN_FEAR) end
		if tHeightenFear and not target:hasEffect(target.EFF_HEIGHTEN_FEAR) then
			local turnsUntilTrigger = tHeightenFear.getTurnsUntilTrigger(self, tHeightenFear)
			local dur = t.getDuration(self, t)
			target:setEffect(target.EFF_HEIGHTEN_FEAR, dur, {src=self, range=self:getTalentRange(tHeightenFear), turns=turnsUntilTrigger, turns_left=turnsUntilTrigger })
		end
		
		--fear res check & heighten fear bypass
		if not no_fearRes and not target:canBe("fear") then
			game.logSeen(target, "#F53CBE#%s ignores the fear!", target.name:capitalize())
			return true
		end
		
		--build table of possible fears
		local effects = {}
		if not target:hasEffect(target.EFF_PARANOID) then table.insert(effects, target.EFF_PARANOID) end
		if not target:hasEffect(target.EFF_DISPAIR) then table.insert(effects, target.EFF_DISPAIR) end
		if not target:hasEffect(target.EFF_TERRIFIED) then table.insert(effects, target.EFF_TERRIFIED) end
		if not target:hasEffect(target.EFF_HAUNTED) then table.insert(effects, target.EFF_HAUNTED) end
		
		--choose fear
		if #effects == 0 then return nil end
		local effectId = rng.table(effects)
		
		--data for fear effects
		local duration = t.getDuration(self, t)
		local eff = {src=self, duration=duration }
		if effectId == target.EFF_PARANOID then
			eff.attackChance = t.getParanoidAttackChance(self, t)
			eff.mindpower = mindpower
		elseif effectId == target.EFF_DISPAIR then
			eff.statChange = t.getDespairStatChange(self, t)
		elseif effectId == target.EFF_TERRIFIED then
			eff.cooldownPower = t.getTerrifiedPower(self, t) / 100
		elseif effectId == target.EFF_HAUNTED then
			eff.damage = t.getHauntedDamage(self, t)
		else
			print("* fears: failed to get effect", effectId)
		end
		
		if tTyrant then
			--data for tyrant buff
			eff.tyrantPower = tTyrant.getTyrantPower(self, tTyrant)
			eff.maxStacks = tTyrant.getMaxStacks(self, tTyrant)
			eff.tyrantDur = tTyrant.getTyrantDur(self, tTyrant)
			--extend fear durations
			local extendfear = tTyrant.getExtendFear(self, tTyrant)
			for eff_id, p in pairs(target.tmp) do
				local e = target.tempeffect_def[eff_id]
				if e.type == "mental" then
					if e.subtype == "fear" then
						if e.eff_id == target.EFF_PARANOID then
							p.dur = math.min(8, p.dur + t.extendfear(self, t))
						elseif e.eff_id == target.EFF_DISPAIR then
							p.dur = math.min(8, p.dur + t.extendfear(self, t))
						elseif e.eff_id == target.EFF_TERRIFIED then
							p.dur = math.min(8, p.dur + t.extendfear(self, t))
						elseif e.eff_id == target.EFF_HAUNTED then
							p.dur = math.min(8, p.dur + t.extendfear(self, t))
						elseif e.eff_id == target.EFF_HEIGHTEN_FEAR then
							p.dur = math.min(8, p.dur + t.extendfear(self, t))
						end
					end
				end
			end
		end
		
		--set fear
		target:setEffect(effectId, duration, eff)
		
		return effectId
	end,
	endEffect = function(self, t)
		local tHeightenFear = nil
		if self:knowTalent(self.T_HEIGHTEN_FEAR) then tHeightenFear = self:getTalentFromId(self.T_HEIGHTEN_FEAR) end
		if tHeightenFear then
			if not t.hasEffect(self, t) then
				-- no more fears
				self:removeEffect(self.EFF_HEIGHTEN_FEAR)
			end
		end
	end,
	requires_target = true,
	target = function(self, t) return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), talent=t} end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y or core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) then return nil end
		
		self:project(
			tg, x, y,
			function(px, py)
				local actor = game.level.map(px, py, engine.Map.ACTOR)
				if actor and self:reactionToward(actor) < 0 and actor ~= self then
					local tInstillFear = self:getTalentFromId(self.T_INSTILL_FEAR)
					tInstillFear.applyEffect(self, tInstillFear, actor)
				end
			end,
			nil, nil)
		return true
	end,
	info = function(self, t)
		return ([[Instill fear in your foes within %d radius of a target location, causing one of 4 possible fears that lasts for %d turns. The target can save versus Mindpower to resist the effect, and can be affected by multiple fears.  
		Possible fears are:
		Paranoid gives the target an %d%% chance to physically attack a nearby creature, friend or foe. If hit, their target will be afflicted with Paranoia as well.
		Despair reduces mind resist, mindsave, armour and defence by %d.
		Terrified increases cooldowns by %d%%.
		Haunted causes the target to suffer %d mind damage for each detrimental mental effect every turn.
		Fear effects improve with your Mindpower.]]):format(self:getTalentRadius(self, t), t.getDuration(self, t),
		t.getParanoidAttackChance(self, t),
		-t.getDespairStatChange(self, t),
		t.getTerrifiedPower(self, t),
		t.getHauntedDamage(self, t))
	end,
}

newTalent{
	name = "Heighten Fear",
	type = {"cursed/fears", 2},
	require = cursed_wil_req2,
	mode = "passive",
	points = 5,
	range = function(self, t)
		return math.floor(self:combatTalentScale(t, 4, 9))
	end,
	getTurnsUntilTrigger = function(self, t)
		return 4
	end,
	tactical = { DISABLE = 2 },
	info = function(self, t)
		local tInstillFear = self:getTalentFromId(self.T_INSTILL_FEAR)
		local range = self:getTalentRange(t)
		local turnsUntilTrigger = t.getTurnsUntilTrigger(self, t)
		local duration = tInstillFear.getDuration(self, tInstillFear)
		return ([[Heighten the fears of those near to you. Any foe you attempt to inflict a fear upon and who remains in a radius of %d and in sight of you for %d (non-consecutive) turns, will gain a new fear that lasts for %d turns. This effect completely ignores fear resistance, but can be saved against.]]):format(range, turnsUntilTrigger, duration)
	end,
}

newTalent{
	name = "Tyrant",
	type = {"cursed/fears", 3},
	mode = "passive",
	require = cursed_wil_req3,
	points = 5,
	on_learn = function(self, t)
	end,
	on_unlearn = function(self, t)
	end,
	getMindpowerChange = function(self, t) return math.floor(self:combatTalentScale(t, 10, 35)) end,
	getTyrantPower = function(self, t) return 2 end,
	getMaxStacks = function(self, t) return math.floor(self:combatTalentScale(t, 7, 20)) end,
	getTyrantDur = function(self, t) return 5 end,
	getExtendFear = function(self, t) return self:combatTalentScale(t, 1, 4) end
	info = function(self, t)
		return ([[Impose your tyranny on the minds of those who fear you. When a foe gains a fear, you increase the duration of any existing fears by %d turns, to a maximum of 8 turns.
		Additionally, your mindpower is increased by %d against foes who attempt to resist your fears and you gain %d mindpower and physpower for 5 turns every time you apply a fear, stacking up to %d times.]]):format(t.getExtendFear(self, t), t.getMindpowerChange(self, t), t.getTyrantPower(self, t), t.getMaxStacks(self, t))
	end,
}

newTalent{
	name = "Panic",
	type = {"cursed/fears", 4},
	require = cursed_wil_req4,
	points = 5,
	random_ego = "attack",
	cooldown = 20,
	hate =  1,
	range = 4,
	tactical = { DISABLE = 4 },
	getDuration = function(self, t)
		return 3 + math.floor(math.pow(self:getTalentLevel(t), 0.5) * 2.2)
	end,
	getChance = function(self, t)
		return math.min(60, math.floor(30 + (math.sqrt(self:getTalentLevel(t)) - 1) * 22))
	end,
	action = function(self, t)
		local range = self:getTalentRange(t)
		local duration = t.getDuration(self, t)
		local chance = t.getChance(self, t)
		local tTyrant = nil
		if self:knowTalent(self.T_TYRANT) then
			tTyrant = self:getTalentFromId(self.T_TYRANT)
		end
		if tTyrant then
			tyrantPower = tTyrant.getTyrantPower(self, tTyrant)
			maxStacks = tTyrant.getMaxStacks(self, tTyrant)
			tyrantDur = tTyrant.getTyrantDur(self, tTyrant)
		end
		self:project(
			{type="ball", radius=range}, self.x, self.y,
			function(px, py)
				local actor = game.level.map(px, py, engine.Map.ACTOR)
				if actor and self:reactionToward(actor) < 0 and actor ~= self then
					if not actor:canBe("fear") then
						game.logSeen(actor, "#F53CBE#%s ignores the panic!", actor.name:capitalize())
					elseif actor:checkHit(self:combatMindpower(), actor:combatMentalResist(), 0, 95) then
						actor:setEffect(actor.EFF_PANICKED, duration, {src=self, range=10, chance=chance, tyrantPower=tyrantPower, maxStacks=maxStacks, tyrantDur=tyrantDur})
					else
						game.logSeen(actor, "#F53CBE#%s resists the panic!", actor.name:capitalize())
					end
				end
			end,
			nil, nil)
		return true
	end,
	info = function(self, t)
		local range = self:getTalentRange(t)
		local duration = t.getDuration(self, t)
		local chance = t.getChance(self, t)
		return ([[Panic your enemies within a range of %d for %d turns. Anyone who fails to make a mental save against your Mindpower has a %d%% chance each turn of trying to run away from you.]]):format(range, duration, chance)
	end,
}
