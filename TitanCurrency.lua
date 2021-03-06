﻿-- **************************************************************************
-- * Titan Currency .lua - VERSION 7.3
-- **************************************************************************
-- * by Greenhorns @ Vek'Nilash
-- * This mod displays all active currency on your curent toon
-- * in a tooltip.
-- *
-- **************************************************************************

-- ******************************** Constants *******************************
local TITAN_CURRENCY_ID = "Currency"
local TITAN_CURRENCY_VERSION = "7.3"

-- ******************************** Variables *******************************
local CURRENCY_INITIALIZED = false
local LB = LibStub("AceLocale-3.0"):GetLocale("Titan_Currency", true)
-- ******************************** Functions *******************************

-- **************************************************************************
-- NAME : TitanPanelCurrencyButton_OnLoad()
-- DESC : Registers the add on upon it loading
-- **************************************************************************
function TitanPanelCurrencyButton_OnLoad(self)
	self.registry = {
		id = TITAN_CURRENCY_ID,
		category = "Information",
		version = TITAN_CURRENCY_VERSION,
		menuText = LB["TITAN_CURRENCY_MENU_TEXT"],
		tooltipTitle = LB["TITAN_CURRENCY_TOOLTIP"],
		tooltipTextFunction = "TitanPanelCurrencyButton_GetTooltipText",
		buttonTextFunction = "TitanPanelCurrencyButton_GetButtonText",
		controlVariables = {
			DisplayOnRightSide = true
		},
		savedVariables = {
			DisplayOnRightSide = false,
			SelectedCurrency = {name="gold"}
		}
	}

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
end

-- *******************************************************************************************
-- NAME: TitanPanelCurrencyButton_OnEvent()
-- DESC: Event handler for the TitanPanelCurrencyButton
-- *******************************************************************************************
function TitanPanelCurrencyButton_OnEvent(self, event, ...)
	if (not CURRENCY_INITIALIZED) and event == "PLAYER_ENTERING_WORLD" then
		TitanPanelButton_UpdateButton(TITAN_CURRENCY_ID)
		CURRENCY_INITIALIZED = true
		return
	end

	-- Fired when gold is spent or received
	if CURRENCY_INITIALIZED and event == "PLAYER_MONEY" then
		local cur = TitanGetVar(TITAN_CURRENCY_ID, "SelectedCurrency")
		if cur.name == "gold" then
			TitanPanelButton_UpdateButton(TITAN_CURRENCY_ID)
		end
		return
	end
	
	-- Fired for all currencies except gold
	if CURRENCY_INITIALIZED and event == "CURRENCY_DISPLAY_UPDATE" then
		local cur = TitanGetVar(TITAN_CURRENCY_ID, "SelectedCurrency")
		if cur.name ~= "gold" then
			local _, amount = GetCurrencyInfo(cur.link)
			cur.count = amount
			TitanSetVar(TITAN_CURRENCY_ID, "SelectedCurrency", cur)
			TitanPanelButton_UpdateButton(TITAN_CURRENCY_ID)
		end
		return
	end
end

-- *******************************************************************************************
-- NAME: TitanPanelCurrencyButton_OnClick()
-- DESC: Mouse click handler for the TitanPanelCurrencyButton
-- *******************************************************************************************
function TitanPanelCurrencyButton_OnClick(self, button)
	if (button == "LeftButton") then
		-- show the currency tab
		ToggleCharacter("TokenFrame")
		return
	end
	-- RightButton handler doesn't need to be manually called
	-- See TitanPanelRightClickMenu_PrepareCurrencyMenu below
end

-- *******************************************************************************************
-- NAME: TitanPanelRightClickMenu_PrepareCurrencyMenu()
-- DESC: Create the right-click menu
-- NOTE: This naming convention is required by the Titan Panel API (TitanUtils.lua:1498)
-- *******************************************************************************************
function TitanPanelRightClickMenu_PrepareCurrencyMenu(self)
	TitanPanelRightClickMenu_AddTitle("Select currency to show")
	TitanPanelRightClickMenu_AddSpacer()

	-- Gold is considered separately from the other currencies by the Blizzard API
	local info = L_UIDropDownMenu_CreateInfo()	
	info.text = "gold"
	info.menuList = 1
	info.checked = TitanGetVar(TITAN_CURRENCY_ID, "SelectedCurrency").name == "gold"
	info.func = function()
		TitanSetVar(TITAN_CURRENCY_ID, "SelectedCurrency", {name="gold"})
		TitanPanelButton_UpdateButton(TITAN_CURRENCY_ID)
	end
	L_UIDropDownMenu_AddButton(info)
	
	local cCount = GetCurrencyListSize()
	for index=1, cCount do
		local name, _, _, isUnused, _, count, icon, id = GetCurrencyListInfo(index)
		if (count ~= 0) and not isUnused then
			info.text = name
			info.menuList = index + 1
			info.checked = name == TitanGetVar(TITAN_CURRENCY_ID, "SelectedCurrency").name
			info.func = function()
				TitanSetVar(TITAN_CURRENCY_ID, "SelectedCurrency",
							{name=name, icon=icon, count=count, link=GetCurrencyListLink(index)})
				TitanPanelButton_UpdateButton(TITAN_CURRENCY_ID)
			end
			L_UIDropDownMenu_AddButton(info)
		end
	end
	
	TitanPanelRightClickMenu_AddSpacer2()

	local info = L_UIDropDownMenu_CreateInfo()
	info.text = "Close Menu"
	info.notCheckable = true
	info.func = function() L_CloseDropDownMenus() end
	L_UIDropDownMenu_AddButton(info)
end

local function get_formatted_gold(options)
	-- These are the colors used by the TitanGold addon
	local gold_effect = "|cFFFFFF00"
	local silver_effect = "|cFFCCCCCC"
	local copper_effect = "|cFFFF6600"
	
	if options and options.use_icons then
		gold_effect = "|TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
		silver_effect = "|TInterface\\MoneyFrame\\UI-SilverIcon:0|t"
		copper_effect = "|TInterface\\MoneyFrame\\UI-CopperIcon:0|t"
	end
	
	local money = GetMoney()
	local gold = BreakUpLargeNumbers(money / 100 / 100)
	local silver = (money / 100) % 100
	local copper = money % 100
	return string.format("%s%sg %s%ds %s%dc", gold_effect, gold,
						 silver_effect, silver, copper_effect, copper)
end

-- *******************************************************************************************
-- NAME: TitanPanelCurrencyButton_GetButtonText()
-- DESC: Generate the text to be displayed on the TitanPanelCurrencyButton
-- *******************************************************************************************
function TitanPanelCurrencyButton_GetButtonText(self)
	local selected_currency = TitanGetVar(TITAN_CURRENCY_ID, "SelectedCurrency")

	if selected_currency.name == "gold" then
		return get_formatted_gold({use_icons=true})
	end
	
	return "|T"..selected_currency.icon..":16|t "..selected_currency.count.."  "..selected_currency.name
end

-- *******************************************************************************************
-- NAME: TitanPanelCurrencyButton_GetTooltipText()
-- DESC: Gets our tool-tip text, what appears when we hover over our item on the Titan bar.
-- *******************************************************************************************
function TitanPanelCurrencyButton_GetTooltipText()
	local cCount = GetCurrencyListSize()
	local tooltip = {}
	for index=1, cCount do
		local name, _, _, isUnused, _, count, icon = GetCurrencyListInfo(index)
		if count ~= 0 and not isUnused and icon ~= nil then
			tooltip[#tooltip + 1] = name.."--".."\t"..count.." |T"..icon..":16|t"
		end
	end
	tooltip[#tooltip + 1] = "Gold--\t"..get_formatted_gold()
	return table.concat(tooltip, "|r\n")
end
