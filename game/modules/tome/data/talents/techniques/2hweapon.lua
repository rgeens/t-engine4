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


newTalent{
	name = "Death Dance",
	type = {"technique/2hweapon-offense", 1},
	require = techs_req1,
	points = 5,
	random_ego = "attack",
	cooldown = 10,
	stamina = 30,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Death Dance without a two-handed weapon!")
			return nil
		end

		for i = -1, 1 do for j = -1, 1 do
			local x, y = self.x + i, self.y + j
			if (self.x ~= x or self.y ~= y) and game.level.map:isBound(x, y) and game.level.map(x, y, Map.ACTOR) then
				local target = game.level.map(x, y, Map.ACTOR)
				self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 1.4, 2.1))
			end
		end end

		return true
	end,
	info = function(self, t)
		return ([[Spin around, extending your weapon and damaging all targets around you for %d%% weapon damage.]]):format(100 * self:combatTalentWeaponDamage(t, 1.4, 2.1))
	end,
}

newTalent{
	name = "Berserker",
	type = {"technique/2hweapon-offense", 2},
	require = techs_req2,
	points = 5,
	mode = "sustained",
	cooldown = 30,
	sustain_stamina = 40,
	activate = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Berserker without a two-handed weapon!")
			return nil
		end

		return {
			stun = self:addTemporaryValue("stun_immune", 0.1 * self:getTalentLevel(t)),
			pin = self:addTemporaryValue("pin_immune", 0.1 * self:getTalentLevel(t)),
			dam = self:addTemporaryValue("combat_dam", 5 + self:getStr(7) * self:getTalentLevel(t)),
			atk = self:addTemporaryValue("combat_atk", 5 + self:getDex(7) * self:getTalentLevel(t)),
			def = self:addTemporaryValue("combat_def", -10),
			armor = self:addTemporaryValue("combat_armor", -10),
		}
	end,

	deactivate = function(self, t, p)
		self:removeTemporaryValue("stun_immune", p.stun)
		self:removeTemporaryValue("pin_immune", p.pin)
		self:removeTemporaryValue("combat_def", p.def)
		self:removeTemporaryValue("combat_armor", p.armor)
		self:removeTemporaryValue("combat_atk", p.atk)
		self:removeTemporaryValue("combat_dam", p.dam)
		return true
	end,
	info = function(self, t)
		return ([[Enters an aggressive battle stance, increasing attack by %d and damage by %d at the cost of -10 defense and -10 armor.
		While berserking you are nearly unstoppable, granting %d%% stun and pinning resistance.
		Attack increase with your Dexterity stat and damage with your Strength stat]]):
		format(
			5 + self:getDex(7) * self:getTalentLevel(t),
			5 + self:getStr(7) * self:getTalentLevel(t),
			10 * self:getTalentLevel(t)
		)
	end,
}

newTalent{
	name = "Warshout",
	type = {"technique/2hweapon-offense",3},
	require = techs_req3,
	points = 5,
	random_ego = "attack",
	stamina = 30,
	cooldown = 18,
	tactical = {
		ATTACKAREA = 10,
	},
	range = 1,
	requires_target = true,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Warshout without a two-handed weapon!")
			return nil
		end

		local tg = {type="cone", range=0, radius=3 + self:getTalentLevelRaw(t), friendlyfire=false}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, DamageType.CONFUSION, {
			dur=3+self:getTalentLevelRaw(t),
			dam=50+self:getTalentLevelRaw(t)*10,
			power_check=function() return self:combatAttackStr(weapon) end,
			resist_check=self.combatPhysicalResist,
		}, {type="flame"})
		return true
	end,
	info = function(self, t)
		return ([[Shout your warcry in a frontal cone. Any targets caught inside will be confused for %d turns.]]):
		format(3 + self:getTalentLevelRaw(t))
	end,
}

newTalent{
	name = "Death Blow",
	type = {"technique/2hweapon-offense", 4},
	require = techs_req4,
	points = 5,
	random_ego = "attack",
	cooldown = 30,
	stamina = 30,
	requires_target = true,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Death Blow without a two-handed weapon!")
			return nil
		end

		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if math.floor(core.fov.distance(self.x, self.y, x, y)) > 1 then return nil end

		local inc = self.stamina / 2
		if self:getTalentLevel(t) >= 4 then
			self.combat_dam = self.combat_dam + inc
		end
		self.combat_physcrit = self.combat_physcrit + 100

		local speed, hit = self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 0.8, 1.3))

		if self:getTalentLevel(t) >= 4 then
			self.combat_dam = self.combat_dam - inc
			self.stamina = 0
		end
		self.combat_physcrit = self.combat_physcrit - 100

		-- Try to insta-kill
		if hit then
			if target:checkHit(self:combatAttackStr(weapon.combat), target:combatPhysicalResist(), 0, 95, 5 - self:getTalentLevel(t) / 2) and target:canBe("instakill") and target.life > 0 and target.life < target.max_life * 0.2 then
				-- KILL IT !
				game.logSeen(target, "%s feels the pain of the death blow!", target.name:capitalize())
				target:die(self)
			elseif target.life > 0 and target.life < target.max_life * 0.2 then
				game.logSeen(target, "%s resists the death blow!", target.name:capitalize())
			end
		end
		return true
	end,
	info = function(self, t)
		return ([[Tries to perform a killing blow doing %d%% weapon damage, granting an automatic critical hit. If the target ends up with low enough life(<20%%) it might be instantly killed.
		At level 4 it drains all remaining stamina and uses it to increase the blow damage by 50%% of it.
		Chance to instant kill will increase with your Strength stat.]]):format(100 * self:combatTalentWeaponDamage(t, 0.8, 1.3))
	end,
}

-----------------------------------------------------------------------------
-- Cripple
-----------------------------------------------------------------------------
newTalent{
	name = "Stunning Blow",
	type = {"technique/2hweapon-cripple", 1},
	require = techs_req1,
	points = 5,
	random_ego = "attack",
	cooldown = 6,
	stamina = 8,
	requires_target = true,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Stunning Blow without a two-handed weapon!")
			return nil
		end

		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if math.floor(core.fov.distance(self.x, self.y, x, y)) > 1 then return nil end
		local speed, hit = self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 1, 1.5))

		-- Try to stun !
		if hit then
			if target:checkHit(self:combatAttackStr(weapon.combat), target:combatPhysicalResist(), 0, 95, 5 - self:getTalentLevel(t) / 2) and target:canBe("stun") then
				target:setEffect(target.EFF_STUNNED, 2 + self:getTalentLevel(t), {})
			else
				game.logSeen(target, "%s resists the stunning blow!", target.name:capitalize())
			end
		end

		return true
	end,
	info = function(self, t)
		return ([[Hits the target with your weapon doing %d%% damage. If the attack hits, the target is stunned for %d turns.
		Stun chance increase with your Strength stat.]])
		:format(100 * self:combatTalentWeaponDamage(t, 1, 1.5),
		2 + self:getTalentLevel(t))
	end,
}

newTalent{
	name = "Sunder Armour",
	type = {"technique/2hweapon-cripple", 2},
	require = techs_req2,
	points = 5,
	random_ego = "attack",
	cooldown = 6,
	stamina = 12,
	requires_target = true,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Sunder Armour without a two-handed weapon!")
			return nil
		end

		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if math.floor(core.fov.distance(self.x, self.y, x, y)) > 1 then return nil end
		local speed, hit = self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 1, 1.5))

		-- Try to stun !
		if hit then
			if target:checkHit(self:combatAttackStr(weapon.combat), target:combatPhysicalResist(), 0, 95, 10 - self:getTalentLevel(t) / 2) and target:canBe("stun") then
				target:setEffect(target.EFF_SUNDER_ARMOUR, 4 + self:getTalentLevel(t), {power=5*self:getTalentLevel(t)})
			else
				game.logSeen(target, "%s resists the sundering!", target.name:capitalize())
			end
		end

		return true
	end,
	info = function(self, t)
		return ([[Hits the target with your weapon doing %d%% damage. If the attack hits, the target's armour is reduced by %d for %d turns.
		Armor reduction chance increase with your Strength stat.]])
		:format(100 * self:combatTalentWeaponDamage(t, 1, 1.5), 
		5*self:getTalentLevel(t),
		4 + self:getTalentLevel(t))
	end,
}

newTalent{
	name = "Sunder Arms",
	type = {"technique/2hweapon-cripple", 3},
	require = techs_req3,
	points = 5,
	random_ego = "attack",
	cooldown = 6,
	stamina = 12,
	requires_target = true,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Sunder Arms without a two-handed weapon!")
			return nil
		end

		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if math.floor(core.fov.distance(self.x, self.y, x, y)) > 1 then return nil end
		local speed, hit = self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 1, 1.5))

		-- Try to stun !
		if hit then
			if target:checkHit(self:combatAttackStr(weapon.combat), target:combatPhysicalResist(), 0, 95, 10 - self:getTalentLevel(t) / 2) and target:canBe("stun") then
				target:setEffect(target.EFF_SUNDER_ARMS, 4 + self:getTalentLevel(t), {power=3*self:getTalentLevel(t)})
			else
				game.logSeen(target, "%s resists the sundering!", target.name:capitalize())
			end
		end

		return true
	end,
	info = function(self, t)
		return ([[Hits the target with your weapon doing %d%% damage. If the attack hits, the target's attack power is reduced by %d for %d turns.
		Attack power reduction chance increase with your Strength stat.]])
		:format(100 * self:combatTalentWeaponDamage(t, 1, 1.5), 
		3*self:getTalentLevel(t),
		4 + self:getTalentLevel(t))
	end,
}

newTalent{
	name = "Blood Frenzy",
	type = {"technique/2hweapon-cripple", 4},
	require = techs_req4,
	points = 5,
	mode = "sustained",
	cooldown = 15,
	sustain_stamina = 100,
	do_turn = function(self, t)
		if self.blood_frenzy > 0 then
			self.blood_frenzy = self.blood_frenzy - 2
		end
	end,
	activate = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Blood Frenzy without a two-handed weapon!")
			return nil
		end
		self.blood_frenzy = 0
		return {
			regen = self:addTemporaryValue("stamina_regen", -4),
		}
	end,
	deactivate = function(self, t, p)
		self.blood_frenzy = nil
		self:removeTemporaryValue("stamina_regen", p.regen)
		return true
	end,
	info = function(self, t)
		return ([[Enter a blood frenzy, draining stamina quickly(-4 stamina/turn). Each time you kill a foe while in blood frenzy you gain a cumulative bonus to weapon power of %d.
		Each turn the bonus decreases by 2.]]):format(2 * self:getTalentLevel(t))
	end,
}
