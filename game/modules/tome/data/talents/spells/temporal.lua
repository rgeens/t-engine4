newTalent{
	name = "Time Prison",
	type = {"spell/temporal", 1},
	require = spells_req1,
	points = 5,
	mana = 30,
	cooldown = 30,
	tactical = {
		DEFENSE = 10,
	},
	range = 20,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, DamageType.TIME_PRISON, 4 + self:combatSpellpower(0.03) * self:getTalentLevel(t), {type="manathrust"})
		return true
	end,
	info = function(self, t)
		return ([[Removes the target from the flow of time for %d turns. In this state the target cannot act nor be harmed.
		The duration will increase with the Magic stat]]):format(4 + self:combatSpellpower(0.03) * self:getTalentLevel(t))
	end,
}

newTalent{
	name = "Congeal Time",
	type = {"spell/temporal",2},
	require = spells_req2,
	points = 5,
	mana = 20,
	cooldown = 30,
	tactical = {
		BUFF = 10,
	},
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, DamageType.SLOW, util.bound((self:combatSpellpower(25) * self:getTalentLevel(t)) / 100, 0.1, 0.4), {type="manathrust"})
		return true
	end,
	info = function(self, t)
		return ([[Decreases the target global speed by %.2f for 7 turns.
		The speed decreases with the Magic stat]]):format(util.bound((self:combatSpellpower(25) * self:getTalentLevel(t)) / 100, 0.1, 0.4))
	end,
}

newTalent{
	name = "Essence of Speed",
	type = {"spell/temporal",3},
	require = spells_req3,
	points = 5,
	mode = "sustained",
	sustain_mana = 450,
	cooldown = 30,
	tactical = {
		BUFF = 10,
	},
	activate = function(self, t)
		local power = util.bound((self:combatSpellpower(50) * self:getTalentLevel(t)) / 100, 0.1, 2)
		return {
			speed = self:addTemporaryValue("energy", {mod=power}),
		}
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("energy", p.speed)
		return true
	end,
	info = function(self, t)
		return ([[Increases the caster global speed by %.2f.
		The speed increases with the Magic stat]]):format(util.bound((self:combatSpellpower(50) * self:getTalentLevel(t)) / 100, 0.1, 2))
	end,
}

newTalent{
	name = "Time Shield",
	type = {"spell/temporal", 4},
	require = spells_req4,
	points = 5,
	mana = 150,
	cooldown = 200,
	tactical = {
		DEFENSE = 10,
	},
	range = 20,
	action = function(self, t)
		print("IMPLEMENT ME �!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		return true
	end,
	info = function(self, t)
		return ([[This intricate spell erects time shield around the caster, preventing any incomming damage and sending it forward in time.
		Once the maximun damage (%d) is absorbed or the time runs out (%d turns) the stored damage will come back as a damage over time.
		The duration and max absorption will increase with the Magic stat]]):format(4 + self:combatSpellpower(0.03) * self:getTalentLevel(t), 1)
	end,
}
