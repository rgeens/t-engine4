-- ToME - Tales of Middle-Earth
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
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
local Mouse = require "engine.Mouse"
local TooltipsData = require "mod.class.interface.TooltipsData"

module(..., package.seeall, class.inherit(TooltipsData))

function _M:init(x, y, w, h, bgcolor)
	self.display_x = x
	self.display_y = y
	self.w, self.h = w, h
	self.bgcolor = bgcolor
	self.font = core.display.newFont("/data/font/VeraMono.ttf", 14)
	self.mouse = Mouse.new()
	self:resize(x, y, w, h)
end

--- Resize the display area
function _M:resize(x, y, w, h)
	self.display_x, self.display_y = x, y
	self.mouse.delegate_offset_x = x
	self.mouse.delegate_offset_y = y
	self.w, self.h = w, h
	self.font_h = self.font:lineSkip()
	self.font_w = self.font:size(" ")
	self.bars_x = self.font_w * 9
	self.bars_w = self.w - self.bars_x - 5
	self.surface = core.display.newSurface(w, h)
	self.texture, self.texture_w, self.texture_h = self.surface:glTexture()

	local tex_bg = core.display.loadImage("/data/gfx/ui/player-display.png")
	local tex_up = core.display.loadImage("/data/gfx/ui/player-display-top.png")
	local bw, bh = tex_bg:getSize()
	self.bg_surface = core.display.newSurface(w, h)
	local i = 0
	while i < h do
		self.bg_surface:merge(tex_bg, 0, i)
		i = i + bh
	end
	self.bg_surface:merge(tex_up, 0, 0)
end

function _M:mouseTooltip(text, _, _, _, w, h, x, y)
	self.mouse:registerZone(x, y, w, h, function(button) game.tooltip_x, game.tooltip_y = 1, 1; game.tooltip:displayAtMap(nil, nil, game.w, game.h, text) end)
end

-- Displays the stats
function _M:display()
	local player = game.player
	if not player or not player.changed then return self.surface end

	self.mouse:reset()
	local s = self.surface

	if self.bg_surface then
		s:erase(self.bgcolor[1], self.bgcolor[2], self.bgcolor[3])
		s:merge(self.bg_surface, 0, 0)
	else
		s:erase(self.bgcolor[1], self.bgcolor[2], self.bgcolor[3])
	end

	local cur_exp, max_exp = player.exp, player:getExpChart(player.level+1)

	local h = 6
	local x = 2
	self:mouseTooltip(self.TOOLTIP_LEVEL, s:drawColorStringBlended(self.font, "Level: #00ff00#"..player.level, x, h, 255, 255, 255)) h = h + self.font_h
	self:mouseTooltip(self.TOOLTIP_LEVEL, s:drawColorStringBlended(self.font, ("Exp:  #00ff00#%2d%%"):format(100 * cur_exp / max_exp), x, h, 255, 255, 255)) h = h + self.font_h
	self:mouseTooltip(self.TOOLTIP_GOLD, s:drawColorStringBlended(self.font, ("Gold: #00ff00#%0.2f"):format(player.money or 0), x, h, 255, 255, 255)) h = h + self.font_h

	h = h + self.font_h

	self:mouseTooltip(self.TOOLTIP_STRDEXCON, s:drawColorStringBlended(self.font, ("Str/Dex/Con: #00ff00#%3d/%3d/%3d"):format(player:getStr(), player:getDex(), player:getCon()), x, h, 255, 255, 255)) h = h + self.font_h
	self:mouseTooltip(self.TOOLTIP_INTWISCHA, s:drawColorStringBlended(self.font, ("Int/Wis/Cha: #00ff00#%3d/%3d/%3d"):format(player:getInt(), player:getWis(), player:getCha()), x, h, 255, 255, 255)) h = h + self.font_h
	h = h + self.font_h

	s:erase(colors.VERY_DARK_RED.r, colors.VERY_DARK_RED.g, colors.VERY_DARK_RED.b, 255, self.bars_x, h, self.bars_w, self.font_h)
	s:erase(colors.DARK_RED.r, colors.DARK_RED.g, colors.DARK_RED.b, 255, self.bars_x, h, self.bars_w * player.life / player.max_life, self.font_h)
	self:mouseTooltip(self.TOOLTIP_LIFE, s:drawColorStringBlended(self.font, ("#c00000#Life:    #ffffff#%d/%d"):format(player.life, player.max_life), x, h, 255, 255, 255)) h = h + self.font_h

	if player:knowTalent(player.T_MANA_POOL) then
		s:erase(0x7f / 5, 0xff / 5, 0xd4 / 5, 255, self.bars_x, h, self.bars_w, self.font_h)
		s:erase(0x7f / 2, 0xff / 2, 0xd4 / 2, 255, self.bars_x, h, self.bars_w * player:getMana() / player.max_mana, self.font_h)
		self:mouseTooltip(self.TOOLTIP_MANA, s:drawColorStringBlended(self.font, ("#7fffd4#Mana:    #ffffff#%d/%d"):format(player:getMana(), player.max_mana), x, h, 255, 255, 255)) h = h + self.font_h
	end

	if savefile_pipe.saving then h = h + self.font_h s:drawColorStringBlended(self.font, "#YELLOW#Saving...", x, h, 255, 255, 255) h = h + self.font_h end

	h = h + self.font_h
	for eff_id, p in pairs(player.tmp) do
		local e = player.tempeffect_def[eff_id]
		local desc = e.long_desc(player, p)
		if e.status == "detrimental" then
			self:mouseTooltip(desc, s:drawColorStringBlended(self.font, ("#LIGHT_RED#%s"):format(e.desc), x, h, 255, 255, 255)) h = h + self.font_h
		else
			self:mouseTooltip(desc, s:drawColorStringBlended(self.font, ("#LIGHT_GREEN#%s"):format(e.desc), x, h, 255, 255, 255)) h = h + self.font_h
		end
	end

	s:updateTexture(self.texture)
	return s
end

function _M:toScreen()
	self:display()
	self.texture:toScreenFull(self.display_x, self.display_y, self.w, self.h, self.texture_w, self.texture_h)
end
