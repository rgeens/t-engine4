require "engine.class"
require "engine.GameTurnBased"
require "engine.KeyCommand"
local Savefile = require "engine.Savefile"
local DamageType = require "engine.DamageType"
local Zone = require "engine.Zone"
local Map = require "engine.Map"
local Target = require "engine.Target"
local Level = require "engine.Level"
local Birther = require "engine.Birther"

local Grid = require "engine.Grid"
local Actor = require "mod.class.Actor"
local ActorStats = require "engine.interface.ActorStats"
local ActorResource = require "engine.interface.ActorResource"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorAI = require "engine.interface.ActorAI"
local Player = require "mod.class.Player"
local NPC = require "mod.class.NPC"

local PlayerDisplay = require "mod.class.PlayerDisplay"
local TalentsDisplay = require "mod.class.TalentsDisplay"

local LogDisplay = require "engine.LogDisplay"
local DebugConsole = require "engine.DebugConsole"
local FlyingText = require "engine.FlyingText"
local Tooltip = require "engine.Tooltip"
local Calendar = require "engine.Calendar"

local QuitDialog = require "mod.dialogs.Quit"
local LevelupStatsDialog = require "mod.dialogs.LevelupStatsDialog"
local LevelupTalentsDialog = require "mod.dialogs.LevelupTalentsDialog"

module(..., package.seeall, class.inherit(engine.GameTurnBased))

collectgarbage("stop")

function _M:init()
	engine.GameTurnBased.init(self, engine.KeyCommand.new(), 1000, 100)

	-- Same init as when loaded from a savefile
	self:loaded()
end

function _M:run()
	self.log = LogDisplay.new(0, self.h * 0.8, self.w * 0.5, self.h * 0.2, nil, nil, nil, {255,255,255}, {30,30,30})
	self.player_display = PlayerDisplay.new(0, 0, self.w * 0.2, self.h * 0.8, {30,30,0})
	self.talents_display = TalentsDisplay.new(self.w * 0.5, self.h * 0.8, self.w * 0.5, self.h * 0.2, {30,30,0})
	self.calendar = Calendar.new("/data/calendar_rivendell.lua", "Today is the %s %s of the %s year of the Fourth Age of Middle-earth.\nThe time is %02d:%02d.", 122)
	self.tooltip = Tooltip.new(nil, nil, {255,255,255}, {30,30,30})
	self.flyers = FlyingText.new()
	self:setFlyingText(self.flyers)

	self.log("Welcome to #00FF00#Tales of Middle Earth!")
	self.logSeen = function(e, ...) if e and self.level.map.seens(e.x, e.y) then self.log(...) end end
	self.logPlayer = function(e, ...) if e == game.player then self.log(...) end end

	-- Setup inputs
	self:setupCommands()
	self:setupMouse()

	-- Starting from here we create a new game
	if not self.player then self:newGame() end

	self.target = Target.new(Map, self.player)
	self.target.target.entity = self.player
	self.old_tmx, self.old_tmy = 0, 0

	-- Ok everything is good to go, activate the game in the engine!
	self:setCurrent()
end

function _M:newGame()
	self.zone = Zone.new("wilderness")
	self.player = Player.new{name=self.player_name}

	local birth = Birther.new(self.player, {"base", "race", "subrace", "sex", "class", "subclass" }, function()
		self.player.wild_x, self.player.wild_y = 10, 10
		self:changeLevel(1)

		local ds = LevelupStatsDialog.new(self.player)
		self:registerDialog(ds)
	end)
	self:registerDialog(birth)
end

function _M:loaded()
	Zone:setup{npc_class="mod.class.NPC", grid_class="mod.class.Grid", object_class="mod.class.Object"}
	Map:setViewPort(self.w * 0.2, 0, self.w * 0.8, math.floor(self.h * 0.80), 16, 16)
	engine.GameTurnBased.loaded(self)
	self.key = engine.KeyCommand.new()
end

function _M:save()
	return class.save(self, {w=true, h=true, zone=true, player=true, level=true,
		energy_to_act=true, energy_per_tick=true, turn=true, paused=true, save_name=true,
	}, true)
end

function _M:getSaveDescription()
	return {
		name = self.player.name,
		description = [[Strolling in the old places of the world!]],
	}
end

function _M:changeLevel(lev, zone)
	if zone then
		self.zone = Zone.new(zone)
	end
	self.zone:getLevel(self, lev, (self.level and not zone) and self.level.level or -1000)

	-- Move back to old wilderness position
	if self.zone.short_name == "wilderness" then
		self.player:move(self.player.wild_x, self.player.wild_y, true)
	else
		self.player:move(self.level.start.x, self.level.start.y, true)
	end
	self.level:addEntity(self.player)
end

function _M:getPlayer()
	return self.player
end

function _M:tick()
	if self.level then
		if self.target.target.entity and not self.level:hasEntity(self.target.target.entity) then self.target.target.entity = false end

		engine.GameTurnBased.tick(self)
		-- Fun stuff: this can make the game realtime, although callit it in display() will make it work better
		-- (since display is on a set FPS while tick() ticks as much as possible
		-- engine.GameEnergyBased.tick(self)
	end
end

--- Called every game turns
-- Does nothing, you can override it
function _M:onTurn()
	-- The following happens only every 10 game turns (once for every turn of 1 mod speed actors)
	if self.turn % 10 ~= 0 then return end

	-- Process overlay effects
	self.level.map:processEffects()

	if not self.day_of_year or self.day_of_year ~= self.calendar:getDayOfYear(self.turn) then
		self.log(self.calendar:getTimeDate(self.turn))
		self.day_of_year = self.calendar:getDayOfYear(self.turn)
	end
end

function _M:display()
	self.log:display():toScreen(self.log.display_x, self.log.display_y)
	self.player_display:display():toScreen(self.player_display.display_x, self.player_display.display_y)
	self.talents_display:display():toScreen(self.talents_display.display_x, self.talents_display.display_y)

	if self.level and self.level.map then
		-- Display the map and compute FOV for the player if needed
		if self.level.map.changed then
			self.level.map:fov(self.player.x, self.player.y, 20)
			self.level.map:fovLite(self.player.x, self.player.y, 4)
		end
		self.level.map:display()

		-- Display the targetting system if active
		self.target:display()

		-- Display a tooltip if available
		local mx, my = core.mouse.get()
		local tmx, tmy = self.level.map:getMouseTile(mx, my)
		local tt = self.level.map:checkAllEntities(tmx, tmy, "tooltip")
		if tt then
			self.tooltip:set(tt)
			local t = self.tooltip:display()
			mx = mx - self.tooltip.w
			my = my - self.tooltip.h
			if mx < 0 then mx = 0 end
			if my < 0 then my = 0 end
			if t then t:toScreen(mx, my) end
		end
		if self.old_tmx ~= tmx or self.old_tmy ~= tmy then
			self.target.target.x, self.target.target.y = tmx, tmy
		end
		self.old_tmx, self.old_tmy = tmx, tmy
	end

	engine.GameTurnBased.display(self)
end

function _M:targetMode(v, msg, co, typ)
	if not v then
		Map:setViewerFaction(nil)
		if msg then self.log(type(msg) == "string" and msg or "Tactical display disabled. Press 't' or right mouse click to enable.") end
		self.level.map.changed = true
		self.target:setActive(false)

		if tostring(self.target_mode) == "exclusive" then
			self.key = self.normal_key
			self.key:setCurrent()
			if self.target_co then
				local co = self.target_co
				self.target_co = nil
				local ok, err = coroutine.resume(co, self.target.target.x, self.target.target.y)
				if not ok and err then error(err) end
			end
		end
	else
		Map:setViewerFaction("players")
		if msg then self.log(type(msg) == "string" and msg or "Tactical display enabled. Press 't' to disable.") end
		self.level.map.changed = true
		self.target:setActive(true, typ)

		-- Exclusive mode means we disable the current key handler and use a specific one
		-- that only allows targetting and resumes talent coroutine when done
		if tostring(v) == "exclusive" then
			self.target_co = co
			self.key = self.targetmode_key
			self.key:setCurrent()

			if self.target.target.entity and self.level.map.seens(self.target.target.entity.x, self.target.target.entity.y) and self.player ~= self.target.target.entity then
			else
				self.target:scan(5, nil, self.player.x, self.player.y)
			end
		end
	end
	self.target_mode = v
end

function _M:setupCommands()
	self.targetmode_key = engine.KeyCommand.new()
	self.targetmode_key:addCommands
	{
		_t = function()
			self:targetMode(false, false)
		end,
		_RETURN = {"alias", "_t"},
		_ESCAPE = function()
			self.target.target.entity = nil
			self.target.target.x = nil
			self.target.target.y = nil
			self:targetMode(false, false)
		end,
		-- Targeting movement
		[{"_LEFT","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 end,
		[{"_RIGHT","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 end,
		[{"_UP","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y - 1 end,
		[{"_DOWN","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y + 1 end,
		[{"_KP4","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 end,
		[{"_KP6","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 end,
		[{"_KP8","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y - 1 end,
		[{"_KP2","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y + 1 end,
		[{"_KP1","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 self.target.target.y = self.target.target.y + 1 end,
		[{"_KP3","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 self.target.target.y = self.target.target.y + 1 end,
		[{"_KP7","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 self.target.target.y = self.target.target.y - 1 end,
		[{"_KP9","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 self.target.target.y = self.target.target.y - 1 end,

		_LEFT = function() self.target:scan(4) end,
		_RIGHT = function() self.target:scan(6) end,
		_UP = function() self.target:scan(8) end,
		_DOWN = function() self.target:scan(2) end,
		_KP4 = function() self.target:scan(4) end,
		_KP6 = function() self.target:scan(6) end,
		_KP8 = function() self.target:scan(8) end,
		_KP2 = function() self.target:scan(2) end,
		_KP1 = function() self.target:scan(1) end,
		_KP3 = function() self.target:scan(3) end,
		_KP7 = function() self.target:scan(7) end,
		_KP9 = function() self.target:scan(9) end,
	}

	self.normal_key = self.key
	-- Load the locales
	self.key:loadLocaleConvertion("/data/locales/number_hotkey.lua")
	-- Activate profiler keybinds
	self.key:setupProfiler()
	self.key:addCommands
	{
		_1 = function() self.player:activateHotkey(1) end,
		_2 = function() self.player:activateHotkey(2) end,
		_3 = function() self.player:activateHotkey(3) end,
		_4 = function() self.player:activateHotkey(4) end,
		_5 = function() self.player:activateHotkey(5) end,
		_6 = function() self.player:activateHotkey(6) end,
		_7 = function() self.player:activateHotkey(7) end,
		_8 = function() self.player:activateHotkey(8) end,
		_9 = function() self.player:activateHotkey(9) end,
		_0 = function() self.player:activateHotkey(10) end,
		_RIGHTPAREN = function() self.player:activateHotkey(11) end,
		_EQUALS = function() self.player:activateHotkey(12) end,

		-- talent use
		_m = function()
			self.player:useTalents()
		end,

		-- Pickup object
		_g = function()
			self.player:pickupFloor(1, true)
		end,

		-- Show inventory
		_i = function()
			self.player:showInventory(nil, self.player:getInven(self.player.INVEN_INVEN), nil, function() end)
		end,
		-- Show equipment
		_e = function()
			self.player:showEquipment(nil, nil, function() end)
		end,
		-- Drop item
		_d = function()
			local inven = self.player:getInven(self.player.INVEN_INVEN)
			self.player:showInventory("Drop object", inven, nil, function(o, item)
				self.player:dropFloor(inven, item)
			end)
		end,
		-- Wear item
		_w = function()
			local inven = self.player:getInven(self.player.INVEN_INVEN)
			self.player:showInventory("Wield/wear object", inven, function(o)
				return o:wornInven() and true or false
			end, function(o, item)
				local ro = self.player:wearObject(o, true, true)
				if ro then
					if type(ro) == "table" then self.player:addObject(self.player.INVEN_INVEN, ro) end
					self.player:removeObject(self.player.INVEN_INVEN, item)
				end
			end)
		end,
		-- Takeoff item
		_t = function()
			self.player:showEquipment("Take off object", nil, function(o, inven, item)
				if self.player:takeoffObject(inven, item) then
					self.player:addObject(self.player.INVEN_INVEN, o)
				end
			end)
		end,

		[{"_g","shift"}] = function()
			local none = true
			if self.player.unused_stats > 0 then
				local ds = LevelupStatsDialog.new(self.player)
				self:registerDialog(ds)
				none = false
			elseif self.player.unused_talents > 0 or self.player.unused_talents_types > 0 then
				local dt = LevelupTalentsDialog.new(self.player)
				self:registerDialog(dt)
				none = false
			end
			if none then
				engine.Dialog:simplePopup("Nothing to level", "You character has no stat or talent points to spend. Levelup and try again.")
			end
		end,

		_LEFT  = function() self.player:move(self.player.x - 1, self.player.y    ) end,
		_RIGHT = function() self.player:move(self.player.x + 1, self.player.y    ) end,
		_UP    = function() self.player:move(self.player.x    , self.player.y - 1) end,
		_DOWN  = function() self.player:move(self.player.x    , self.player.y + 1) end,
		_KP1   = function() self.player:move(self.player.x - 1, self.player.y + 1) end,
		_KP2   = function() self.player:move(self.player.x    , self.player.y + 1) end,
		_KP3   = function() self.player:move(self.player.x + 1, self.player.y + 1) end,
		_KP4   = function() self.player:move(self.player.x - 1, self.player.y    ) end,
		_KP5   = function() self.player:move(self.player.x    , self.player.y    ) end,
		_KP6   = function() self.player:move(self.player.x + 1, self.player.y    ) end,
		_KP7   = function() self.player:move(self.player.x - 1, self.player.y - 1) end,
		_KP8   = function() self.player:move(self.player.x    , self.player.y - 1) end,
		_KP9   = function() self.player:move(self.player.x + 1, self.player.y - 1) end,

		[{"_LESS","anymod"}] = function()
			local e = self.level.map(self.player.x, self.player.y, Map.TERRAIN)
			if self.player:enoughEnergy() and e.change_level then
				-- Do not unpause, the player is allowed first move on next level
				self:changeLevel(e.change_zone and e.change_level or self.level.level + e.change_level, e.change_zone)
			else
				self.log("There is no way out of this level here.")
			end
		end,
		_GREATER = {"alias", "_LESS"},
		-- Toggle tactical displau
		[{"_t","shift"}] = function()
			if Map.view_faction then
				self:targetMode(false, true)
			else
				self:targetMode(true, true)
				-- Find nearest target
				self.target:scan(5)
			end
		end,
		-- Show time
		[{"_t","ctrl"}] = function()
			self.log(self.calendar:getTimeDate(self.turn))
		end,
		-- Exit the game
		[{"_x","ctrl"}] = function()
			self:onQuit()
		end,
		-- Lua console
		[{"_l","ctrl"}] = function()
			self:registerDialog(DebugConsole.new())
		end,

		-- Targeting movement
		[{"_LEFT","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 end,
		[{"_RIGHT","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 end,
		[{"_UP","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y - 1 end,
		[{"_DOWN","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y + 1 end,
		[{"_KP4","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 end,
		[{"_KP6","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 end,
		[{"_KP8","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y - 1 end,
		[{"_KP2","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y + 1 end,
		[{"_KP1","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 self.target.target.y = self.target.target.y + 1 end,
		[{"_KP3","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 self.target.target.y = self.target.target.y + 1 end,
		[{"_KP7","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 self.target.target.y = self.target.target.y - 1 end,
		[{"_KP9","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 self.target.target.y = self.target.target.y - 1 end,
		[{"_LEFT","ctrl"}] = function() self.target:scan(4) end,
		[{"_RIGHT","ctrl"}] = function() self.target:scan(6) end,
		[{"_UP","ctrl"}] = function() self.target:scan(8) end,
		[{"_DOWN","ctrl"}] = function() self.target:scan(2) end,
		[{"_KP4","ctrl"}] = function() self.target:scan(4) end,
		[{"_KP6","ctrl"}] = function() self.target:scan(6) end,
		[{"_KP8","ctrl"}] = function() self.target:scan(8) end,
		[{"_KP2","ctrl"}] = function() self.target:scan(2) end,
		[{"_KP1","ctrl"}] = function() self.target:scan(1) end,
		[{"_KP3","ctrl"}] = function() self.target:scan(3) end,
		[{"_KP7","ctrl"}] = function() self.target:scan(7) end,
		[{"_KP9","ctrl"}] = function() self.target:scan(9) end,

		-- Save the game
		[{"_s","ctrl"}] = function()
			local save = Savefile.new(self.save_name)
			save:saveGame(self)
			save:close()
			self.log("Saved game.")
		end,

	}
	self.key:setCurrent()
end

function _M:setupMouse()
	-- Those 2 locals will be "absorbed" into the mosue event handler function, this is a closure
	local derivx, derivy = 0, 0

	self.mouse:registerZone(Map.display_x, Map.display_y, Map.viewport.width, Map.viewport.height, function(button, mx, my, xrel, yrel)
		-- Target stuff
		if button == "right" then
			local tmx, tmy = self.level.map:getMouseTile(mx, my)

			local actor = self.level.map(tmx, tmy, Map.ACTOR)

			if actor and self.level.map.seens(tmx, tmy) then
				self.target.target.entity = actor
			else
				self.target.target.entity = nil
				self.target.target.x = tmx
				self.target.target.y = tmy
			end
			if tostring(self.target_mode) == "exclusive" then
				self:targetMode(false, false)
			else
				self:targetMode(true, true)
			end
		-- Move map around
		elseif button == "left" and xrel and yrel then
			derivx = derivx + xrel
			derivy = derivy + yrel
			game.level.map.changed = true
			if derivx >= game.level.map.tile_w then
				game.level.map.mx = game.level.map.mx - 1
				derivx = derivx - game.level.map.tile_w
			elseif derivx <= -game.level.map.tile_w then
				game.level.map.mx = game.level.map.mx + 1
				derivx = derivx + game.level.map.tile_w
			end
			if derivy >= game.level.map.tile_h then
				game.level.map.my = game.level.map.my - 1
				derivy = derivy - game.level.map.tile_h
			elseif derivy <= -game.level.map.tile_h then
				game.level.map.my = game.level.map.my + 1
				derivy = derivy + game.level.map.tile_h
			end
			game.level.map._map:setScroll(game.level.map.mx, game.level.map.my)
		end
	end)
	-- Scroll message log
	self.mouse:registerZone(self.log.display_x, self.log.display_y, self.w, self.h, function(button)
		if button == "wheelup" then self.log:scrollUp(1) end
		if button == "wheeldown" then self.log:scrollUp(-1) end
	end, {button=true})
end

--- Ask if we realy want to close, if so, save the game first
function _M:onQuit()
	if not self.quit_dialog then
		self.quit_dialog = QuitDialog.new()
		self:registerDialog(self.quit_dialog)
	end
end
