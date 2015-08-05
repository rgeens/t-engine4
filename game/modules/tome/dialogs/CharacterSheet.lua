-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2015 Nicolas Casalini
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
require "mod.class.interface.TooltipsData"
local Dialog = require "engine.ui.Dialog"
local DamageType = require "engine.DamageType"
local Talents = require "engine.interface.ActorTalents"
local Tab = require "engine.ui.Tab"
local Button = require "engine.ui.Button"
local SurfaceZone = require "engine.ui.SurfaceZone"
local Separator = require "engine.ui.Separator"
local Stats = require "engine.interface.ActorStats"
local Textzone = require "engine.ui.Textzone"
local FontPackage = require "engine.FontPackage"
local EquipDoll = require "engine.ui.EquipDoll"
local TextzoneList = require "engine.ui.TextzoneList"

module(..., package.seeall, class.inherit(Dialog, mod.class.interface.TooltipsData))

cs_player_dup = nil
local tabs_list = {general=true, attack=true, defense=true, talents=true, equipment=true}

function _M:init(actor, start_tab)
	if _M.cs_player_dup and _M.cs_player_dup.name ~= actor.name then _M.cs_player_dup = nil end

	self.actor = actor
	start_tab = start_tab and tabs_list[start_tab] and start_tab or "general"

	self.font = core.display.newFont(FontPackage:getFont("mono_small", "mono"))
	self.font_w, self.font_h = self.font:size(' ')
	self.font_h = self.font:lineSkip()

	Dialog.init(self, "Character Sheet: "..self.actor.name, util.bound(self.font_w*200, game.w*0.5, game.w*0.95), util.bound(self.font_h*36, game.h*.35, game.h*.85))

	self.talent_sorting = config.settings.tome.charsheet_talent_sorting or 1

	self.c_general = Tab.new{title="[G]eneral", default=start_tab == "general", fct=function() end, on_change=function(s) if s then self:switchTo("general") end end}
	self.c_attack = Tab.new{title="[A]ttack", default=start_tab == "attack", fct=function() end, on_change=function(s) if s then self:switchTo("attack") end end}
	self.c_defence = Tab.new{title="[D]efense", default=start_tab == "defense", fct=function() end, on_change=function(s) if s then self:switchTo("defence") end end}
	self.c_talents = Tab.new{title="[T]alents", default=start_tab == "talents", fct=function() end, on_change=function(s) if s then self:switchTo("talents") end end }

	-- Select equipment/switch sets
	self.equip_set = self.actor.off_weapon_slots and "off" or "main"
	self.c_equipment = Tab.new{title="[E]quipment: "..self.equip_set.." set", default=start_tab == "equipment",
		fct=function()
		end,
		on_change=function(s)
			if not self.actor.quickSwitchWeapons then return end
			if s then
				if self.last_tab == "equipment" then
					local last_set = self.equip_set
					self.equip_set = last_set == "off" and "main" or "off"
					if not self:updateEquipDollRefs() then
						self.equip_set = last_set
					else
						game.logPlayer(self.actor, "#RED#Displaying %s set for %s (equipment NOT switched)", self.equip_set, self.actor.name:capitalize())
					end
				end
				self.c_equipment.title = "[E]quipment: "..self.equip_set.." set"
				self:switchTo("equipment")
				self.c_equipment:generate() -- Force redraw
			end
		end
	}
	self.b_talents_sorting = Button.new{text="Sort: "..({"Groups", "Name", "Type"})[self.talent_sorting], hide=true, width=100, fct=function()
		self.talent_sorting = self.talent_sorting + 1
		if self.talent_sorting > 3 then self.talent_sorting = 1 end

		--Save to config
		config.settings.tome.charsheet_talent_sorting = self.talent_sorting
		game:saveSettings("tome.charsheet_talent_sorting", ("tome.charsheet_talent_sorting = %d\n"):format(self.talent_sorting))

		self.b_talents_sorting.text = "Sort: "..({"Groups", "Name", "Type"})[self.talent_sorting]
		self.b_talents_sorting:generate()
		self:switchTo("talents") -- Force a redraw
	end}
	self.b_show_equipment = Button.new{text="Manage [I]nventory", fct=function()
		self:showInventory()
		return
	end}
	
	local tw, th = self.font_bold:size(self.title)

	self.vs = Separator.new{dir="vertical", size=self.iw}

	self.c_tut = Textzone.new{width=self.iw * 0.6, auto_height=true, no_color_bleed=true, font = self.font, text=[[
Values #00FF00#in brackets ( )#LAST# show changes made from last character sheet checking.
Keyboard: #00FF00#'u'#LAST# to save character dump. #00FF00#TAB key#LAST# to switch between tabs.
Mouse: Hover over stat for info
]]}
	game.total_playtime = (game.total_playtime or 0) + (os.time() - (game.last_update or game.real_starttime))
	game.last_update = os.time()

	local playtime = ""
	local days = math.floor(game.total_playtime/86400)
	local hours = math.floor(game.total_playtime/3600) % 24
	local minutes = math.floor(game.total_playtime/60) % 60
	local seconds = game.total_playtime % 60

	if days > 0 then
		playtime = ("%i day%s %i hour%s %i minute%s %s second%s"):format(days, days > 1 and "s" or "", hours, hours > 1 and "s" or "", minutes, minutes > 1 and "s" or "", seconds, seconds > 1 and "s" or "")
	elseif hours > 0 then
		playtime = ("%i hour%s %i minute%s %s second%s"):format(hours, hours > 1 and "s" or "", minutes, minutes > 1 and "s" or "", seconds, seconds > 1 and "s" or "")
	elseif minutes > 0 then
		playtime = ("%i minute%s %s second%s"):format(minutes, minutes > 1 and "s" or "", seconds, seconds > 1 and "s" or "")
	else
		playtime = ("%s second%s"):format(seconds, seconds > 1 and "s" or "")
	end

	local all_kills_kind = self.actor.all_kills_kind or {}
	local playtimetext = ([[#GOLD#Days adventuring / current month:#LAST# %d / %s
#GOLD#Time playing:#LAST# %s
#GOLD#Creatures killed:           #ANTIQUE_WHITE#%d
#GOLD#Elites/Rares/Bosses killed: #YELLOW#%d/#SALMON#%d/#ORANGE#%d
]]):format(
		game.turn / game.calendar.DAY,
		game.calendar:getMonthName(game.calendar:getDayOfYear(game.turn)),
		playtime,
		all_kills_kind.creature or 0,
		all_kills_kind.elite or 0,
		all_kills_kind.rare or 0,
		all_kills_kind.boss or 0
	)

	self.c_playtime = Textzone.new{width=self.iw * 0.4, auto_height=true, no_color_bleed=true, font = self.font, text=playtimetext}

	self.c_desc = SurfaceZone.new{width=self.iw, height=self.ih - self.c_general.h - self.vs.h - self.c_tut.h,alpha=0}

	self.equip_frame = { -- display equipment
		dialog = self,
		c_doll = EquipDoll.new{equipdoll = self.actor.equipdoll or "default", actor=self.actor, title=false,
			subobject=self.actor:attr("can_tinker") and "getTinker" or nil,
			subobject_restrict_slots=self.actor.tinker_restrict_slots,
			drag_enable=false, filter=nil,
			scale = math.min(self.ih/630, self.iw/1700), --scale doll to fit dialog
			fct=function(item) end,
			on_select=function(ui, inven, item, o)
--game.log("c_doll select called with item %s (ui:%s, inven:%s, item:%s)", o and o.name, tostring(ui), inven, item)
				if o and inven and item and ui and ui.x and ui.y then
--game.log("#GREY#c_doll select(local):ui = (%s,%s) to (%s,%s)", ui.x, ui.y, ui.x+ui.ui.w, ui.y+ui.ui.h)
					self.equip_frame.c_obj_desc:switchItem({item=item, object=o, ui=ui, inven=inven}, o:getDesc({do_color=true}, nil, true, self.actor))
				end
			end,
		},
		vsep = Separator.new{dir="horizontal", size=self.ih - self.c_tut.h - self.c_general.h - 20}
	}
	self.equip_frame.c_doll.dialog = self
	self.equip_frame.c_obj_desc = TextzoneList.new{focus_check=true, scrollbar=true, pingpong = 20, width=self.iw - self.equip_frame.c_doll.w - self.equip_frame.vsep.w - 50, height = self.ih - self.c_tut.h, no_color_bleed=true,
		dest_area = { h = self.ih - self.c_tut.h - self.vs.h},
		can_focus = true,
		on_focus = function(self, v)
		end,
		font = self.font,
		}

	self:loadUI{
		{left=0, top=0, ui=self.c_tut},
		{left=self.iw * 0.5, top=0, ui=self.c_playtime},
		{left=15, top=self.c_tut.h, ui=self.c_general},
--		{right=130, top=50, ui=self.b_show_equipment}, -- misaligned mouse zone?
		{right=200, top=self.c_tut.h, ui=self.b_show_equipment},
		{left=15+self.c_general.w, top=self.c_tut.h, ui=self.c_attack},
		{left=15+self.c_general.w+self.c_attack.w, top=self.c_tut.h, ui=self.c_defence},
		{left=15+self.c_general.w+self.c_attack.w+self.c_defence.w, top=self.c_tut.h, ui=self.c_talents},
		{left=15+self.c_general.w+self.c_attack.w+self.c_defence.w+self.c_talents.w, top=self.c_tut.h, ui=self.c_equipment},
		{left=0, top=self.c_tut.h + self.c_general.h, ui=self.vs},
		{right=0, bottom=0, ui=self.b_talents_sorting},
		{left=0, top=self.c_tut.h + self.c_general.h + 5 + self.vs.h, ui=self.c_desc},
	}
--	self:setFocus(self.c_general)
	self:setupUI()

	self:switchTo(start_tab)

	self:updateKeys()
end

-- Immunity types to display matching Actor:attr(<immunity>)
_M.status_immunities = {poison_immune = "Poison     ",
	disease_immune = "Disease    ", cut_immune = "Bleed      ", confusion_immune= "Confusion  ",
	blind_immune = "Blind      ", silence_immune = "Silence    ", disarm_immune = "Disarm     ",
	pin_immune = "Pinning    ", stun_immune = "Stun/Freeze", sleep_immune = "Sleep      ",
	fear_immune = "Fear       ", knockback_immune = "Knockback  ", stone_immune = "Stoning    ",
	instakill_immune = "Instadeath ", teleport_immune = "Teleport   ",
	negative_status_effect_immune = "All        "}
-- Specific tooltips to use for certain immunity types
_M.immunity_tooltips = {instakill_immune = "TOOLTIP_INSTAKILL_IMMUNE", negative_status_effect_immune = "TOOLTIP_NEGATIVE_STATUS_IMMUNE", stun_immune="TOOLTIP_STUN_IMMUNE"}

function _M:innerDisplay(x, y, nb_keyframes)
	self.actor:toScreen(nil, x + self.iw - 128, y + 6, 128, 128)
end

function _M:switchTo(kind)
	self.b_talents_sorting.hide = true
	self.b_show_equipment.hide = not self.actor.player
	self:hideEquipmentFrame() -- turn off special frames for equipment
	self:drawDialog(kind, _M.cs_player_dup)
	if kind == "general" then self.c_attack.selected = false self.c_defence.selected = false self.c_talents.selected = false self.c_equipment.selected = false
	elseif kind == "attack" then self.c_general.selected = false self.c_defence.selected = false self.c_talents.selected = false self.c_equipment.selected = false
	elseif kind == "defence" then self.c_attack.selected = false self.c_general.selected = false self.c_talents.selected = false self.c_equipment.selected = false
	elseif kind == "talents" then
		self.b_talents_sorting.hide = false
		self.c_attack.selected = false self.c_general.selected = false self.c_defence.selected = false self.c_equipment.selected = false
	elseif kind == "equipment" then self.c_attack.selected = false self.c_general.selected = false self.c_talents.selected = false self.c_defence.selected = false
	end
	self.last_tab = kind
	self:updateKeys()
end

function _M:on_register()
	game:onTickEnd(function() self.key:unicodeInput(true) end)
end

function _M:updateKeys()
	self.key:addCommands{
	_TAB = function() self:tabTabs() end,
	__TEXTINPUT = function(c)
		if (c == 'u' or c == 'U') and self.actor.player then
			self:dump()
		elseif (c == 'g' or c == 'G') then
			self.c_general:select()
		elseif (c == 'a' or c == 'A') then
			self.c_attack:select()
		elseif (c == 'd' or c == 'D') then
			self.c_defence:select()
		elseif (c == 't' or c == 'T') then
			self.c_talents:select()
		elseif (c == 'e' or c == 'E') then
			self.c_equipment:select()
		elseif (c == 'i' or c == 'I') then
			self:showInventory()
		end
	end,
	}
	if self.c_equipment.selected then
		local OD = self.equip_frame.c_obj_desc
		self.key:addCommands{
		[{"_UP","ctrl"}] = function() OD.key:triggerVirtual("MOVE_UP") end,
		[{"_DOWN","ctrl"}] = function()	OD.key:triggerVirtual("MOVE_DOWN") end,
		_HOME = function() if OD.scrollbar then OD.scrollbar.pos = 0 end end,
		_END = function() if OD.scrollbar then OD.scrollbar.pos = OD.scrollbar.max end end,
		_PAGEUP = function() if OD.scrollbar then OD.scrollbar.pos = util.minBound(OD.scrollbar.pos - OD.h, 0, OD.scrollbar.max) end end,
		_PAGEDOWN = function() if OD.scrollbar then OD.scrollbar.pos = util.minBound(OD.scrollbar.pos + OD.h, 0, OD.scrollbar.max) end end,
	}
	end
	self.key:addBinds{
		EXIT = function() _M.cs_player_dup = game.player:clone() game:unregisterDialog(self) end,
		LUA_CONSOLE = function()
			if config.settings.cheat then
				local DebugConsole = require "engine.DebugConsole"
				game:registerDialog(DebugConsole.new())
			end
		end,
		}
end

function _M:tabTabs()
	if self.c_general.selected == true then self.c_attack:select()
	elseif self.c_attack.selected == true then self.c_defence:select()
	elseif self.c_defence.selected == true then self.c_talents:select()
	elseif self.c_talents.selected == true then self.c_equipment:select()
	elseif self.c_equipment.selected == true then self.c_general:select()
	end
end

function _M:mouseZones(t, no_new)
	self.c_desc.mouse:registerZones(t)
	self.c_desc.can_focus = true
end

function _M:mouseTooltip(text, _, _, _, w, h, x, y)
	self:mouseZones({
		{ x=x, y=y, w=w, h=h, fct=function(button) game.tooltip_x, game.tooltip_y = 1, 1; game:tooltipDisplayAtMap(game.w, game.h, text) end},
	}, true)
end

function _M:mouseLink(link, text, _, _, _, w, h, x, y)
	self:mouseZones({
		{ x=x, y=y, w=w, h=h, fct=function(button)
			game.tooltip_x, game.tooltip_y = 1, 1; game:tooltipDisplayAtMap(game.w, game.h, text)
			if button == "left" then
				util.browserOpenUrl(link, {is_external=true})
			end
		end},
	}, true)
end

-- Switch between equipment sets (by reference only) for the equip doll
-- This makes sure the equipment shown in the equipdoll matches the tab setting
-- Done this way to make sure the actor's equipment is never actually touched
function _M:updateEquipDollRefs()
	local actor, c_doll = self.actor, self.equip_frame.c_doll
	local showset = "main"
	
	if (actor.off_weapon_slots and self.equip_set ~= "off") or (actor.off_weapon_slots == false and self.equip_set ~= "main") then
		showset = "off"
	else showset = "main"
	end
--game.log("Showing actual %s set", showset)
	local mh1, mh2 = actor.inven[actor.INVEN_MAINHAND], actor.inven[actor.INVEN_QS_MAINHAND]
	local oh1, oh2 = actor.inven[actor.INVEN_OFFHAND], actor.inven[actor.INVEN_QS_OFFHAND]
	local pf1, pf2 = actor.inven[actor.INVEN_PSIONIC_FOCUS], actor.inven[actor.INVEN_QS_PSIONIC_FOCUS]
	local qv1, qv2 = actor.inven[actor.INVEN_QUIVER], actor.inven[actor.INVEN_QS_QUIVER]
	if not mh1 or not mh2 or not oh1 or not oh2 then return end
	
	--find ui's corresponding to displayed inventory slots and update refs to the displayed slots
	local mhui, ohui, qvui, pfui
	for i, ui in ipairs(c_doll.uis) do
		if ui.ui and ui.ui.inven then
			if not ui.ui.inven_name then -- assign inventory names the first time
				ui.ui.inven_name = ui.ui.inven.name
			end
			if ui.ui.inven_name == "MAINHAND" then
				ui.ui.inven = showset == "main" and mh1 or mh2
			elseif ui.ui.inven_name == "OFFHAND" then
				ui.ui.inven = showset == "main" and oh1 or oh2
			elseif ui.ui.inven_name == "PSIONIC_FOCUS" then
				ui.ui.inven = showset == "main" and pf1 or pf2
			elseif ui.ui.inven_name == "QUIVER" then
				ui.ui.inven = showset == "main" and qv1 or qv2
			end
--game.log("#GREY#--UI %d: %s (showing: %s)", i, ui.ui.inven_name, ui.ui.inven.id)
		end
	end
--	return showset == self.equip_set
	return true
end

-- show the equipment inspection area
function _M:showEquipmentFrame()
	local EF = self.equip_frame
	local uis = {no_reset=true,
		{left=EF.c_doll.w, top=self.c_tut.h + self.c_general.h + self.vs.h, ui=EF.vsep},
		{left=0, top=self.c_tut.h + self.c_general.h + self.vs.h, ui=EF.c_doll},
		{left=EF.c_doll.w + EF.vsep.w + 10, top=self.c_tut.h + self.c_general.h + self.vs.h, ui=EF.c_obj_desc},
	}
	self:loadUI(uis)
	self:setFocus(EF.c_doll)
	self:setupUI()
	-- set up mouse for this tab
	self.mouse:registerZone(self.display_x + 0, self.display_y + self.title_tex.h + self.c_tut.h + self.c_general.h + self.vs.h + 10, self.w, EF.c_doll.h,
		function(button, x, y, xrel, yrel, bx, by, event)
--game.log("#PINK#Csheet: c_doll mouse event (local) function: button: %s, (%s, %s), (%s, %s), [%s, %s], event:%s", button, x, y, xrel, yrel, bx, by, event)
			if button == "wheelup" and event == "button" then
				EF.c_obj_desc.key:triggerVirtual("MOVE_UP")
			elseif button == "wheeldown" and event == "button" then
				EF.c_obj_desc.key:triggerVirtual("MOVE_DOWN")
			end
			for i = 1, #EF.c_doll.uis do
				local ui = EF.c_doll.uis[i]
--game.log("#GREY#--ui[%d]: (%s,%s) to (%s,%s)", i, ui.x, ui.x + ui.ui.w, ui.y, ui.y + ui.ui.h)
				if ui.ui.can_focus and bx >= ui.x and bx <= ui.x + ui.ui.w and by >= ui.y and by <= ui.y + ui.ui.h then
--game.log("#YELLOW#--Setting focus for ui[%d]: (%s,%s) to (%s,%s)", i, ui.x, ui.x + ui.ui.w, ui.y, ui.y + ui.ui.h)
					EF.c_doll:setInnerFocus(i)
					-- Pass the event
					ui.ui.mouse:delegate(button, x, y, xrel, yrel, bx, by, event)
					return true
				end
			end
			EF.c_doll:no_focus()
		end,
		mode, "equip_doll")
end

-- hide the equipment inspection area
function _M:hideEquipmentFrame()
	self.mouse:unregisterZone("equip_doll") -- disable equip doll mouse functions
	local EF = self.equip_frame
	self:toggleDisplay(EF.c_doll, false)
	self:toggleDisplay(EF.c_obj_desc, false)
	self:toggleDisplay(EF.vsep, false)
end

--Failing to update Csheet on equipment drag?
-- show the inventory screen
function _M:showInventory()
	if self.actor.no_inventory_access or not self.actor.player then return end
	local d
	local titleupdator = self.actor:getEncumberTitleUpdator("Inventory")
	d = require("mod.dialogs.ShowEquipInven").new(titleupdator(), self.actor, nil,
		function(o, inven, item, button, event)
			if not o then return end
			local ud = require("mod.dialogs.UseItemDialog").new(event == "button", self.actor, o, item, inven, function(_, _, _, stop)
				d:generate()
				d:generateList()
				d:updateTitle(titleupdator())
				if stop then game:unregisterDialog(d) game:unregisterDialog(self)
				end
				if self.actor.changed then
					_M.cs_player_dup = d._actor_to_compare --update comparison info
					self:switchTo(self.last_tab) -- force refresh
				end
			end)
			game:registerDialog(ud)
		end
		)
	game:registerDialog(d)
	d._actor_to_compare = d._actor_to_compare or game.player:clone() -- save comparison info
end

function _M:drawDialog(kind, actor_to_compare)
--game.log("Drawing dialog for %s(%s vs %s)", self.actor.name, tostring(self.actor), actor_to_compare)
	self.c_desc.mouse:reset()
	self.c_desc.key:reset()

	local player = self.actor
	local s = self.c_desc.s

	s:erase(0,0,0,0)

	local h = 0
	local w = 0

	local text = ""
	local dur_text = ""

	if player.__te4_uuid and profile.auth and profile.auth.drupid then
		local path = "http://te4.org/characters/"..profile.auth.drupid.."/tome/"..player.__te4_uuid
		local LinkTxt = "Online URL: #LIGHT_BLUE##{underline}#"..path.."#{normal}#"
		local Link_w, Link_h = self.font:size(LinkTxt)
		h = self.c_desc.h - Link_h
		w = (self.c_desc.w - Link_w) * 0.5
		self:mouseLink(path, "You can find your character sheet online", s:drawColorStringBlended(self.font, LinkTxt, w, h, 255, 255, 255, true))
	end

	local compare_fields = function(item1, item2, field, outformat, diffoutformat, mod, isinversed, nobracets, ...)
		mod = mod or 1
		isinversed = isinversed or false
		local ret = tstring{}
		local added = 0
		local add = false
		local value
		if type(field) == "function" then
			value = field(item1, ...)
		else
			value = item1[field]
		end
		ret:add(outformat:format((value or 0) * mod))

		if value then
			add = true
		end

		local value2
		if item2 then
			if type(field) == "function" then
				value2 = field(item2, ...)
			else
				value2 = item2[field]
			end
		end

		if value and value2 and value2 ~= value then
			if added == 0 and not nobracets then
				ret:add(" (")
			elseif added > 1 then
				ret:add(" / ")
			end
			added = added + 1
			add = true

			if isinversed then
				ret:add(value2 < value and {"color","RED"} or {"color","LIGHT_GREEN"}, diffoutformat:format(((value or 0) - value2) * mod), {"color", "LAST"})
			else
				ret:add(value2 > value and {"color","RED"} or {"color","LIGHT_GREEN"}, diffoutformat:format(((value or 0) - value2) * mod), {"color", "LAST"})
			end
		end
		if added > 0 and not nobracets then
			ret:add(")")
		end
		if add then
			return ret:toString()
		end
		return nil
	end

	local compare_table_fields = function(item1, item2, field, outformat, text, kfunct, mod, isinversed)
		mod = mod or 1
		isinversed = isinversed or false
		local ret = tstring{}
		local added = 0
		local add = false
		ret:add(text)
		local tab = {}
		if item1[field] then
			for k, v in pairs(item1[field]) do
				tab[k] = {}
				tab[k][1] = v
			end
		end
		if item2[field] then
			for k, v in pairs(item2[field]) do
				tab[k] = tab[k] or {}
				tab[k][2] = v
			end
		end
		local count1 = 0
		for k, v in pairs(tab) do
			local count = 0
			if isinversed then
				ret:add(("%s"):format((count1 > 0) and " / " or ""), (v[1] or 0) > 0 and {"color","RED"} or {"color","LIGHT_GREEN"}, outformat:format((v[1] or 0)), {"color","LAST"})
			else
				ret:add(("%s"):format((count1 > 0) and " / " or ""), (v[1] or 0) < 0 and {"color","RED"} or {"color","LIGHT_GREEN"}, outformat:format((v[1] or 0)), {"color","LAST"})
			end
			count1 = count1 + 1
			if v[1] then
				add = true
			end
			for kk, vv in pairs(v) do
				if kk > 1 and (v[1] or 0) ~= vv then
					if count == 0 then
						ret:add("(")
					elseif count > 0 then
						ret:add(" / ")
					end
					if isinversed then
						ret:add((v[1] or 0) > vv and {"color","RED"} or {"color","LIGHT_GREEN"}, outformat:format((v[1] or 0) - vv), {"color","LAST"})
					else
						ret:add((v[1] or 0) < vv and {"color","RED"} or {"color","LIGHT_GREEN"}, outformat:format((v[1] or 0) - vv), {"color","LAST"})
					end
					add = true
					count = count + 1
				end
			end
			if count > 0 then
				ret:add(")")
			end
			ret:add(kfunct(k))
		end

		if add then
			return ret:toString()
		end
		return nil
	end

	if kind == "general" then
		local cur_exp, max_exp = player.exp, player:getExpChart(player.level+1)
		h = 0
		w = 0
		s:drawStringBlended(self.font, "Sex  : "..((player.descriptor and player.descriptor.sex) or (player.female and "Female" or "Male")), w, h, 0, 200, 255, true) h = h + self.font_h
		s:drawStringBlended(self.font, (player.descriptor and "Race : " or "Type : ")..((player.descriptor and player.descriptor.subrace) or player.type:capitalize()), w, h, 0, 200, 255, true) h = h + self.font_h
		s:drawStringBlended(self.font, (player.descriptor and "Class: " or "Stype: ")..((player.descriptor and player.descriptor.subclass) or player.subtype:capitalize()), w, h, 0, 200, 255, true) h = h + self.font_h
		s:drawStringBlended(self.font, "Size : "..(player:TextSizeCategory():capitalize()), w, h, 0, 200, 255, true) h = h + self.font_h

		h = h + self.font_h
		if player:attr("forbid_arcane") then
			local follow = (player.faction == "zigur" or player:attr("zigur_follower")) and "Zigur follower" or "Antimagic devotee"
			s:drawColorStringBlended(self.font, "#ORCHID#"..follow, w, h, 255, 255, 255, true) h = h + self.font_h
		end
		if player:attr("blood_life") then
			s:drawColorStringBlended(self.font, "#DARK_RED#Blood of Life", w, h, 255, 255, 255, true) h = h + self.font_h
		end

		h = h + self.font_h
		self:mouseTooltip(self.TOOLTIP_LEVEL, s:drawColorStringBlended(self.font,  "Level: #00ff00#"..player.level, w, h, 255, 255, 255, true)) h = h + self.font_h
		self:mouseTooltip(self.TOOLTIP_LEVEL, s:drawColorStringBlended(self.font, ("Exp  : #00ff00#%2d%%"):format(100 * cur_exp / max_exp), w, h, 255, 255, 255, true)) h = h + self.font_h
		self:mouseTooltip(self.TOOLTIP_GOLD, s:drawColorStringBlended(self.font, ("Gold : #00ff00#%0.2f"):format(player.money), w, h, 255, 255, 255, true)) h = h + self.font_h

		h = h + self.font_h

		text = compare_fields(player, actor_to_compare, "max_life", "%d", "%+.0f")
		if player.die_at ~=  0 or (actor_to_compare and actor_to_compare.die_at ~=0) then 
			text = text .. " #a08080#[" .. compare_fields(player, actor_to_compare, "die_at", "die:%+d","%+.0f", 1, true) .. "]"
		end
		if player.life < 0 then self:mouseTooltip(self.TOOLTIP_LIFE, s:drawColorStringBlended(self.font, ("#c00000#Life: #00ff00#???/%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		else self:mouseTooltip(self.TOOLTIP_LIFE, s:drawColorStringBlended(self.font, ("#c00000#Life: #00ff00#%d/%s"):format(player.life, text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end

		if player:knowTalent(player.T_STAMINA_POOL) then
			text = compare_fields(player, actor_to_compare, "max_stamina", "%d", "%+.0f")
			self:mouseTooltip(self.TOOLTIP_STAMINA, s:drawColorStringBlended(self.font, ("#ffcc80#Stamina: #00ff00#%d/%s"):format(player:getStamina(), text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		if player:knowTalent(player.T_MANA_POOL) then
			text = compare_fields(player, actor_to_compare, "max_mana", "%d", "%+.0f")
			self:mouseTooltip(self.TOOLTIP_MANA, s:drawColorStringBlended(self.font, ("#7fffd4#Mana: #00ff00#%d/%s"):format(player:getMana(), text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		if player:knowTalent(player.T_POSITIVE_POOL) then
			text = compare_fields(player, actor_to_compare, "max_positive", "%d", "%+.0f")
			self:mouseTooltip(self.TOOLTIP_POSITIVE, s:drawColorStringBlended(self.font, ("#7fffd4#Positive: #00ff00#%d/%s"):format(player:getPositive(), text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		if player:knowTalent(player.T_NEGATIVE_POOL) then
			text = compare_fields(player, actor_to_compare, "max_negative", "%d", "%+.0f")
			self:mouseTooltip(self.TOOLTIP_NEGATIVE, s:drawColorStringBlended(self.font, ("#7fffd4#Negative: #00ff00#%d/%s"):format(player:getNegative(), text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		if player:knowTalent(player.T_VIM_POOL) then
			text = compare_fields(player, actor_to_compare, "max_vim", "%d", "%+.0f")
			self:mouseTooltip(self.TOOLTIP_VIM, s:drawColorStringBlended(self.font, ("#904010#Vim: #00ff00#%d/%s"):format(player:getVim(), text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		if player:knowTalent(player.T_HATE_POOL) then
			self:mouseTooltip(self.TOOLTIP_HATE, s:drawColorStringBlended(self.font, ("#F53CBE#Hate: #00ff00#%d/%d"):format(player:getHate(), player.max_hate), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		if player:knowTalent(player.T_PARADOX_POOL) then
			text = compare_fields(player, actor_to_compare, function(actor) local chance = actor:paradoxFailChance() return chance end, "%d%%", "%+.1f%%", 1, true)
			self:mouseTooltip(self.TOOLTIP_PARADOX, s:drawColorStringBlended(self.font, ("#LIGHT_STEEL_BLUE#Paradox: #00ff00#%d(anomaly: %s)"):format(player:getParadox(), text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		if player:knowTalent(player.T_PSI_POOL) then
			text = compare_fields(player, actor_to_compare, "max_psi", "%d", "%+.0f")
			self:mouseTooltip(self.TOOLTIP_PSI, s:drawColorStringBlended(self.font, ("#7fffd4#Psi: #00ff00#%d/%s"):format(player:getPsi(), text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		if player:getMaxFeedback() > 0 then
			text = compare_fields(player, actor_to_compare, "psionic_feedback_max", "%d", "%+.0f")
			local tt = self.TOOLTIP_FEEDBACK..("Current Feedback gain is %0.1f%% of damge taken."):format(player:callTalent(player.T_FEEDBACK_POOL, "getFeedbackRatio")*100)
			self:mouseTooltip(tt, s:drawColorStringBlended(self.font, ("#7fffd4#Feedback: #00ff00#%d/%s"):format(player:getFeedback(), text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end

		if player:knowTalent(player.T_EQUILIBRIUM_POOL) then
			text = compare_fields(player, actor_to_compare, function(actor) local _, chance = actor:equilibriumChance() return 100 - chance end, "%d%%", "%+.1f%%", 1, true)
			self:mouseTooltip(self.TOOLTIP_EQUILIBRIUM, s:drawColorStringBlended(self.font, ("#00ff74#Equi: #00ff00#%d(fail: %s)"):format(player:getEquilibrium(), text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end

		h = 0
		w = self.w * 0.25

		s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Speeds:", w, h, 255, 255, 255, true) h = h + self.font_h
		local color = player.global_speed
		color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
		text = compare_fields(player, actor_to_compare, "global_speed", color.."%.1f%%", "%+.1f%%",100)
		self:mouseTooltip(self.TOOLTIP_SPEED_GLOBAL,   s:drawColorStringBlended(self.font, ("Global speed  : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		color = 1/player:getSpeed("movement")
		color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
		text = compare_fields(player, actor_to_compare, function(actor) return (1/actor:getSpeed("movement")) end, color.."%.1f%%", "%+.1f%%", 100)
		self:mouseTooltip(self.TOOLTIP_SPEED_MOVEMENT, s:drawColorStringBlended(self.font, ("Movement speed: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		color = 1/player:getSpeed("spell")
		color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
		text = compare_fields(player, actor_to_compare, function(actor, ...) return 1/actor:getSpeed("spell") end, color.."%.1f%%", "%+.1f%%", 100)
		self:mouseTooltip(self.TOOLTIP_SPEED_SPELL,    s:drawColorStringBlended(self.font, ("Spell speed   : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h

		color = 1/player:getSpeed("weapon")
		color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
		text = compare_fields(player, actor_to_compare, function(actor, ...) return 1/actor:getSpeed("weapon") end, color.."%.1f%%", "%+.1f%%", 100)
		self:mouseTooltip(self.TOOLTIP_SPEED_ATTACK,   s:drawColorStringBlended(self.font, ("Attack speed  : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		color = 1/player:getSpeed("mind")
		color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
		text = compare_fields(player, actor_to_compare, function(actor, ...) return 1/actor:getSpeed("mind") end, color.."%.1f%%", "%+.1f%%", 100)
		self:mouseTooltip(self.TOOLTIP_SPEED_MENTAL,   s:drawColorStringBlended(self.font, ("Mental speed  : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		h = h + self.font_h
		if player.died_times then
			text = compare_fields(player, actor_to_compare, function(actor) return #actor.died_times end, "%3d", "%+.0f")
			self:mouseTooltip(self.TOOLTIP_LIVES,       s:drawColorStringBlended(self.font, ("Times died     : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		if player.easy_mode_lifes then
			text = compare_fields(player, actor_to_compare, "easy_mode_lifes", "%3d", "%+.0f")
			self:mouseTooltip(self.TOOLTIP_LIVES, s:drawColorStringBlended(self.font,   ("Lives left     : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		color = player.healing_factor
		color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
		text = compare_fields(player, actor_to_compare, function(actor) return util.bound((actor.healing_factor or 1), 0, 2.5) end, color.."%.1f%%", "%+.1f%%", 100)
		self:mouseTooltip(self.TOOLTIP_HEALING_MOD, s:drawColorStringBlended(self.font, ("Healing mod.   : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		color = player.life_regen
		color = color >= 0 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
		text = compare_fields(player, actor_to_compare, "life_regen", color.."%.1f", "%+.1f")
		self:mouseTooltip(self.TOOLTIP_LIFE_REGEN,  s:drawColorStringBlended(self.font, ("Life regen     : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor) return actor.life_regen * util.bound((actor.healing_factor or 1), 0, 2.5) end, "%.2f", "%+.2f")
		self:mouseTooltip(self.TOOLTIP_LIFE_REGEN,  s:drawColorStringBlended(self.font, ("(with heal mod): #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h

		h = h + self.font_h
		s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Vision:", w, h, 255, 255, 255, true) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, "lite", "%d", "%+.0f")
		if text then
			self:mouseTooltip(self.TOOLTIP_VISION_LITE,  s:drawColorStringBlended(self.font, ("Light radius   : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		text = compare_fields(player, actor_to_compare, "sight", "%d", "%+.0f")
		if text then
			self:mouseTooltip(self.TOOLTIP_VISION_SIGHT,  s:drawColorStringBlended(self.font, ("Vision range   : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		text = compare_fields(player, actor_to_compare, function(actor) return (actor:attr("infravision") or actor:attr("heightened_senses")) and math.max((actor.heightened_senses or 0), (actor.infravision or 0)) end, "%d", "%+.0f")
		if text then
			self:mouseTooltip(self.TOOLTIP_VISION_INFRA,  s:drawColorStringBlended(self.font, ("Heighten Senses: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		text = compare_fields(player, actor_to_compare, function(who) return who:attr("stealth") and who.stealth + (who:attr("inc_stealth") or 0) end, "%.1f", "%+.1f")
		if text then
			self:mouseTooltip(self.TOOLTIP_VISION_STEALTH,  s:drawColorStringBlended(self.font, ("Stealth        : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		text = compare_fields(player, actor_to_compare, function(actor) return actor:combatSeeStealth() end, "%.1f", "%+.1f")
		if text then
			self:mouseTooltip(self.TOOLTIP_VISION_SEE_STEALTH,  s:drawColorStringBlended(self.font, ("See stealth    : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		text = compare_fields(player, actor_to_compare, "invisible", "%.1f", "%+.1f")
		if text then
			self:mouseTooltip(self.TOOLTIP_VISION_INVISIBLE,  s:drawColorStringBlended(self.font, ("Invisibility   : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		text = compare_fields(player, actor_to_compare, function(actor) return actor:combatSeeInvisible() end, "%.1f", "%+.1f")
		if text then
			self:mouseTooltip(self.TOOLTIP_VISION_SEE_INVISIBLE,  s:drawColorStringBlended(self.font, ("See invisible  : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end

		local any_esp = false
		local esps_compare = {}
		if actor_to_compare and actor_to_compare.esp_all and actor_to_compare.esp_all ~= 0 then
			esps_compare["All"] = {}
			esps_compare["All"][1] = v
			any_esp = true
		end
		if player.esp_all and player.esp_all ~= 0 then
			esps_compare["All"] = esps_compare["All"] or {}
			esps_compare["All"][2] = v
			any_esp = true
		end
		for type, v in pairs(actor_to_compare and (actor_to_compare.esp or {}) or {}) do
			if v ~= 0 then
				esps_compare[type] = {}
				esps_compare[type][1] = v
				any_esp = true
			end
		end
		for type, v in pairs(player.esp or {}) do
			if v ~= 0 then
				esps_compare[type] = esps_compare[type] or {}
				esps_compare[type][2] = v
				any_esp = true
			end
		end
		if any_esp then
			text = compare_fields(player, actor_to_compare, "esp_range", "%d", "%+.0f")
			if text then
				self:mouseTooltip(self.TOOLTIP_ESP_RANGE,  s:drawColorStringBlended(self.font, ("Telepathy range: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end

		-- player.forbid_arcane
		-- player.exp_mod
		-- player.can_breath[]

		h = 0
		w = self.w * 0.5

		self:mouseTooltip(self.TOOLTIP_STATS, s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Stats:        Base/Current", w, h, 255, 255, 255, true)) h = h + self.font_h
		local print_stat = function(stat, name, tooltip)
			local StatVal = player:getStat(stat, nil, nil, true)
			local StatTxt = ""
			text = compare_fields(player, actor_to_compare, function(actor) return actor:getStat(stat, nil, nil, true) end, "", "%+.0f", 1, false, true)
			local text2 = compare_fields(player, actor_to_compare, function(actor) return actor:getStat(stat) end, "", "%+.0f", 1, false, true)

			local text3 = ("(%s / %s)"):format(text~="" and text or "0", text2~="" and text2 or "0")
			if text3 == "(0 / 0)" then
				text3 = ""
			end

			StatTxt = ("%s: #00ff00#%3d / %d#LAST#%s"):format(name, player:getStat(stat, nil, nil, true), player:getStat(stat), text3)

			self:mouseTooltip(tooltip, s:drawColorStringBlended(self.font, StatTxt, w, h, 255, 255, 255, true)) h = h + self.font_h
		end

		print_stat(self.actor.STAT_STR, ("%-12s"):format(Stats.stats_def[self.actor.STAT_STR].name:capitalize()), self.TOOLTIP_STR)
		print_stat(self.actor.STAT_DEX, ("%-12s"):format(Stats.stats_def[self.actor.STAT_DEX].name:capitalize()), self.TOOLTIP_DEX)
		print_stat(self.actor.STAT_CON, ("%-12s"):format(Stats.stats_def[self.actor.STAT_CON].name:capitalize()), self.TOOLTIP_CON)
		print_stat(self.actor.STAT_MAG, ("%-12s"):format(Stats.stats_def[self.actor.STAT_MAG].name:capitalize()), self.TOOLTIP_MAG)
		print_stat(self.actor.STAT_WIL, ("%-12s"):format(Stats.stats_def[self.actor.STAT_WIL].name:capitalize()), self.TOOLTIP_WIL)
		print_stat(self.actor.STAT_CUN, ("%-12s"):format(Stats.stats_def[self.actor.STAT_CUN].name:capitalize()), self.TOOLTIP_CUN)
		h = h + self.font_h

		local nb_inscriptions = 0
		for i = 1, player.max_inscriptions do if player.inscriptions[i] then nb_inscriptions = nb_inscriptions + 1 end end
		self:mouseTooltip(self.TOOLTIP_INSCRIPTIONS, s:drawColorStringBlended(self.font, ("#AQUAMARINE#Inscriptions (%d/%d)"):format(nb_inscriptions, player.max_inscriptions), w, h, 255, 255, 255, true)) h = h + self.font_h
		for i = 1, player.max_inscriptions do if player.inscriptions[i] then
			local t = player:getTalentFromId("T_"..player.inscriptions[i])
			local desc = player:getTalentFullDescription(t)
			self:mouseTooltip("#GOLD##{bold}#"..t.name.."#{normal}##WHITE#\n"..tostring(desc), s:drawColorStringBlended(self.font, ("#LIGHT_GREEN#%s"):format(t.name), w, h, 255, 255, 255, true)) h = h + self.font_h
		end end

		if any_esp then
			h = h + self.font_h
			self:mouseTooltip(self.TOOLTIP_ESP,  s:drawColorStringBlended(self.font, ("Telepathy of: "), w, h, 255, 255, 255, true)) h = h + self.font_h
			if not esps_compare["All"] or not esps_compare["All"][2] or esps_compare["All"][2] == 0 then
				for type, v in pairs(esps_compare) do
					self:mouseTooltip(self.TOOLTIP_ESP,  s:drawColorStringBlended(self.font, ("%s%s "):format(v[2] and (v[1] and "#GOLD#" or "#00ff00#") or "#ff0000#", type:capitalize()), w, h, 255, 255, 255, true)) h = h + self.font_h
				end
			else
				self:mouseTooltip(self.TOOLTIP_ESP_ALL,  s:drawColorStringBlended(self.font, ("%sAll "):format(esps_compare["All"][2] and (esps_compare["All"][1] and "#GOLD#" or "#00ff00#") or "#ff0000#"), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end

		h = 0
		w = self.w * 0.77
		s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Current effects:", w, h, 255, 255, 255, true) h = h + self.font_h
		for tid, act in pairs(player.sustain_talents) do
			if act then
				local t = player:getTalentFromId(tid)
				local desc = "#GOLD##{bold}#"..t.name.."#{normal}##WHITE#\n"..tostring(player:getTalentFullDescription(t))
				self:mouseTooltip(desc, s:drawColorStringBlended(self.font, ("#LIGHT_GREEN#%s"):format(player:getTalentFromId(tid).name), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end
		for eff_id, p in pairs(player.tmp) do
			local e = player.tempeffect_def[eff_id]
			local desc = e.long_desc(player, p)
			if e.status == "detrimental" then
				self:mouseTooltip(desc, s:drawColorStringBlended(self.font, ("#LIGHT_RED#%s"):format(e.desc), w, h, 255, 255, 255, true)) h = h + self.font_h
			else
				self:mouseTooltip(desc, s:drawColorStringBlended(self.font, ("#LIGHT_GREEN#%s"):format(e.desc), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end
	elseif kind=="attack" then
		h = 0
		w = 0
		local color
		local mainhand = player:getInven(player.INVEN_MAINHAND)
		if mainhand and (#mainhand > 0) and not player:attr("disarmed") then
			local WeaponTxt = "#LIGHT_BLUE#Main Hand"
			if player:hasTwoHandedWeapon() then
				WeaponTxt = WeaponTxt.."(2-handed)"
			end
			WeaponTxt = WeaponTxt..":"

			for i, o in ipairs(player:getInven(player.INVEN_MAINHAND)) do
				local mean, dam = player:getObjectCombat(o, "mainhand"), player:getObjectCombat(o, "mainhand")
				local range
				if o.archery and mean then
					local ammo = player:getInven("QUIVER") and player:getInven("QUIVER")[1]
					if ammo and ammo.archery_ammo == o.archery then -- make sure ammo matches launcher
						dam = player:getObjectCombat(ammo, "mainhand")
						range = mean.range
					end
				end
				if mean and dam then
					s:drawColorStringBlended(self.font, WeaponTxt, w, h, 255, 255, 255, true) h = h + self.font_h
					text = compare_fields(player, actor_to_compare, function(actor, ...) return math.floor(actor:combatAttack(...)) end, "%3d", "%+.0f", 1, false, false, mean, dam)
					self:mouseTooltip(self.TOOLTIP_COMBAT_ATTACK, s:drawColorStringBlended(self.font, ("Accuracy    : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
					text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatDamage(...) end, "%3d", "%+.0f", 1, false, false, dam)
					self:mouseTooltip(self.TOOLTIP_COMBAT_DAMAGE, s:drawColorStringBlended(self.font, ("Damage      : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
					text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatAPR(...) end, "%3d", "%+.0f", 1, false, false, dam)
					self:mouseTooltip(self.TOOLTIP_COMBAT_APR,    s:drawColorStringBlended(self.font, ("APR         : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
					text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatCrit(...) end, "%3d%%", "%+.0f%%", 1, false, false, dam)
					self:mouseTooltip(self.TOOLTIP_COMBAT_CRIT,   s:drawColorStringBlended(self.font, ("Crit. chance: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
					color = 1/player:combatSpeed(mean)
					color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
					text = compare_fields(player, actor_to_compare, function(actor, ...) return 1/actor:combatSpeed(...) end, color.."%.1f%%", "%+.1f%%", 100, true, false, mean)
					self:mouseTooltip(self.TOOLTIP_COMBAT_SPEED,  s:drawColorStringBlended(self.font, ("Speed       : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
				end
				
 -- compare fields
				if range then
					self:mouseTooltip(self.TOOLTIP_COMBAT_RANGE, s:drawColorStringBlended(self.font, ("Range (Main Hand): #00ff00#%3d"):format(range), w, h, 255, 255, 255, true)) h = h + self.font_h
				end
			end
		-- Handle bare-handed combat
		else
			s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Unarmed:", w, h, 255, 255, 255, true) h = h + self.font_h
			local mean, dam = player:getObjectCombat(nil, "barehand"), player:getObjectCombat(nil, "barehand")
			if mean and dam then
				text = compare_fields(player, actor_to_compare, function(actor, ...) return math.floor(actor:combatAttack(...)) end, "%3d", "%+.0f", 1, false, false, mean)
				self:mouseTooltip(self.TOOLTIP_COMBAT_ATTACK, s:drawColorStringBlended(self.font, ("Accuracy    : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
				text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatDamage(...) end, "%3d", "%+.0f", 1, false, false, dam)
				self:mouseTooltip(self.TOOLTIP_COMBAT_DAMAGE, s:drawColorStringBlended(self.font, ("Damage      : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
				text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatAPR(...) end, "%3d", "%+.0f", 1, false, false, dam)
				self:mouseTooltip(self.TOOLTIP_COMBAT_APR,    s:drawColorStringBlended(self.font, ("APR         : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
				text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatCrit(...) end, "%3d%%", "%+.0f%%", 1, false, false, dam)
				self:mouseTooltip(self.TOOLTIP_COMBAT_CRIT,   s:drawColorStringBlended(self.font, ("Crit. chance: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
				color = 1/player:combatSpeed(mean)
				color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
				text = compare_fields(player, actor_to_compare, function(actor, ...) return 1/actor:combatSpeed(...) end, color.."%.1f%%", "%+.1f%%", 100, false, false, mean)
				self:mouseTooltip(self.TOOLTIP_COMBAT_SPEED,  s:drawColorStringBlended(self.font, ("Speed       : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
			if mean and mean.range then
				self:mouseTooltip(self.TOOLTIP_COMBAT_RANGE, s:drawColorStringBlended(self.font, ("Range (Main Hand): #00ff00#%3d"):format(mean.range), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end

		h = h + self.font_h
		-- All weapons in off hands
		-- Offhand attacks are with a damage penalty, that can be reduced by talents
		
		if player:getInven(player.INVEN_OFFHAND) then
			for i, o in ipairs(player:getInven(player.INVEN_OFFHAND)) do
				local offmult = player:getOffHandMult(o.combat)
				local mean, dam = player:getObjectCombat(o, "offhand"), player:getObjectCombat(o, "offhand")
				if o.archery and mean then
					dam = (player:getInven("QUIVER") and player:getInven("QUIVER")[1] and player:getInven("QUIVER")[1].combat)
				end
				if mean and dam then
					s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Off Hand:"..(player:attr("disarmed") and " (disabled)" or ""), w, h, 255, 255, 255, true) h = h + self.font_h
					text = compare_fields(player, actor_to_compare, function(actor, ...) return math.floor(actor:combatAttack(...)) end, "%3d", "%+.0f", 1, false, false, mean)
					self:mouseTooltip(self.TOOLTIP_COMBAT_ATTACK, s:drawColorStringBlended(self.font, ("Accuracy    : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
					text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatDamage(...) end, "%3d", "%+.0f", offmult, false, false, dam)
					self:mouseTooltip(self.TOOLTIP_COMBAT_DAMAGE, s:drawColorStringBlended(self.font, ("Damage      : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
					text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatAPR(...) end, "%3d", "%+.0f", 1, false, false, dam)
					self:mouseTooltip(self.TOOLTIP_COMBAT_APR,    s:drawColorStringBlended(self.font, ("APR         : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
					text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatCrit(...) end, "%3d%%", "%+.0f%%", 1, false, false, dam)
					self:mouseTooltip(self.TOOLTIP_COMBAT_CRIT,   s:drawColorStringBlended(self.font, ("Crit. chance: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
					color = 1/player:combatSpeed(mean)
					color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
					text = compare_fields(player, actor_to_compare, function(actor, ...) return 1/actor:combatSpeed(...) end, color.."%.1f%%", "%+.1f%%", 100, false, false, mean)
					self:mouseTooltip(self.TOOLTIP_COMBAT_SPEED,  s:drawColorStringBlended(self.font, ("Speed       : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
				end
 -- compare fields
				if mean and mean.range then self:mouseTooltip(self.TOOLTIP_COMBAT_RANGE, s:drawColorStringBlended(self.font, ("Range (Off Hand): #00ff00#%3d"):format(mean.range), w, h, 255, 255, 255, true)) h = h + self.font_h end
			end
		end

		-- Magical and Mental power
		h = 0
		w = self.w * 0.25
		s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Magical:", w, h, 255, 255, 255, true) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatSpellpower() end, "%3d", "%+.0f")
		self:mouseTooltip(self.TOOLTIP_SPELL_POWER, s:drawColorStringBlended(self.font, ("Spellpower  : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatSpellCrit() end, "%d%%", "%+.0f%%")
		self:mouseTooltip(self.TOOLTIP_SPELL_CRIT, s:drawColorStringBlended(self.font,  ("Crit. chance: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		color = 1/player:combatSpellSpeed()
		color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
		text = compare_fields(player, actor_to_compare, function(actor, ...) return 1/actor:combatSpellSpeed() end, color.."%.1f%%", "%+.1f%%", 100)
		self:mouseTooltip(self.TOOLTIP_SPELL_SPEED, s:drawColorStringBlended(self.font, ("Spell speed : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return (1 - (actor.spell_cooldown_reduction or 0)) * 100 end, "%3d%%", "%+.0f%%", nil, true)
		self:mouseTooltip(self.TOOLTIP_SPELL_COOLDOWN  , s:drawColorStringBlended(self.font,   ("Spell cooldown: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		h = h + self.font_h
		s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Mental:", w, h, 255, 255, 255, true) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatMindpower() end, "%3d", "%+.0f")
		dur_text = ("%d"):format(math.floor(player:combatMindpower()/5))
		self:mouseTooltip(self.TOOLTIP_MINDPOWER, s:drawColorStringBlended(self.font, ("Mindpower: #00ff00#%s"):format(text, dur_text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatMindCrit() end, "%d%%", "%+.0f%%")
		self:mouseTooltip(self.TOOLTIP_MIND_CRIT, s:drawColorStringBlended(self.font,  ("Crit. chance: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		color = 1/player:combatMindSpeed()
		color = color >= 1 and "#LIGHT_GREEN#" or "#LIGHT_RED#"
		text = compare_fields(player, actor_to_compare, function(actor, ...) return 1/actor:combatMindSpeed() end, color.."%.1f%%", "%+.1f%%", 100)
		self:mouseTooltip(self.TOOLTIP_MIND_SPEED, s:drawColorStringBlended(self.font, ("Mind speed : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h

		h = 0
		w = self.w * 0.5

		s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Damage Modifiers:", w, h, 255, 255, 255, true) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return 150 + (actor.combat_critical_power or 0) end, "%3d%%", "%+.0f%%")
		self:mouseTooltip(self.TOOLTIP_INC_CRIT_POWER  , s:drawColorStringBlended(self.font,   ("Critical mult.: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h

		if player.inc_damage.all and player.inc_damage.all ~= 0 or (actor_to_compare and actor_to_compare.inc_damage.all and actor_to_compare.inc_damage.all ~= 0) then
			text = compare_fields(player, actor_to_compare, function(actor, ...) return actor.inc_damage and actor.inc_damage.all or 0 end, "%3d%%", "%+.0f%%")
			self:mouseTooltip(self.TOOLTIP_INC_DAMAGE_ALL, s:drawColorStringBlended(self.font, ("All damage    : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end

		-- Specific Damage type increases
		local all_damage = player.inc_damage.all and player.inc_damage.all or 0
		for i, t in pairs(DamageType.dam_def) do
			local valn = player.inc_damage[DamageType[t.type]] or 0
			local valo = actor_to_compare and actor_to_compare.inc_damage[DamageType[t.type]] or valn
			if valn~=0 or valo~=0 then
				text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatGetDamageIncrease(DamageType[t.type]) end, "%+3d%%", "%+.0f%%")
				self:mouseTooltip(self.TOOLTIP_INC_DAMAGE, s:drawColorStringBlended(self.font, ("%s%-20s: #00ff00#%s"):format((t.text_color or "#WHITE#"), t.name:capitalize().."#LAST#", text), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end

		--Damage vs actor types
		if player.inc_damage_actor_type or actor_to_compare and actor_to_compare.inc_damage_actor_type then
			local types = {}
			if player.inc_damage_actor_type then table.merge(types, player.inc_damage_actor_type) end
			if actor_to_compare and actor_to_compare.inc_damage_actor_type then table.merge(types, actor_to_compare.inc_damage_actor_type) end
			for t, v in pairs(types) do
				local valn = player.inc_damage_actor_type and player.inc_damage_actor_type[t] or 0
				local valo = actor_to_compare and actor_to_compare.inc_damage_actor_type and actor_to_compare.inc_damage_actor_type[t] or 0
				if valn~=0 or valo~=0 then
					text = compare_fields(player, actor_to_compare, function(actor, ...) return actor == player and valn or actor == actor_to_compare and valo or 0 end, "%+3d%%", "%+.0f%%")
					self:mouseTooltip(self.TOOLTIP_INC_DAMAGE_ACTOR, s:drawColorStringBlended(self.font, ("%s%-20s: #00ff00#%s"):format("#ORANGE#", "vs "..t:capitalize().."#LAST#", text), w, h, 255, 255, 255, true)) h = h + self.font_h
				end
			end
		end
		
		h = 0
		w = self.w * 0.75
		--Resist penetration
		s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Damage penetration.:", w, h, 255, 255, 255, true) h = h + self.font_h

		if player.resists_pen.all then
			text = compare_fields(player, actor_to_compare, function(actor, ...) return actor.resists_pen and actor.resists_pen.all or 0 end, "%3d%%", "%+.0f%%")
			
			self:mouseTooltip(self.TOOLTIP_RESISTS_PEN_ALL, s:drawColorStringBlended(self.font, ("All damage    : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		end

		for i, t in pairs(DamageType.dam_def) do
			local valn = player.resists_pen[DamageType[t.type]] or 0
			local valo = actor_to_compare and actor_to_compare.resists_pen[DamageType[t.type]] or 0
			if valn~=0 or valo~=0 then
				text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatGetResistPen(DamageType[t.type]) end, "%3d%%", "%+.0f%%")
				self:mouseTooltip(self.TOOLTIP_RESISTS_PEN, s:drawColorStringBlended(self.font, ("%s%-20s: #00ff00#%s"):format((t.text_color or "#WHITE#"), t.name:capitalize().."#LAST#", text), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end
		
	elseif kind=="defence" then
		h = 0
		w = 0

		local ArmorTxt = "#LIGHT_BLUE#"
		if player:hasHeavyArmor() then
			ArmorTxt = ArmorTxt.."Heavy armor"
		elseif player:hasMassiveArmor() then
			ArmorTxt = ArmorTxt.."Massive armor"
		else
			ArmorTxt = ArmorTxt.."Light armor"
		end

		ArmorTxt = ArmorTxt..":"

		s:drawColorStringBlended(self.font, ArmorTxt, w, h, 255, 255, 255, true) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatFatigue() end, "%3d%%", "%+.0f%%", 1, true)
		self:mouseTooltip(self.TOOLTIP_FATIGUE, s:drawColorStringBlended(self.font,           ("Fatigue         : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatArmorHardiness() end, "%3d%%", "%+.0f%%")
		self:mouseTooltip(self.TOOLTIP_ARMOR_HARDINESS,   s:drawColorStringBlended(self.font, ("Armor Hardiness : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatArmor() end, "%3d", "%+.0f")
		self:mouseTooltip(self.TOOLTIP_ARMOR,   s:drawColorStringBlended(self.font,           ("Armor           : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatDefense(true) end, "%3d", "%+.0f")
		self:mouseTooltip(self.TOOLTIP_DEFENSE, s:drawColorStringBlended(self.font,           ("Defense         : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatDefenseRanged(true) end, "%3d", "%+.0f")
		self:mouseTooltip(self.TOOLTIP_RDEFENSE,s:drawColorStringBlended(self.font,           ("Ranged Defense  : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:combatCritReduction()  end, "%d%%", "%+.0f%%")
		self:mouseTooltip(self.TOOLTIP_CRIT_REDUCTION,s:drawColorStringBlended(self.font,           ("Crit. Reduction : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return actor:attr("ignore_direct_crits") or 0 end, "%d%%", "%+.0f%%")
		self:mouseTooltip(self.TOOLTIP_CRIT_SHRUG,s:drawColorStringBlended(self.font,           ("Crit. Shrug Off : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h

		h = h + self.font_h
		self:mouseTooltip(self.TOOLTIP_SAVES, s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Saves:", w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return math.floor(actor:combatPhysicalResist(true)) end, "%3d", "%+.0f")
		self:mouseTooltip(self.TOOLTIP_PHYS_SAVE,   s:drawColorStringBlended(self.font, ("Physical: #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return math.floor(actor:combatSpellResist(true)) end, "%3d", "%+.0f")
		self:mouseTooltip(self.TOOLTIP_SPELL_SAVE,  s:drawColorStringBlended(self.font, ("Spell   : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
		text = compare_fields(player, actor_to_compare, function(actor, ...) return math.floor(actor:combatMentalResist(true)) end, "%3d", "%+.0f")
		self:mouseTooltip(self.TOOLTIP_MENTAL_SAVE, s:drawColorStringBlended(self.font, ("Mental  : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h

		h = 0
		w = self.w * 0.25
		-- Damage Resistance
		self:mouseTooltip(self.TOOLTIP_RESIST_DAMAGE, s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Resistances   : base / cap:", w, h, 255, 255, 255, true)) h = h + self.font_h
		if player.resists.all or actor_to_compare and actor_to_compare.resists.all then
			local res = player.resists.all or 0
			local reso = actor_to_compare and actor_to_compare.resists.all or res
			if res ~= 0 or reso ~= 0 then
				local change = ""
				local cap = player.resists_cap.all or 100
				local capo = actor_to_compare and (actor_to_compare.resists_cap.all or 100) or cap
				res, reso = math.min(res, cap), math.min(reso, capo)
				if res ~= reso or cap ~= capo then
					local rdiff, capdiff = res-reso, cap-capo
					change = ("(%s%+3.0f%%#LAST#/%s%+3.0f%%#LAST#)"):format(rdiff>0 and "#LIGHT_GREEN#" or rdiff<0 and "#RED#" or "#GREY#", rdiff, capdiff>0 and "#LIGHT_GREEN#" or capdiff<0 and "#RED#" or "#GREY#", capdiff)
				end
				self:mouseTooltip(self.TOOLTIP_RESIST_ALL, s:drawColorStringBlended(self.font, ("%-14s: #00ff00#%3d%% / %d%% %s"):format("All", res, cap, change), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end
		if player.resists.absolute or actor_to_compare and actor_to_compare.resists.absolute then
			local res = player.resists.absolute or 0
			local reso = actor_to_compare and actor_to_compare.resists.absolute or res
			if res ~= 0 or reso ~= 0 then
				local change = ""
				local cap = player.resists_cap.absolute or 70
				local capo = actor_to_compare and (actor_to_compare.resists_cap.absolute or 70) or cap
				res, reso = math.min(res, cap), math.min(reso, capo)
				if res ~= reso or cap ~= capo then
					local rdiff, capdiff = res-reso, cap-capo
					change = ("(%s%+3.0f%%#LAST#/%s%+3.0f%%#LAST#)"):format(rdiff>0 and "#LIGHT_GREEN#" or rdiff<0 and "#RED#" or "#GREY#", rdiff, capdiff>0 and "#LIGHT_GREEN#" or capdiff<0 and "#RED#" or "#GREY#", capdiff)
				end
				self:mouseTooltip(self.TOOLTIP_RESIST_ABSOLUTE, s:drawColorStringBlended(self.font, ("#SALMON#%-14s: #00ff00#%3d%% / %d%% %s"):format("Absolute", res, cap, change), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end
		if player:attr("speed_resist") or actor_to_compare and actor_to_compare:attr("speed_resist") then
			local resfunc = function(actor, ...)
				if not (actor and actor:attr("speed_resist")) then return end
				return 100 - (util.bound(actor.global_speed * actor.movement_speed, 1-(actor.speed_resist_cap or 70)/100, 1)) * 100 
			end
			local res = resfunc(player)
			local reso = resfunc(actor_to_compare) or res
			local change = ""
			local cap = player.speed_resist_cap or 70
			local capo = actor_to_compare and (actor_to_compare.speed_resist_cap or 70) or cap
			if res ~= reso or cap ~= capo then
				local rdiff, capdiff = res-reso, cap-capo
				change = ("(%s%+3.0f%%#LAST#/%s%+3.0f%%#LAST#)"):format(rdiff>0 and "#LIGHT_GREEN#" or rdiff<0 and "#RED#" or "#GREY#", rdiff, capdiff>0 and "#LIGHT_GREEN#" or capdiff<0 and "#RED#" or "#GREY#", capdiff)
			end
			self:mouseTooltip(self.TOOLTIP_RESIST_SPEED, s:drawColorStringBlended(self.font, ("#SALMON#%-14s: #00ff00#%3d%% / %d%% %s"):format("Speed Res", res, cap, change), w, h, 255, 255, 255, true)) h = h + self.font_h
		end
		-- Resists vs specific damage types
		for i, t in pairs(DamageType.dam_def) do
			local res = player.resists[DamageType[t.type]] or 0
			local reso = actor_to_compare and actor_to_compare.resists[DamageType[t.type]] or res
			if res ~= 0 or reso ~= 0 then -- report restance type
				local res = player:combatGetResist(DamageType[t.type])
				local reso = actor_to_compare and actor_to_compare:combatGetResist(DamageType[t.type]) or res
				local cap = (player.resists_cap[DamageType[t.type]] or 0) + (player.resists_cap.all or 0)
				local capo = actor_to_compare and (actor_to_compare.resists_cap[DamageType[t.type]] or 0) + (actor_to_compare.resists_cap.all or 0) or cap
				local vals = ("%3.0f%% / %3.0f%%"):format(res, cap)
				local change = ""
				if res ~= reso or cap ~= capo then
					local rdiff = res-reso
					local capdiff = cap-capo
					change = ("(%s%+3.0f%%#LAST#/%s%+3.0f%%#LAST#)"):format(rdiff>0 and "#LIGHT_GREEN#" or rdiff<0 and "#RED#" or "#GREY#", rdiff, capdiff>0 and "#LIGHT_GREEN#" or capdiff<0 and "#RED#" or "#GREY#", capdiff)
				
				end
				self:mouseTooltip(self.TOOLTIP_RESIST, s:drawColorStringBlended(self.font, ("%s%-14s#LAST#: #00ff00#%3s %s"):format((t.text_color or "#WHITE#"), t.name:capitalize(), vals, change), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end

		--Resists vs actor types
		if player.resists_actor_type or actor_to_compare and actor_to_compare.resists_actor_type then
			local types = {}
			if player.resists_actor_type then table.merge(types, player.resists_actor_type) end
			if actor_to_compare and actor_to_compare.resists_actor_type then table.merge(types, actor_to_compare.resists_actor_type) end
			for t, v in pairs(types) do
				local res = table.get(player, "resists_actor_type", t) or 0
				local reso = table.get(actor_to_compare, "resists_actor_type", t) or res
				local cap = player.resists_cap_actor_type or 100
				local capo = actor_to_compare and actor_to_compare.resists_cap_actor_type or cap
				
				if res ~= 0 or reso ~= 0 then -- report resistances
					local vals = ("%3.0f%% /%3.0f%%"):format(res, cap)
					local change = ""
					if res ~= reso or cap ~= capo then
						local rdiff = res-reso
						local capdiff = cap-capo
						change = ("(%s%+.0f%%#LAST#/%s%+.0f%%#LAST#)"):format(rdiff>0 and "#LIGHT_GREEN#" or rdiff<0 and "#RED#" or "#GREY#", rdiff, capdiff>0 and "#LIGHT_GREEN#" or capdiff<0 and "#RED#" or "#GREY#", capdiff)
					end
					self:mouseTooltip(self.TOOLTIP_RESIST_DAMAGE_ACTOR, s:drawColorStringBlended(self.font, ("#ORANGE#vs %-11s#LAST#: #00ff00#%3s %s"):format(t:capitalize(), vals, change), w, h, 255, 255, 255, true)) h = h + self.font_h

				end
			end
		end
		
		h = h + self.font_h
		--Damage Affinities
		s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Damage affinities:", w, h, 255, 255, 255, true) h = h + self.font_h

		if player.damage_affinity.all or (actor_to_compare and actor_to_compare.damage_affinity.all) then
			text = compare_fields(player, actor_to_compare, function(actor, ...) return actor.damage_affinity and actor.damage_affinity.all or 0 end, "%3d%%", "%+.0f%%")
			if text ~= "  0%" then
				self:mouseTooltip(self.TOOLTIP_AFFINITY_ALL, s:drawColorStringBlended(self.font, ("All damage    : #00ff00#%s"):format(text), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end

		for i, t in pairs(DamageType.dam_def) do
			local alln = player.damage_affinity.all or 0
			local allo = actor_to_compare and actor_to_compare.damage_affinity.all or 0
			local valn = player.damage_affinity[DamageType[t.type]] or 0
			local valo = actor_to_compare and actor_to_compare.damage_affinity[DamageType[t.type]] or 0
			if valn~=0 or valo~=0 then
				text = compare_fields(player, actor_to_compare, function(actor, ...) return actor == player and valn+alln or actor == actor_to_compare and valo+allo or 0 end, "%3d%%", "%+.0f%%")
				self:mouseTooltip(self.TOOLTIP_AFFINITY, s:drawColorStringBlended(self.font, ("%s%-20s: #00ff00#%s"):format((t.text_color or "#WHITE#"), t.name:capitalize().."#LAST#", text), w, h, 255, 255, 255, true)) h = h + self.font_h
			end
		end

		-- Status Immunities
		h = 0
		w = self.w * 0.52
		self:mouseTooltip(self.TOOLTIP_STATUS_IMMUNE, s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Effect resistances:", w, h, 255, 255, 255, true)) h = h + self.font_h

		for immune_type, immune_name in pairs(self.status_immunities) do
			text = compare_fields(player, actor_to_compare, function(actor, ...) return util.bound((actor:attr(...) or 0) * 100, 0, 100) end, "%3d%%", "%+.0f%%", 1, false, false, immune_type)
			if text ~= "  0%" then
				self:mouseTooltip(self[self.immunity_tooltips[immune_type] or "TOOLTIP_SPECIFIC_IMMUNE"], s:drawColorStringBlended(self.font, ("%s: #00ff00#%s"):format(immune_name, text), w, h, 255, 255, 255, true))
				h = h + self.font_h
			end
		end

		h = 0
		w = self.w * 0.75

		self:mouseTooltip(self.TOOLTIP_ON_HIT_DAMAGE, s:drawColorStringBlended(self.font, "#LIGHT_BLUE#Damage when hit:", w, h, 255, 255, 255, true)) h = h + self.font_h

		for i, t in pairs(DamageType.dam_def) do
			if player.on_melee_hit[DamageType[t.type]] and player.on_melee_hit[DamageType[t.type]] ~= 0 then
				local dval = player.on_melee_hit[DamageType[t.type]]
				if t.tdesc then
					dval = t.tdesc(dval)
					self:mouseTooltip(self.TOOLTIP_ON_HIT_DAMAGE, s:drawColorStringBlended(self.font, ("%s"):format(dval), w, h, 255, 255, 255, true)) h = h + self.font_h
				else
					dval = Talents.damDesc(player, DamageType[t.type] ,type(dval) == "number" and dval or dval.dam)
					self:mouseTooltip(self.TOOLTIP_ON_HIT_DAMAGE, s:drawColorStringBlended(self.font, ("%s%-10s#LAST#: #00ff00#%.1f"):format((t.text_color or "#WHITE#"), t.name:capitalize(), dval), w, h, 255, 255, 255, true)) h = h + self.font_h

				end
			end
		end

	elseif kind=="equipment" then
		self:showEquipmentFrame()

	-- allow scrolling for large numbers of talents?
	elseif kind=="talents" then
		h = 0
		w = 0
		local function sort_talents()
			local talents = {}
			local get_group
			if self.talent_sorting == 1 then
				-- Get the group/display name for a given talent type
				get_group = function(t, tt)
					if tt.type:match("inscriptions/.*") then
						return "Inscriptions"
					elseif tt.type:match("uber/.*") then
						return "Prodigies"
					elseif tt.type:match(".*/objects") then
						return "Item Talents"
					end

					local cat = tt.type:gsub("/.*", ""):bookCapitalize()
					return cat.."/"..(tt.name or ""):bookCapitalize()
				end
			elseif self.talent_sorting == 2 then
				-- Alphabetically, so no groups at all.
				get_group = function(t, tt)
					return "Talents"
				end
			else
				-- Sort by usage type/speed
				get_group = function(t, tt)
					if t.mode == "activated" then
						local no_energy = util.getval(t.no_energy, player, t)
						return no_energy and "Instant" or "Activated"
					else
						return t.mode:bookCapitalize()
					end
				end
			end

			-- Process the talents
			for j, t in pairs(player.talents_def) do
				if player:knowTalent(t.id) and (not t.hide or t.hide ~= "always") then
					local lvl = player:getTalentLevelRaw(t)
					local tt = player:getTalentTypeFrom(t.type[1])

					local data = {type_name = tt,
						talent = t,
						name = ("%s (%d)"):format(t.name, lvl),
						desc = player:getTalentFullDescription(t):toString(),
					}

					if self.talent_sorting == 2 then
						if not talents["All"] then
							talents["All"] = {type_name = "All", talent_type=nil, talents={} }
						end
						table.insert(talents["All"]["talents"], data)
					else
						local group_name = get_group(t, tt)

						if not talents[group_name] then
							talents[group_name] = {type_name = group_name, talent_type=tt, talents={}}
						end
						table.insert(talents[group_name]["talents"], data)
					end
				end
			end

			local sort_tt

			-- Decide what sorting method to use
			if self.talent_sorting == 1 then
				-- Sorting of talent groups, Racial/infusions first, then alphabetical order
				local sort_rank = {"race/.*", "Inscriptions", "Prodigies", "Item Talents"} -- Relies on the groups
				sort_tt = function(a, b)
					a, b = a["type_name"], b["type_name"]
					for i, v in ipairs(sort_rank) do
						local rank_a, rank_b
						rank_a = a:match(v)
						if not rank_a then
							rank_b = b:match(v)
							if rank_b then return false end
						else
							return true
						end
					end
					return a < b
				end
			elseif self.talent_sorting == 2 then
				-- Only care about alphabetically sorting
				sort_tt = function(a, b)
					return a.name < b.name end
			else
				-- instant > activated > sustained > passive > alphabetically
				local sort_rank = {"Instant", "Activated", "Sustained", "Passive" }
				sort_tt = function(a, b)
					a, b = a["type_name"], b["type_name"]
					for i, v in ipairs(sort_rank) do
						local rank_a, rank_b
						rank_a = a:match(v)
						if not rank_a then
							rank_b = b:match(v)
							if rank_b then return false end
						else
							return true
						end
					end
					return a < b
				end
			end
			-- Sort the talent type stuff
			local sorted = {}
			if self.talent_sorting == 2 then
				if not talents["All"] or not talents["All"]["talents"] then talents["All"] = {type_name = "All", talent_type=nil, talents={} } end
				table.sort(talents["All"]["talents"], sort_tt)
				return talents
			end
			for k, v in pairs(talents) do
				sorted[#sorted+1] = v
			end

			if self.talent_sorting == 2 then
				table.sort(sorted[1], sort_tt)
				return sorted
			else
				table.sort(sorted, sort_tt)
			end

			return sorted

		end

		local sorted = sort_talents()

		-- The color used to display it
		local function get_talent_color(t)
			if t.uber then
				return "#GOLD#"
			elseif t.mode == "activated" then
				local no_energy = util.getval(t.no_energy, player, t)
				if no_energy == true then
					return "#00c91b##{italic}#"--return "#E56F48#"
				else
					return "#00c91b#"
				end
			elseif t.mode == "passive" then
				return "#LIGHT_STEEL_BLUE#"--return "#486FE5#"
			else --Sustains
				return "#C49600#"--return "#E5D848#"
			end
		end

		-- Now display it!
		for ts, tt in pairs(sorted) do
			-- Display talent type
			local tt_name = tt["type_name"]
			local talent_type_name = tt["talent_type"] and tt["talent_type"].description or tt_name or ""
			local talents = tt["talents"]
			if tt_name then
				if h + self.font_h*2 >= self.c_desc.h then h = 0 w = w + self.c_desc.w / 6 end
				self:mouseTooltip(talent_type_name, s:drawColorStringBlended(self.font, ("#{bold}##KHAKI#%s#{normal}#"):format(tt_name), w, h, 255, 255, 255, true)) h = h + self.font_h
			end

			-- Display the talents in the talent type
			for _, t in ipairs(talents) do
				if h + self.font_h >= self.c_desc.h then h = 0 w = w + self.c_desc.w / 6 end
				self:mouseTooltip(t.desc, s:drawColorStringBlended(self.font, (get_talent_color(t.talent).."%s".."#{normal}#"):format(t.name), w, h, 255, 255, 255, true)) h = h + self.font_h

			end
			-- Add extra space to separate categories
			h = h + self.font_h
		end
	end

	--put a hook here to allow adding more info to the display?  (Steampower, etc.)
	
	self.c_desc:update()
	self.changed = false
end

function _M:dump()
	local player = self.actor

	fs.mkdir("/character-dumps")
	local file = "/character-dumps/"..(player.name:gsub("[^a-zA-Z0-9_-.]", "_")).."-"..os.date("%Y%m%d-%H%M%S")..".txt"
	local fff = fs.open(file, "w")
	local labelwidth = 17
	local nl = function(s) s = s or "" fff:write(s:removeColorCodes()) fff:write("\n") end
	local nnl = function(s) s = s or "" fff:write(s:removeColorCodes()) end
	--prepare label and value
	local makelabel = function(s,r) while s:len() < labelwidth do s = s.." " end return ("%s: %s"):format(s, r) end

	local cur_exp, max_exp = player.exp, player:getExpChart(player.level+1)
	nl("  [ToME4 @ www.te4.org Character Dump]")
	nl()

	nnl(("%-32s"):format(makelabel("Sex", (player.descriptor and player.descriptor.sex) or (player.female and "Female" or "Male"))))
	nl(("STR:  %d"):format(player:getStr()))

	nnl(("%-32s"):format(makelabel("Race", (player.descriptor and player.descriptor.subrace) or player.type:capitalize())))
	nl(("DEX:  %d"):format(player:getDex()))

	nnl(("%-32s"):format(makelabel("Class", (player.descriptor and player.descriptor.subclass) or player.subtype:capitalize())))
	nl(("MAG:  %d"):format(player:getMag()))

	nnl(("%-32s"):format(makelabel("Level", ("%d"):format(player.level))))
	nl(("WIL:  %d"):format(player:getWil()))

	nnl(("%-32s"):format(makelabel("Exp", ("%d%%"):format(100 * cur_exp / max_exp))))
	nl(("CUN:  %d"):format(player:getCun()))

	nnl(("%-32s"):format(makelabel("Gold", ("%.2f"):format(player.money))))
	nl(("CON:  %d"):format(player:getCon()))

	if player.died_times then
		nl(("Times died       : %d"):format(#player.died_times))
	end
	if player.easy_mode_lifes then
		nl(("Lifes left       : %d"):format(player.easy_mode_lifes))
	end

	 -- All weapons in main hands
	local strings = {}
	for i = 1, 6 do strings[i]="" end
	if player:getInven(player.INVEN_MAINHAND) then
		for i, o in ipairs(player:getInven(player.INVEN_MAINHAND)) do
			local mean, dam = o.combat, o.combat
			if o.archery and mean then
				dam = (player:getInven("QUIVER")[1] and player:getInven("QUIVER")[1].combat)
			end
			if mean and dam then
				strings[1] = ("Accuracy(Main Hand): %3d"):format(player:combatAttack(mean))
				strings[2] = ("Damage  (Main Hand): %3d"):format(player:combatDamage(dam))
				strings[3] = ("APR     (Main Hand): %3d"):format(player:combatAPR(dam))
				strings[4] = ("Crit    (Main Hand): %3d%%"):format(player:combatCrit(dam))
				strings[5] = ("Speed   (Main Hand): %0.2f"):format(player:combatSpeed(mean))
			end
			if mean and mean.range then strings[6] = ("Range (Main Hand): %3d"):format(mean.range) end
		end
	end
	--Unarmed??
	if player:isUnarmed() then
		local mean, dam = player.combat, player.combat
		if mean and dam then
			strings[1] = ("Accuracy(Unarmed): %3d"):format(player:combatAttack(mean))
			strings[2] = ("Damage  (Unarmed): %3d"):format(player:combatDamage(dam))
			strings[3] = ("APR     (Unarmed): %3d"):format(player:combatAPR(dam))
			strings[4] = ("Crit    (Unarmed): %3d%%"):format(player:combatCrit(dam))
			strings[5] = ("Speed   (Unarmed): %0.2f"):format(player:combatSpeed(mean))
		end
		if mean and mean.range then strings[6] = ("Range (Unarmed): %3d"):format(mean.range) end
	end

	local enc, max = player:getEncumbrance(), player:getMaxEncumbrance()

	nl()
	nnl(("%-32s"):format(strings[1]))
	nnl(("%-32s"):format(makelabel("Life", ("    %d/%d"):format(player.life, player.max_life))))
	nl(makelabel("Encumbrance", enc .. "/" .. max))

	nnl(("%-32s"):format(strings[2]))
	if player:knowTalent(player.T_STAMINA_POOL) then
		nnl(("%-32s"):format(makelabel("Stamina", ("    %d/%d"):format(player:getStamina(), player.max_stamina))))
	else
		 nnl(("%-32s"):format(" "))
	end
	nl(makelabel("Difficulty", (player.descriptor and player.descriptor.difficulty) or "???"))
	nl(makelabel("Permadeath", (player.descriptor and player.descriptor.permadeath) or "???"))

	nnl(("%-32s"):format(strings[3]))
	if player:knowTalent(player.T_MANA_POOL) then
		nl(makelabel("Mana", ("    %d/%d"):format(player:getMana(), player.max_mana)))
	else
		nl()
	end
	nnl(("%-32s"):format(strings[4]))
	if player:knowTalent(player.T_POSITIVE_POOL) then
		nl(makelabel("Positive", ("    %d/%d"):format(player:getPositive(), player.max_positive)))
	else
		nl()
	end
	nnl(("%-32s"):format(strings[5]))
	if player:knowTalent(player.T_NEGATIVE_POOL) then
		nl(makelabel("Negative", ("    %d/%d"):format(player:getNegative(), player.max_negative)))
	else
		nl()
	end
	nnl(("%-32s"):format(strings[6]))
	if player:knowTalent(player.T_VIM_POOL) then
		nl(makelabel("Vim", ("    %d/%d"):format(player:getVim(), player.max_vim)))
	else
		nl()
	end
	nnl(("%-32s"):format(""))
	if player:knowTalent(player.T_EQUILIBRIUM_POOL) then
		nl((makelabel("Equilibrium", ("    %d"):format(player:getEquilibrium()))))
	else
		nl()
	end
	nnl(("%-32s"):format(""))
	if player:knowTalent(player.T_PARADOX_POOL) then
		nl((makelabel("Paradox", ("    %d"):format(player:getParadox()))))
	else
		nl()
	end

	-- All weapons in off hands
	-- Offhand attacks are with a damage penalty, that can be reduced by talents
	if player:getInven(player.INVEN_OFFHAND) then
		for i, o in ipairs(player:getInven(player.INVEN_OFFHAND)) do
			local offmult = player:getOffHandMult(o.combat)
			local mean, dam = o.combat, o.combat
			if o.archery and mean then
				dam = (player:getInven("QUIVER")[1] and player:getInven("QUIVER")[1].combat)
			end
			if mean and dam then
				nl()
				nl(("Accuracy(Off Hand): %3d"):format(player:combatAttack(mean)))
				nl(("Damage  (Off Hand): %3d"):format(player:combatDamage(dam) * offmult))
				nl(("APR     (Off Hand): %3d"):format(player:combatAPR(dam)))
				nl(("Crit    (Off Hand): %3d%%"):format(player:combatCrit(dam)))
				nl(("Speed   (Off Hand): %0.2f"):format(player:combatSpeed(mean)))
			end
			if mean and mean.range then strings[6] = ("Range (Off Hand): %3d"):format(mean.range) end
		end
	end

	nl()
	nnl(("%-32s"):format(makelabel("Fatigue", player:combatFatigue() .. "%")))
	nl(makelabel("Spellpower", player:combatSpellpower() ..""))
	nnl(("%-32s"):format(makelabel("Armor", player:combatArmor() .. "")))
	nl(makelabel("Spell Crit", player:combatSpellCrit() .."%"))
	nnl(("%-32s"):format(makelabel("Armor Hardiness", player:combatArmorHardiness() .. "%")))
	nl(makelabel("Spell Speed", player:combatSpellSpeed() ..""))
	nnl(("%-32s"):format(makelabel("Defense", player:combatDefense(true) .. "")))
	nl()
	nnl(("%-32s"):format(makelabel("Ranged Defense", player:combatDefenseRanged(true) .. "")))

	nl()
	if player.inc_damage.all then nl(makelabel("All damage", player.inc_damage.all.."%")) end
	for i, t in ipairs(DamageType.dam_def) do
		if player.inc_damage[DamageType[t.type]] and player.inc_damage[DamageType[t.type]] ~= 0 then
			nl(makelabel(t.name:capitalize().." damage", (player.inc_damage[DamageType[t.type]] + (player.inc_damage.all or 0)).."%"))
		end
	end

	nl()
	nl(makelabel("Physical Save",player:combatPhysicalResist(true) ..""))
	nl(makelabel("Spell Save",player:combatSpellResist(true) ..""))
	nl(makelabel("Mental Save",player:combatMentalResist(true) ..""))

	nl()
	if player.resists.all then nl(("All Resists: %3d%%"):format(player.resists.all, player.resists_cap.all or 0)) end
	for i, t in ipairs(DamageType.dam_def) do
		if player.resists[DamageType[t.type]] and player.resists[DamageType[t.type]] ~= 0 then
			nl(("%s Resist(cap): %3d%%(%3d%%)"):format(t.name:capitalize(), player:combatGetResist(DamageType[t.type]), (player.resists_cap[DamageType[t.type]] or 0) + (player.resists_cap.all or 0)))
		end
	end

	immune_type = "poison_immune" immune_name = "Poison Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "disease_immune" immune_name = "Disease Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "cut_immune" immune_name = "Bleed Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "confusion_immune" immune_name = "Confusion Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "blind_immune" immune_name = "Blind Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "silence_immune" immune_name = "Silence Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "disarm_immune" immune_name = "Disarm Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "pin_immune" immune_name = "Pinning Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "stun_immune" immune_name = "Stun Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "sleep_immune" immune_name = "Sleep Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "fear_immune" immune_name = "Fear Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "knockback_immune" immune_name = "Knockback Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "stone_immune" immune_name = "Stoning Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "instakill_immune" immune_name = "Instadeath Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end
	immune_type = "teleport_immune" immune_name = "Teleport Resistance" if player:attr(immune_type) then nl(("%s: %3d%%"):format(immune_name, util.bound(player:attr(immune_type) * 100, 0, 100))) end

	nl()
	local most_kill, most_kill_max = "none", 0
	local total_kill = 0
	for name, nb in pairs(player.all_kills or {}) do
		if nb > most_kill_max then most_kill_max = nb most_kill = name end
		total_kill = total_kill + nb
	end
	nl(("Number of NPC killed: %s"):format(total_kill))
	nl(("Most killed NPC: %s (%d)"):format(most_kill, most_kill_max))

	if player.winner then
		nl()
		nl("  [Winner!]")
		nl()
		for i, line in ipairs(player.winner_text) do
			nl(("%s"):format(line:removeColorCodes()))
		end
	end

	-- Talents
	nl()
	nl("  [Talents Chart]")
	nl()
	for i, tt in ipairs(player.talents_types_def) do
		 local ttknown = player:knowTalentType(tt.type)
		if not (player.talents_types[tt.type] == nil) and ttknown then
			local cat = tt.type:gsub("/.*", "")
			local catname = ("%s / %s"):format(cat:capitalize(), tt.name:capitalize())
			nl((" - %-35s(mastery %.02f)"):format(catname, player:getTalentTypeMastery(tt.type)))

			-- Find all talents of this school
			if (ttknown) then
				for j, t in ipairs(tt.talents) do
					if not t.hide then
						local typename = "class"
						if t.generic then typename = "generic" end
						local skillname = ("    %s (%s)"):format(t.name, typename)
						nl(("%-37s %d/%d"):format(skillname, player:getTalentLevelRaw(t.id), t.points))
					end
				end
			end
		end
	end

	-- Inscriptions
	local nb_inscriptions = 0
	for i = 1, player.max_inscriptions do if player.inscriptions[i] then nb_inscriptions = nb_inscriptions + 1 end end
	nl()
	nl(("  [Inscriptions (%d/%d)]"):format(nb_inscriptions, player.max_inscriptions))
	nl()
	for i = 1, player.max_inscriptions do if player.inscriptions[i] then
		local t = player:getTalentFromId("T_"..player.inscriptions[i])
		local desc = player:getTalentFullDescription(t)
		nl(("%s"):format(t.name))
	end end

	 -- Current Effects

	 nl()
	 nl("  [Current Effects]")
	 nl()

	for tid, act in pairs(player.sustain_talents) do
		if act then nl("- "..player:getTalentFromId(tid).name)	end
	end
	for eff_id, p in pairs(player.tmp) do
		local e = player.tempeffect_def[eff_id]
		if e.status == "detrimental" then
			 nl("+ "..e.desc)
		else
			 nl("- "..e.desc)
		end
	end

	-- Quests, Active and Completed

	local first = true
	for id, q in pairs(game.party.quests or {}) do
		if q:isEnded() then
			if first then
					nl()
					nl("  [Completed Quests]")
					nl()
					first=false
			end
			nl(" -- ".. q.name)
			nl(q:desc(game.party):gsub("#.-#", "   "))
		end
	end

	 first=true
	for id, q in pairs(game.party.quests or {}) do
		if not q:isEnded() then
			if first then
					first=false
					nl()
					nl("  [Active Quests]")
					nl()
				end
			nl(" -- ".. q.name)
			nl(q:desc(game.party):gsub("#.-#", "   "))
		end
	end


	--All Equipment
	nl()
	nl("  [Character Equipment]")
	nl()
	local index = 0
	for inven_id =  1, #player.inven_def do
		if player.inven[inven_id] and player.inven_def[inven_id].is_worn then
			nl((" %s"):format(player.inven_def[inven_id].name))

			for item, o in ipairs(player.inven[inven_id]) do
				if not self.filter or self.filter(o) then
					local char = string.char(string.byte('a') + index)
					nl(("%s) %s"):format(char, o:getName{force_id=true}))
					nl(("   %s"):format(tostring(o:getTextualDesc())))
					if o.droppedBy then
						nl(("   Dropped by %s"):format(o.droppedBy))
					end
					index = index + 1
				end
			end
		end
	end

	nl()
	nl("  [Player Achievements]")
	nl()
	local achs = {}
	for id, data in pairs(player.achievements or {}) do
		local a = world:getAchievementFromId(id)
		achs[#achs+1] = {id=id, data=data, name=a.name}
	end
	table.sort(achs, function(a, b) return a.name < b.name end)
	for i, d in ipairs(achs) do
		local a = world:getAchievementFromId(d.id)
		nl(("'%s' was achieved for %s At %s"):format(a.name, a.desc, d.data.when))
	end

	nl()
	nl("  [Character Inventory]")
	nl()
	for item, o in ipairs(player:getInven("INVEN")) do
		if not self.filter or self.filter(o) then
			local char = " "
			if item < 26 then string.char(string.byte('a') + item - 1) end
			nl(("%s) %s"):format(char, o:getName{force_id=true}))
			nl(("   %s"):format(tostring(o:getTextualDesc())))
			if o.droppedBy then
				nl(("   Dropped by %s"):format(o.droppedBy))
			end
		end
	end

	nl()
	nl("  [Last Messages]")
	nl()

	nl(table.concat(game.uiset.logdisplay:getLines(40), "\n"):removeColorCodes())

	fff:close()

	Dialog:simplePopup("Character dump complete", "File: "..fs.getRealPath(file))
end
