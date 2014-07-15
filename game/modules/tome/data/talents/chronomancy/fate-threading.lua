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

-- EDGE TODO: Particles, Timed Effect Particles

newTalent{
	name = "Disentangle",
	type = {"chronomancy/fate-threading", 1},
	require = chrono_req1,
	points = 5,
	cooldown = 12,
	tactical = { PARADOX = 2 },
	getReduction = function(self, t) return self:combatTalentSpellDamage(t, 20, 80, getParadoxSpellpower(self, t)) end,
	getParadoxMulti = function(self, t) return self:combatTalentLimit(t, 2, 0.10, .75) end,
	anomaly_type = "no-major",
	no_energy = true,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "anomaly_paradox_recovery", t.getParadoxMulti(self, t))
	end,
	action = function(self, t)
		local reduction = self:spellCrit(t.getReduction(self, t))
		self:paradoxDoAnomaly(reduction, t.anomaly_type, "forced")
		return true
	end,
	info = function(self, t)
		local reduction = t.getReduction(self, t)
		local paradox = 100 * t.getParadoxMulti(self, t)
		return ([[Disentangle the timeline, reducing your Paradox by %d and creating an anomaly.  This spell will never produce a major anomaly.
		Additionally you recover %d%% more Paradox from random anomalies (%d%% total).
		The Paradox reduction will increase with your Spellpower.]]):format(reduction, paradox, paradox + 200)
	end,
}

newTalent{
	name = "Preserve Pattern",
	type = {"chronomancy/fate-threading", 2},
	require = chrono_req2,
	mode = "sustained", 
	sustain_paradox = 0,
	points = 5,
	cooldown = 10,
	tactical = { DEFEND = 2 },
	getPercent = function(self, t) return self:combatTalentLimit(t, 50, 10, 30)/100 end, -- Limit < 50%
	getDuration = function(self, t) return getExtensionModifier(self, t, math.floor(self:combatTalentScale(t, 3, 6))) end,
	getConversionRatio = function(self, t) return 200 / self:combatTalentSpellDamage(t, 60, 600) end,
	damage_feedback = function(self, t, p, src)
		if p.particle and p.particle._shader and p.particle._shader.shad and src and src.x and src.y then
			local r = -rng.float(0.2, 0.4)
			local a = math.atan2(src.y - self.y, src.x - self.x)
			p.particle._shader:setUniform("impact", {math.cos(a) * r, math.sin(a) * r})
			p.particle._shader:setUniform("impact_tick", core.game.getTime())
		end
	end,
	iconOverlay = function(self, t, p)
		local val = p.rest_count or 0
		if val <= 0 then return "" end
		local fnt = "buff_font"
		return tostring(math.ceil(val)), fnt
	end,
	doPerservePattern = function(self, t, src, dam)
		local absorb = dam * t.getPercent(self, t)
		local paradox = absorb*t.getConversionRatio(self, t)
		self:setEffect(self.EFF_PRESERVE_PATTERN, t.getDuration(self, t), {paradox=paradox/t.getDuration(self, t), no_ct_effect=true})
		game:delayedLogMessage(self, nil,  "preserve pattern", "#LIGHT_BLUE##Source# converts damage to paradox!")
		game:delayedLogDamage(src, self, 0, ("#LIGHT_BLUE#(%d converted)#LAST#"):format(absorb), false)
		dam = dam - absorb
		
		return dam
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/arcane")

		local particle
		if core.shader.active(4) then
			particle = self:addParticles(Particles.new("shader_shield", 1, {size_factor=1.4, img="runicshield"}, {type="runicshield", shieldIntensity=0.14, ellipsoidalFactor=1, scrollingSpeed=-1, time_factor=12000, bubbleColor={1, 0.5, 0.3, 0.2}, auraColor={1, 0.5, 0.3, 1}}))
		else
			particle = self:addParticles(Particles.new("time_shield", 1))
		end

		return {
			particle = particle,
		}
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		return true
	end,
	info = function(self, t)
		local ratio = t.getPercent(self, t) * 100
		local absorb = t.getConversionRatio(self, t) * 100
		local duration = t.getDuration(self, t)
		return ([[While active, %d%% of all damage you take increases your Paradox by %d%% of the damage absorbed over %d turns.
		The amount of Paradox damage you recieve will be reduced by your Spellpower.]]):
		format(ratio, absorb, duration)
	end,
}

newTalent{
	name = "Trim Threads",
	type = {"chronomancy/fate-threading", 3},
	require = chrono_req3,
	points = 5,
	cooldown = 4,
	tactical = { ATTACKAREA = { TEMPORAL = 2 } },
	range = 10,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 1, 2)) end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 25, 290, getParadoxSpellpower(self, t)) end,
	getDuration = function(self, t) return getExtensionModifier(self, t, 4) end,
	getReduction = function(self, t) return self:getTalentLevel(t) * 2 end,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false, nowarning=true, talent=t}
	end,
	requires_target = true,
	direct_hit = true,
	doAnomaly = function(self, t, target, eff)
		self:project({type=hit}, target.x, target.y, DamageType.TEMPORAL, eff.power * eff.dur)
		target:removeEffect(target.EFF_TRIM_THREADS)
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		
		local damage = self:spellCrit(t.getDamage(self, t))
		self:project(tg, x, y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if not target then return end
			target:setEffect(target.EFF_TRIM_THREADS, t.getDuration(self, t), {power=damage/4, src=self, reduction=t.getReduction(self, t), apply_power=getParadoxSpellpower(self, t)})
		end)

		game.level.map:particleEmitter(x, y, tg.radius, "temporal_flash", {radius=tg.radius})

		game:playSoundNear(self, "talents/tidalwave")

		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local duration = t.getDuration(self, t)
		local radius = self:getTalentRadius(t)
		local reduction = t.getReduction(self, t)
		return ([[Deals %0.2f temporal damage over %d turns to all other targets in a radius of %d.  If the target is slain before the effect expires you'll recover %d Paradox.
		If the target is hit by an Anomaly the remaining damage will be done instantly.
		The damage will scale with your Spellpower.]]):format(damDesc(self, DamageType.TEMPORAL, damage), duration, radius, reduction)
	end,
}

newTalent{
	name = "Bias Weave",
	type = {"chronomancy/fate-threading", 4},
	require = chrono_req4,
	points = 5,
	cooldown = 10,
	-- Anomaly biases can be set manually for monsters
	-- Use the following format anomaly_bias = { type = "teleport", chance=50}
	no_npc_use = true,  -- so rares don't learn useless talents
	allow_temporal_clones = true,  -- let clones copy it anyway so they can benefit from the effects
	on_pre_use = function(self, t, silent) if self ~= game.player then return false end return true end,  -- but don't let them cast it
	getBiasChance = function(self, t) return self:combatTalentLimit(t, 100, 10, 75) end,
	getTargetChance = function(self, t) return self:combatTalentLimit(t, 100, 10, 75) end,
	getAnomalySpeed = function(self, t) return self:combatTalentLimit(t, 1, 0.10, .75) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "anomaly_recovery_speed", t.getAnomalySpeed(self, t))
	end,
	on_learn = function(self, t)
		if self.anomaly_bias and self.anomaly_bias.chance then
			self.anomaly_bias.chance = t.getBiasChance(self, t)
		end
	end,
 	on_unlearn = function(self, t)
		if self:getTalentLevel(t) == 0 then
			self.anomaly_bias = nil
		elseif self.anomaly_bias and self.anomaly_bias.chance then
			self.anomaly_bias.chance = t.getBiasChance(self, t)
		end
 	end,
	action = function(self, t)
		local state = {}
		local Chat = require("engine.Chat")
		local chat = Chat.new("chronomancy-bias-weave", {name="Bias Weave"}, self, {version=self, state=state})
		local d = chat:invoke()
		local co = coroutine.running()
		d.unload = function() coroutine.resume(co, state.set_bias) end
		if not coroutine.yield() then return nil end
		return true
	end,
	info = function(self, t)
		local target_chance = t.getTargetChance(self, t)
		local bias_chance = t.getBiasChance(self, t)
		local anomaly_recovery = (1 - t.getAnomalySpeed(self, t)) * 100
		return ([[You've learned to focus most anomalies when they occur and may choose the target area with %d%% probability.
		You also may bias the type of anomaly effects you produce with %d%% probability.
		Additionally random anomalies only cost you %d%% of a turn rather than a full turn when they occur.
		Major anomalies, those occuring when your modified Paradox is over 600, are not affected by this talent.]]):format(target_chance, bias_chance, anomaly_recovery)
	end,
}