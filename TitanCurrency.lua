-- **************************************************************************
-- * Titan Currency .lua - VERSION 5.4
-- **************************************************************************
-- * by Greenhorns @ Vek'Nilash
-- * This mod will display all the Currency you have on the curent toon
-- * in a tool tip.  It shows the curent Toons Gold amount on the Titan Panel
-- * bar.
-- *
-- **************************************************************************

-- ******************************** Constants *******************************
local TITAN_CURRENCY_ID = "Currency";
local TITAN_CURRENCY_VERSION = "5.1";

-- ******************************** Variables *******************************
local CURRENCY_INITIALIZED = false;
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
	};

	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_MONEY");
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
end

-- *******************************************************************************************
-- NAME: TitanPanelCurrencyButton_OnEvent()
-- DESC: Event handler for the TitanPanelCurrencyButton
-- *******************************************************************************************
function TitanPanelCurrencyButton_OnEvent(self, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if (not CURRENCY_INITIALIZED) then
			TitanPanelButton_UpdateButton(TITAN_CURRENCY_ID);
			CURRENCY_INITIALIZED = true;
		end
		return;
	end

	-- Fired when gold is spent or received
	if (event == "PLAYER_MONEY") and CURRENCY_INITIALIZED then
		TitanPanelButton_UpdateButton(TITAN_CURRENCY_ID);
		return;
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
		ToggleCharacter("TokenFrame");
		return;
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

local function get_formatted_gold()
	-- These are the colors used by the TitanGold addon
	local gold_color = "|cFFFFFF00"
	local silver_color = "|cFFCCCCCC"
	local copper_color = "|cFFFF6600"
	local money = GetMoney();
	local gold = BreakUpLargeNumbers(money / 100 / 100)
	local silver = (money / 100) % 100
	local copper = money % 100
	return string.format("%s%sg %s%ds %s%dc", gold_color, gold, silver_color, silver, copper_color, copper)
end

-- *******************************************************************************************
-- NAME: TitanPanelCurrencyButton_GetButtonText()
-- DESC: Generate the text to be displayed on the TitanPanelCurrencyButton
-- *******************************************************************************************
function TitanPanelCurrencyButton_GetButtonText(self)
	local selected_currency = TitanGetVar(TITAN_CURRENCY_ID, "SelectedCurrency")

	if selected_currency.name == "gold" then
		return get_formatted_gold()
	end
	
	return "|T"..selected_currency.icon..":16|t "..selected_currency.count.."  "..selected_currency.name;
end

-- *******************************************************************************************
-- NAME: TitanPanelCurrencyButton_GetTooltipText()
-- DESC: Gets our tool-tip text, what appears when we hover over our item on the Titan bar.
-- *******************************************************************************************
function TitanPanelCurrencyButton_GetTooltipText()
	local display="";
	local tooltip="";
	local name, isHeader, isExpanded, isUnused, isWatched, count, icon, maximum, hasWeeklyLimit, currentWeeklyAmount, unknown;
	cCount = GetCurrencyListSize();
	for index=1, cCount do
		name, isHeader, isExpanded, isUnused, isWatched, count, icon, maximum, hasWeeklyLimit, currentWeeklyAmount, unknown = GetCurrencyListInfo(index)
		if (count ~= 0) and not isUnused then
			if icon ~= nil then
				display=name.."--".."\t"..count.." |T"..icon..":16|t"
			end
			tooltip=strconcat(tooltip,display,"|r\n")
		end
		myindex=index
	end
	final_tooltip=tooltip
	return ""..final_tooltip;
end
