require "engine.class"
module(..., package.seeall, class.make)

function _M:init(level, map)
	self.level = level
	self.map = map
	self.entities = {}
end

function _M:addEntity(e)
	if self.entities[e.uid] then error("Entity "..e.uid.." already present on the level") end
	self.entities[e.uid] = e
end
