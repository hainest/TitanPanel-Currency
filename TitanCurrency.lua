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
local CURRENCY_VARIABLES_LOADED = false;
local CURRENCY_ENTERINGWORLD = false;
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
			DisplayOnRightSide = false
		}
	};

	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_MONEY");
	self:RegisterEvent("VARIABLES_LOADED");
	MoneyFrame_Update("TitanPanelCurrencyButton", TitanPanelCurrencyButton_FindGold());
end

function TitanPanelCurrencyButton_OnEvent(self, event, ...)
	if (event == "VARIABLES_LOADED") then
		CURRENCY_VARIABLES_LOADED = true;
		if (CURRENCY_ENTERINGWORLD) then
			TitanPanelCurrencyButton_Initialize_Array(self);
		end
		return;
	end

	if ( event == "PLAYER_ENTERING_WORLD" ) then
		CURRENCY_ENTERINGWORLD = true;
		if (CURRENCY_VARIABLES_LOADED) then
			TitanPanelCurrencyButton_Initialize_Array(self);
		end
		return;
	end

	if (event == "PLAYER_MONEY") then
		if (CURRENCY_INITIALIZED) then
			MoneyFrame_Update("TitanPanelCurrencyButton", TitanPanelCurrencyButton_FindGold());
		end
		return;
	end
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

-- *******************************************************************************************
-- NAME: TitanPanelCurrencyButton_FindGold()
-- DESC: This routines determines which gold total the ui wants (server or player) then calls it and returns it
-- *******************************************************************************************
function TitanPanelCurrencyButton_FindGold()
	local ttlgold = 0;
	ttlgold = GetMoney("player");
	return ttlgold;
end

function TitanPanelCurrencyButton_Initialize_Array(self)
	CURRENCY_INITIALIZED = true;
	MoneyFrame_Update("TitanPanelCurrencyButton", TitanPanelCurrencyButton_FindGold());
end
