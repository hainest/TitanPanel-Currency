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
			DisplayOnRightSide = false
		}
	};

	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_MONEY");
end

function TitanPanelCurrencyButton_OnEvent(self, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if (not CURRENCY_INITIALIZED) then
			TitanPanelButton_UpdateButton(TITAN_CURRENCY_ID);
			CURRENCY_INITIALIZED = true;
		end
		return;
	end

	if (event == "PLAYER_MONEY") then
		if (CURRENCY_INITIALIZED) then
			TitanPanelButton_UpdateButton(TITAN_CURRENCY_ID);
		end
		return;
	end
end

-- *******************************************************************************************
-- NAME: TitanPanelCurrencyButton_GetButtonText()
-- DESC: Generate the text to be displayed on the TitanPanelCurrencyButton
-- *******************************************************************************************
function TitanPanelCurrencyButton_GetButtonText(self)
	-- These are the colors used by the TitanGold addon
	local gold_color = "|cFFFFFF00"
	local silver_color = "|cFFCCCCCC"
	local copper_color = "|cFFFF6600"
	local money = GetMoney();
	local gold = BreakUpLargeNumbers(money / 100 / 100)
	local silver = (money / 100) % 100
	local copper = money % 100
	return string.format("%s%sg %s%ds %s%dc", gold_color, gold, silver_color, silver, copper_color, copper);
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
