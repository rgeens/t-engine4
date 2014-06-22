-- TE4 - T-Engine 4
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

require "engine.class"
local Base = require "engine.interface.ActorLife"

--- Handles actors life and death
module(..., package.seeall, class.inherit(Base))

local function oktodie(self, value, src, death_note)
	if self:knowTalent(self.T_CAUTERIZE) and self:triggerTalent(self.T_CAUTERIZE, nil, value) then
		return false, 0
	else
		if src.on_kill and src:on_kill(self) then return false, value end
		return self:die(src, death_note), value
	end
end

--- Remove some HP from an actor
-- If HP is reduced to 0 then remove from the level and call the die method.<br/>
-- When an actor dies its dead property is set to true, to wait until garbage collection deletes it
-- @return true/false if the actor died and the actual damage done
function _M:takeHit(value, src, death_note)
	if self.onTakeHit then value = self:onTakeHit(value, src, death_note) end
	if value <= 0 then return false, 0 end
	self.life = self.life - value
	self.changed = true
	if self.life <= self.die_at and not self.dead then
		if self:hasEffect(self.EFF_PRECOGNITION) then
			game.log("%s dies during precognition, ending the effect!", self.name:capitalize())
			self:removeEffect(self.EFF_PRECOGNITION)
			return false, 0
		end
		return oktodie(self, value, src, death_note)
	-- Allow double-death ONLY for npcs
	elseif self.life <= self.die_at and self.dead then
		if not game.party or not game.party:hasMember(self) then
			return oktodie(self, value, src, death_note)
		end
	end
	return false, value
end
