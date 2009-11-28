require "engine.class"
local DamageType = require "engine.DamageType"
local Map = require "engine.Map"
local Target = require "engine.Target"

--- Interface to add ToME combat system
module(..., package.seeall, class.make)

--- Checks what to do with the target
-- Talk ? attack ? displace ?
function _M:bumpInto(target)
	local reaction = self:reactionToward(target)
	if reaction < 0 then
		return self:attackTarget(target)
	elseif reaction >= 0 then
		-- Talk ?
		if self.player and target.can_talk then
			-- TODO: implement !
		elseif target.player and self.can_talk then
			-- TODO: implement! requet the player to talk
		else
			-- Displace
			game.level.map:remove(self.x, self.y, Map.ACTOR)
			game.level.map:remove(target.x, target.y, Map.ACTOR)
			game.level.map(self.x, self.y, Map.ACTOR, target)
			game.level.map(target.x, target.y, Map.ACTOR, self)
			self.x, self.y, target.x, target.y = target.x, target.y, self.x, self.y
		end
	end
end

--- Makes the death happen!
--[[
The ToME combat system has the following attributes:
- attack power: increases chances to hit against high defence
- defence: increases chances to miss against high attack power
- armor: direct reduction of damage done
- armor penetration: reduction of target's armor
- damage: raw damage done
]]
function _M:attackTarget(target)
	local sc = self.combat
	local tc = target.combat

	if not sc then sc = {dam=0, atk=0, apr=0, def=0, armor=0} end
	if not tc then tc = {dam=0, atk=0, apr=0, def=0, armor=0} end

	-- Does the blow connect?
	local hit = rng.avg(sc.atk * 2 / 3, sc.atk) - tc.def
	-- If hit is over 0 it connects, if it is 0 we still have 50% chance
	if hit > 0 or (hit == 0 and rng.percent(50)) then
		local dam = rng.avg(sc.dam * 2 / 3, sc.dam) - math.max(0, tc.armor - sc.apr)
		if dam < 0 then dam = 0 end
		game.logSeen(target, "%s hits %s for #aaaaaa#%0.2f physical damage#ffffff#.", self.name:capitalize(), target.name, dam)
		target:takeHit(dam, self)
	else
		game.logSeen(target, "%s misses %s.", self.name:capitalize(), target.name)
	end
end

--- Project damage to a distance
function _M:project(t, x, y, damtype, dam)
	if dam < 0 then return end
	local typ = Target:getType(t)

	local lx, ly = x, y
	if typ.stop_block then
		local l = line.new(self.x, self.y, x, y)
		lx, ly = l()
		while lx and ly do
			if typ.stop_block and game.level.map:checkAllEntities(lx, ly, "block_move") then break end
			if typ.range and math.sqrt((self.source_actor.x-lx)^2 + (self.source_actor.y-ly)^2) > typ.range then break end

			-- Deam damage: beam
			if typ.line then DamageType:get(damtype).projector(self, lx, ly, damtype, dam) end

			lx, ly = l()
		end
	end

	if typ.ball then
		core.fov.calc_circle(lx, ly, typ.ball, function(self, px, py)
			-- Deam damage: ball
			DamageType:get(damtype).projector(self, px, py, damtype, dam)
--			self.sg:toScreen(self.display_x + (lx - game.level.map.mx) * self.tile_w, self.display_y + (ly - game.level.map.my) * self.tile_h)
		end, function()end, self)
		DamageType:get(damtype).projector(self, lx, ly, damtype, dam)
	elseif typ.cone then
	else
		-- Deam damage: single
		DamageType:get(damtype).projector(self, lx, ly, damtype, dam)
	end
end
