-- TE4 - T-Engine 4
-- Copyright (C) 2009 - 2017 Nicolas Casalini
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
local Module = require "engine.Module"
local Downloader = require "engine.dialogs.Downloader"
local Entity = require "engine.Entity"
local Dialog = require "engine.ui.Dialog"
local Image = require "engine.ui.Image"
local Textzone = require "engine.ui.Textzone"
local ListColumns = require "engine.ui.ListColumns"
local Button = require "engine.ui.Button"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(mode)
	if not mode then mode = core.steam and "steam" or "te4" end
	self.mode = mode

	self.cart = {}

	self.base_title_text = game.__mod_info.long_name.." #GOLD#Online Store#LAST#"
	Dialog.init(self, self.base_title_text, game.w * 0.8, game.h * 0.8)

	self.categories_icons = {
		pay2die = Entity.new{image="/data/gfx/mtx/ui/category_pay2die.png"},
		community = Entity.new{image="/data/gfx/mtx/ui/category_community.png"},
		cosmetic = Entity.new{image="/data/gfx/mtx/ui/category_cosmetic.png"},
		misc = Entity.new{image="/data/gfx/mtx/ui/category_misc.png"},
	}
	local in_cart_icon = Entity.new{image="/data/gfx/mtx/ui/in_cart.png"},

	self:generateList()
	self.recap = {}

	self.c_waiter = Textzone.new{auto_width=1, auto_height=1, text="#YELLOW#-- connecting to server... --"}
	self.c_list = ListColumns.new{width=self.iw - 350, height=self.ih, item_height=132, hide_columns=true, scrollbar=true, sortable=true, columns={
		{name="", width=100, display_prop="", direct_draw=function(item, x, y)
			item.img:toScreen(nil, x+2, y+2, 128, 128)
			item.category_img:toScreen(nil, x+2+64+32, y+2+64+32, 32, 32)
			if self.cart[item.id_purchasable] and item.nb_purchase > 0 then in_cart_icon:toScreen(nil, x+2, y+2, 128, 128) end
			item.txt:display(x+10+130, y+2 + (128 - item.txt.h) / 2, 0)
		end},
	}, list=self.list, all_clicks=true, fct=function(item, _, button) self:use(item, button) end, select=function(item, sel) self:onSelectItem(item) end}
	self.c_list.on_focus_change = function(_, v) if not v then game:tooltipHide() end end

	self.c_do_purchase = Button.new{text="Purchase", fct=function() self:doPurchase() end}

	self.c_recap = ListColumns.new{width=350, height=self.ih - self.c_do_purchase.h, scrollbar=true, columns={
		{name="Name", width=50, display_prop="recap_name"},
		{name="Price", width=35, display_prop="recap_price"},
		{name="Qty", width=15, display_prop="recap_qty"},
	}, list=self.recap, all_clicks=true, fct=function(item, _, button)
		if item.total then return end
		if button == "left" then button = "right"
		elseif button == "right" then button = "left" end
		self:use(item.item, button)
	end, select=function(item, sel) end}

	self:loadUI{
		{vcenter=0, hcenter=0, ui=self.c_waiter},
		{left=0, top=0, ui=self.c_list},
		{right=0, top=0, ui=self.c_recap},
		{right=0, bottom=0, ui=self.c_do_purchase},
	}
	self:setupUI(false, false)
	self:toggleDisplay(self.c_list, false)

	self.key:addBinds{
		ACCEPT = "EXIT",
		EXIT = function()
			game:unregisterDialog(self)
			if on_exit then on_exit() end
		end,
	}
end

function _M:onSelectItem(item)
	if self.in_paying_ui then game:tooltipHide() return end
	if not item then return game:tooltipHide() end

	if item.last_display_x then
		game:tooltipDisplayAtMap(item.last_display_x + self.c_list.w, item.last_display_y, item.tooltip)
	else
		game:tooltipHide()
	end
end

function _M:use(item, button)
	if self.in_paying_ui then return end
	if not item then return end
	if button == "right" then
		item.nb_purchase = math.max(0, item.nb_purchase - 1)
		if item.nb_purchase <= 0 then self.cart[item.id] = nil end
	elseif button == "left" then
		if item.can_multiple then
			item.nb_purchase = item.nb_purchase + 1
		else
			item.nb_purchase = math.min(1, item.nb_purchase + 1)
		end
		self.cart[item.id] = true
	end

	self:updateCart()
end

function _M:currencyDisplay(v)
	if self.user_currency then
		return ("%0.2f %s"):format(v, self.user_currency)
	else
		return ("%d coins"):format(v)
	end
end

function _M:updateCart()
	local nb_items, total_sum = 0, 0
	table.empty(self.recap)

	for id, ok in pairs(self.cart) do if ok then
		local item = self.purchasables[id]
		nb_items = nb_items + item.nb_purchase
		total_sum = total_sum + item.nb_purchase * item.price

		self.recap[#self.recap+1] = {
			sort_name = item.name,
			recap_name = item.img:getDisplayString()..item.name,
			recap_price = self:currencyDisplay(item.price * item.nb_purchase),
			recap_qty = item.nb_purchase,
			item = item,
		}
	end end
	table.sort(self.recap, "sort_name")
	self.recap[#self.recap+1] = {
		recap_name = "#{bold}#TOTAL#{normal}#",
		recap_price = self:currencyDisplay(total_sum),
		recap_qty = nb_items,
		total = true,
	}

	self.c_recap:setList(self.recap, true)
	self:updateTitle(self.base_title_text..("  (%d items in cart, %s)"):format(nb_items, self:currencyDisplay(total_sum)))

	self:toggleDisplay(self.c_do_purchase, nb_items > 0)
end

function _M:doPurchase()
	self.in_paying_ui = true
	if core.steam then self:doPurchaseSteam()
	else self:doPurchaseTE4()
	end
end

function _M:installShimmer(item)
	if not core.webview then
		Dialog:simpleLongPopup(item.name, "In-game browser is inoperant or disabled, impossible to auto-install shimmer pack.\nPlease go to https://te4.org/ to download it manually.", 600)
		return
	end

	-- When download is finished, we will try to load the addon dynamically and add it to the current character. We can do taht because cosmetic addons dont require much setup
	local when_done = function()
		local found = false
		local addons = Module:listAddons(game.__mod_info, true)
		for _, add in ipairs(addons) do if add.short_name == "cosmetic-"..item.effect then
			found = true

			local hooks_list = {}
			Module:loadAddon(game.__mod_info, add, {}, hooks_list)

			dofile("/data/gfx/mtx-shimmers/"..item.effect..".lua")

			Dialog:simplePopup(item.name, [[Shimmer pack installed!]])
			break
		end end

		if not found then
			Dialog:simpleLongPopup(item.name, [[Could not dynamically link addon to current character, maybe the installation weng wrong.
	You can fix that by manually downloading the shimmer addon from https://te4.org/ and placing it in game/addons/ folder.]], 600)
		end
	end

	local co co = coroutine.create(function()
		local filename = ("/addons/%s-cosmetic-%s.teaa"):format(game.__mod_info.short_name, item.effect)
		print("==> downloading", "https://te4.org/download-mtx/"..item.id_purchasable, filename)
		local d = Downloader.new{title="Downloading cosmetic pack: #LIGHT_GREEN#"..item.name, co=co, dest=filename..".tmp", url="https://te4.org/download-mtx/"..item.id_purchasable, allow_downloads={addons=true}}
		local ok = d:start()
		if ok then
			local wdir = fs.getWritePath()
			local _, _, dir, name = filename:find("(.+/)([^/]+)$")
			if dir then
				fs.setWritePath(fs.getRealPath(dir))
				fs.delete(name)
				fs.rename(name..".tmp", name)
				fs.setWritePath(wdir)

				when_done()
			end
		end
	end)
	print(coroutine.resume(co))
end

function _M:paymentSuccess()
	self.in_paying_ui = false

	local list = {}
	for id, ok in pairs(self.cart) do if ok then
		local item = self.purchasables[id]
		if item.is_shimmer then
			self:installShimmer(item)
			list[#list+1] = ("- #{bold}##ROYAL_BLUE#%s #SLATE#x%d#WHITE##{normal}#: The pack should be downloading or even finished by now."):format(item.name, item.nb_purchase)
		elseif item.self_event or item.community_event then
			list[#list+1] = ("- #{bold}##ROYAL_BLUE#%s #SLATE#x%d#WHITE##{normal}#: You can now trigger it whenever you are ready."):format(item.name, item.nb_purchase)
		elseif item.effect == "vaultspace" then
			list[#list+1] = ("- #{bold}##ROYAL_BLUE#%s #SLATE#x%d#WHITE##{normal}#: Your available vault space has increased."):format(item.name, item.nb_purchase)
		end
	end end

	game:unregisterDialog(self)
	Dialog:simpleLongPopup("Payment", "Payment accepted.\n"..table.concat(list, "\n"), 700)
end

function _M:paymentFailure()
	self.in_paying_ui = false
end

function _M:doPurchaseSteam()
	local popup = Dialog:simplePopup("Connecting to Steam", "Steam Overlay should appear, if it does not please make sure it you have not disabled it.", nil, true)

	local cart = {}
	for id, ok in pairs(self.cart) do if ok then
		local item = self.purchasables[id]
		cart[#cart+1] = {
			id_purchasable = id,
			nb_purchase = item.nb_purchase,
		}
	end end

	local function onMTXResult(id_cart, ok)
		local finalpopup = Dialog:simplePopup("Connecting to Steam", "Finalizing transaction with Steam servers...", nil, true)
		profile:registerTemporaryEventHandler("MicroTxnSteamFinalizeCartResult", function(e)
			game:unregisterDialog(finalpopup)
			if e.success then
				self:paymentSuccess()
			else
				Dialog:simplePopup("Payment", "Payment refused, you have not been billed.")
				self:paymentFailure()
			end
		end)
		core.profile.pushOrder(string.format("o='MicroTxn' suborder='steam_finalize_cart' module=%q store=%q id_cart=%q", game.__mod_info.short_name, "steam", id_cart))
	end

	profile:registerTemporaryEventHandler("MicroTxnListCartResult", function(e)
		game:unregisterDialog(popup)
		if e.success then
			core.steam.waitMTXResult(onMTXResult)
		else
			Dialog:simplePopup("Payment", "Payment refused, you have not been billed.")
			self:paymentFailure()
		end
	end)
	core.profile.pushOrder(string.format("o='MicroTxn' suborder='create_cart' module=%q store=%q cart=%q", game.__mod_info.short_name, core.steam and "steam" or "te4", table.serialize(cart)))
end

function _M:buildTooltip(item)
	local text = {}
	if item.community_event then
		text[#text+1] = [[- Once you have purchased a community event you will be able to trigger it at any later date, on whichever character you choose.
Community events once triggered will activate for #{bold}#every player currently logged on#{normal}# including yourself. Every player receiving it will know you sent it and thus that you are to thank for it.
To activate it you will need to have your online events option set to "all" (which is the default value).]]
	end
	if item.self_event then
		text[#text+1] = [[- Once you have purchased an event you will be able to trigger it at any later date, on whichever character you choose.
To activate it you will need to have your online events option set to "all" (which is the default value).]]
	end
	if item.once_per_character then
		text[#text+1] = [[- This event can only be received #{bold}#once per character#{normal}#. Usualy because it adds a new zone or effect to the game that would not make sense to duplicate.]]
	end
	if item.is_shimmer then
		text[#text+1] = [[- Once purchased the game will automatically install the shimmer pack to your game and enable it for your current character too (you will still need to use the Mirror of Reflection to switch them on).
#LIGHT_GREEN#Bonus perk:#LAST# purchasing any shimmer pack will also give your characters a portable Mirror of Reflection to be able to change your appearance anywhere, anytime!]]
	end
	if item.effect == "vaultspace" then
		text[#text+1] = [[- Once purchased your vault space is permanently increased.]]
	end
	return table.concat(text, '\n')
end

function _M:generateList()
	self.list = {}
	self.purchasables = {}

	profile:registerTemporaryEventHandler("MicroTxnListPurchasables", function(e)
		if e.error then
			Dialog:simplePopup("Online Store", e.error:capitalize())
			game:unregisterDialog(self)
			return
		end

		if not e.data then return end
		e.data = e.data:unserialize()

		if e.data.infos.steam then
			self.user_country = e.data.infos.steam.country
			self.user_currency = e.data.infos.steam.currency
		end

		local list = {}
		for _, res in ipairs(e.data.list) do
			res.id_purchasable = res.id
			res.nb_purchase = 0
			res.img = Entity.new{image=res.image}
			res.category_img = self.categories_icons[res.category or "misc"] or self.categories_icons.misc
			res.txt = Textzone.new{width=self.iw - 10 - 132 - 350, auto_height=true, text=("%s (%s)\n#SLATE##{italic}#%s#{normal}#"):format(res.name, self:currencyDisplay(res.price), res.desc)}
			res.tooltip = self:buildTooltip(res)
			list[#list+1] = res
			self.purchasables[res.id] = res
		end
		self.list = list
		self.c_list:setList(list)
		self:toggleDisplay(self.c_list, true)
		self:toggleDisplay(self.c_waiter, false)
		self:setFocus(self.c_list)
		game.log("===balance: %s", tostring(e.data.infos.balance))
	end)
	core.profile.pushOrder(string.format("o='MicroTxn' suborder='list_purchasables' module=%q store=%q", game.__mod_info.short_name, core.steam and "steam" or "te4"))
end
