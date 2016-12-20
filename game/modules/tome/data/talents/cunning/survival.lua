-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2016 Nicolas Casalini
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
	name = "Heightened Senses",
	type = {"cunning/survival", 1},
	require = cuns_req1,
	mode = "passive",
	points = 5,
	sense = function(self, t) return math.floor(self:combatTalentScale(t, 5, 9)) end,
	seePower = function(self, t) return self:combatScale(self:getCun(15, true)*self:getTalentLevel(t), 5, 0, 80, 75) end, --I5
	getResists = function(self, t) return self:combatTalentLimit(t, 40, 5, 25) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "heightened_senses", t.sense(self, t))
		self:talentTemporaryValue(p, "see_invisible", t.seePower(self, t))
		self:talentTemporaryValue(p, "see_stealth", t.seePower(self, t))
		if self:getTalentLevel(t) >= 3 then
			self:talentTemporaryValue(p, "resist_unseen", t.getResists(self, t))
		end
	end,
	info = function(self, t)
		return ([[You notice the small things others do not notice, allowing you to "see" creatures in a %d radius even outside of light radius.
		This is not telepathy, however, and it is still limited to line of sight.
		Also, your attention to detail increases stealth detection and invisibility detection by %d.
		At level 3, you are able to react quickly to stealthed and invisible enemies attacking you, reducing the damage they deal by %d%%.
		The detection power improves with your Cunning.]]):
		format(t.sense(self,t), t.seePower(self,t), t.getResists(self,t))
	end,
}

newTalent{
	name = "Track",
	type = {"cunning/survival", 2},
	require = cuns_req2,
	points = 5,
	random_ego = "utility",
	cooldown = 20,
	radius = function(self, t) return math.floor(self:combatScale(self:getCun(10, true) * self:getTalentLevel(t), 5, 0, 55, 50)) end,
	no_npc_use = true,
	action = function(self, t)
		local rad = self:getTalentRadius(t)
		self:setEffect(self.EFF_SENSE, 3 + self:getTalentLevel(t), {
			range = rad,
			actor = 1,
		})
		return true
	end,
	info = function(self, t)
		local rad = self:getTalentRadius(t)
		return ([[Sense foes around you in a radius of %d for %d turns.
		The radius will increase with your Cunning.]]):format(rad, 3 + self:getTalentLevel(t))
	end,
}

newTalent{
	name = "Device Mastery",
	type = {"cunning/survival", 3},
	require = cuns_req3,
	mode = "passive",
	points = 5,
	cdReduc = function(tl)
		if tl <=0 then return 0 end
		return math.floor(100*tl/(tl+7.5)) -- Limit < 100%
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "use_object_cooldown_reduce", t.cdReduc(self:getTalentLevel(t)))
	end,
	on_learn = function(self, t)
		if not self:knowTalent(self.T_DISARM_TRAP) then
			self:learnTalent(self.T_DISARM_TRAP, true, 1)
		end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevel(t) < 1 and self:knowTalent(self.T_DISARM_TRAP) then
			self:unlearnTalent(self.T_DISARM_TRAP, 1)
		end
	end,
	trapPower = function(self, t) return self:combatScale(self:getTalentLevel(t) * self:getCun(25, true), 0, 0, 125, 125) end,
	info = function(self, t)
		return ([[Your cunning manipulations allow you to use charms (wands, totems and torques) more efficiently, reducing their cooldowns and the power cost of all usable items by %d%%.
In addition, your knowledge of devices allows you to detect traps around you and disarm known traps (%d detection and disarm 'power').
The trap detection and disarming ability improves with your Cunning. ]]):
		format(t.cdReduc(self:getTalentLevel(t)), t.trapPower(self,t)) --I5
	end,
}

newTalent{
	name = "Danger Sense",
	type = {"cunning/survival", 4},
	require = cuns_req4,
	points = 5,
	mode = "passive",
	getTrigger = function(self, t) return self:combatTalentScale(t, 0.15, 0.40, 0.5) end,
	cooldown = function(self, t) return 30 end,
	no_npc_use = true,
	getReduction = function(self, t)
		return self:combatTalentLimit(t, 75, 25, 65)
	end,
	callbackOnHit = function(self, t, cb, src)
		if self.life > self.max_life*t.getTrigger(self,t) and self.life - cb.value <= self.max_life*t.getTrigger(self,t) and not self:isTalentCoolingDown(t) then
			self:setEffect("EFF_DANGER_SENSE", 1, {reduce = t.getReduction(self, t)})
			local eff = self:hasEffect("EFF_DANGER_SENSE")
			eff.dur = eff.dur - 1
			cb.value = cb.value * (100-t.getReduction(self, t)) / 100
			self:startTalentCooldown(t)
		end
		return cb.value
	end,
	info = function(self, t)
		return ([[You react quickly when in danger - on falling below %d%% life, all damage you take from the attack and all further damage that turn is reduced by %d%%.
This talent has a cooldown.]]):
		format(t.getTrigger(self,t)*100, t.getReduction(self,t) )
	end,
}

newTalent{
	name = "Disarm Trap",
	type = {"base/class", 1},
	no_npc_use = true,
	innate = true,
	points = 1,
	range = 1,
	message = false,
	image = "talents/trap_priming.png",
	target = {type="hit", range=1, nowarning=true, immediate_keys=true, no_lock=false},
	action = function(self, t)
		if self.player then
--			core.mouse.set(game.level.map:getTileToScreen(self.x, self.y, true))
			game.log("#CADET_BLUE#Disarm A Trap: (direction keys to select where to disarm, shift+direction keys to move freely)")
		end
		local tg = self:getTalentTarget(t)
		local x, y, dir = self:getTarget(tg)
		if not (x and y) then return end
		
		dir = util.getDir(x, y, self.x, self.y)
		x, y = util.coordAddDir(self.x, self.y, dir)
		print("Requesting disarm trap", self.name, t.id, x, y)
		local trap = self:detectTrap(nil, x, y)
		if trap then
			print("Found trap", trap.name, x, y)
			if (x == self.x and y == self.y) or self:canMove(x, y) then
				local px, py = self.x, self.y
				self:move(x, y, true) -- temporarily move to make sure trap can trigger properly
				trap:trigger(self.x, self.y, self) -- then attempt to disarm the trap, which may trigger it
				self:move(px, py, true)
			else
				game.logPlayer(self, "#CADET_BLUE#You cannot disarm traps in grids you cannot enter.")
			end
		else
			game.logPlayer(self, "#CADET_BLUE#You don't see a trap there.")
		end
		
		return true
	end,
	info = function(self, t)
		local ths = self:getTalentFromId(self.T_DEVICE_MASTERY)
		local power = ths.trapPower(self,ths)
		return ([[You search an adjacent grid for a hidden trap (%d detection 'power') and attempt to disarm it (%d disarm 'power').
		To disarm a trap, you must be able to enter its grid to manipulate it, even though you stay in your current location.
		Success depends on your skill in the %s talent and your Cunning, and failing to disarm a trap may trigger it.]]):format(power, power + (self:attr("disarm_bonus") or 0), ths.name)
	end,
}