--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals activate tab

local DEFAULT_TAB_SIZE = 67;
local DEFAULT_TAB_MARGINS = 25;
local DEFAULT_DISABLED_ALPHA = "80";

local DEFAULT_VERTICAL_HELPER_OFFSETX = 8;
local DEFAULT_VERTICAL_HELPER_OFFSETY = 7;
local DEFAULT_HORIZONTAL_HELPER_OFFSETX = 7;
local DEFAULT_HORIZONTAL_HELPER_OFFSETY = 10;

local DEFAULT_VERTICAL_TEXT_OFFSETX = 8;
local DEFAULT_VERTICAL_TEXT_OFFSETY = 41;
local DEFAULT_HORIZONTAL_TEXT_OFFSETX = 41;
local DEFAULT_HORIZONTAL_TEXT_OFFSETY = 10;
local DEFAULT_VERTICAL_ICON_OFFSETX = 7;
local DEFAULT_VERTICAL_ICON_OFFSETY = 41;

local _bHorizontal = false;
local _nTabSize = DEFAULT_TAB_SIZE;
local _nMargins = DEFAULT_TAB_MARGINS;
local _sDisabledAlpha = DEFAULT_DISABLED_ALPHA;

local _tVertHelperIconOffset = { DEFAULT_VERTICAL_HELPER_OFFSETX, DEFAULT_VERTICAL_HELPER_OFFSETY };
local _tHorzHelperIconOffset = { DEFAULT_HORIZONTAL_HELPER_OFFSETX, DEFAULT_HORIZONTAL_HELPER_OFFSETY };
local _tVertTextOffset = { DEFAULT_VERTICAL_TEXT_OFFSETX, DEFAULT_VERTICAL_TEXT_OFFSETY };
local _tHorzTextOffset = { DEFAULT_HORIZONTAL_TEXT_OFFSETX, DEFAULT_HORIZONTAL_TEXT_OFFSETY };
local _tVertIconOffset = { DEFAULT_VERTICAL_ICON_OFFSETX, DEFAULT_VERTICAL_ICON_OFFSETY };

function onInit()
	self.parseSettings();
	self.createTopWidget();
	self.parseTabs();
end

function parseSettings()
	_bHorizontal = self.parseTagBooleanSetting("horizontal");

	_nTabSize = self.parseTagNumberSetting("tabsize", DEFAULT_TAB_SIZE);
	_nMargins = self.parseTagNumberSetting("tabmargins", DEFAULT_TAB_MARGINS);
	_sDisabledAlpha = self.parseTagStringSetting("disabledalpha", DEFAULT_DISABLED_ALPHA);

	_tVertHelperIconOffset[1] = self.parseTagNumberSetting("tabverticalhelperoffsetx", DEFAULT_VERTICAL_HELPER_OFFSETX);
	_tVertHelperIconOffset[2] = self.parseTagNumberSetting("tabverticalhelperoffsety", DEFAULT_VERTICAL_HELPER_OFFSETY);
	_tHorzHelperIconOffset[1] = self.parseTagNumberSetting("tabhorizontalhelperoffsetx", DEFAULT_HORIZONTAL_HELPER_OFFSETX);
	_tHorzHelperIconOffset[2] = self.parseTagNumberSetting("tabhorizontalhelperoffsety", DEFAULT_HORIZONTAL_HELPER_OFFSETY);

	_tVertTextOffset[1] = self.parseTagNumberSetting("tabverticaltextoffsetx", DEFAULT_VERTICAL_TEXT_OFFSETX);
	_tVertTextOffset[2] = self.parseTagNumberSetting("tabverticaltextoffsety", DEFAULT_VERTICAL_TEXT_OFFSETY);
	_tHorzTextOffset[1] = self.parseTagNumberSetting("tabhorzizontaloffsetx", DEFAULT_HORIZONTAL_TEXT_OFFSETX);
	_tHorzTextOffset[2] = self.parseTagNumberSetting("tabhorzizontaloffsety", DEFAULT_HORIZONTAL_TEXT_OFFSETY);
	_tVertIconOffset[1] = self.parseTagNumberSetting("tabverticaloffsetx", DEFAULT_VERTICAL_ICON_OFFSETX);
	_tVertIconOffset[2] = self.parseTagNumberSetting("tabverticaloffsety", DEFAULT_VERTICAL_ICON_OFFSETY);
end
function parseTagBooleanSetting(sTag)
	if self[sTag] then
		return true;
	end
	return false;
end
function parseTagNumberSetting(sTag, nDefault)
	if self[sTag] then
		return tonumber(self[sTag][1]) or nDefault;
	end
	return nDefault;
end
function parseTagStringSetting(sTag, sDefault)
	if self[sTag] then
		return self[sTag][1] or sDefault;
	end
	return sDefault;
end
function parseTabs()
	local tTabs = {};
	if tab and type(tab) == "table" then
		local nActivate = 1;
		if activate then
			nActivate = tonumber(activate[1]) or 1;
		end

		for k, v in ipairs(tab) do
			if type(v) == "table" then
				local tData = { sName = v.subwindow[1], };
				if v.tabres then
					tData.sTabRes = v.tabres[1];
				end
				if v.textres then
					tData.sTextRes = v.textres[1];
				elseif v.text then
					tData.sText = v.text[1];
				end
				if v.icon then
					tData.sIcon = v.icon[1];
				end
				if k == nActivate then
					tData.bActivate = true;
				end
				table.insert(tTabs, tData);
			end
		end
	end
	self.setTabsData(tTabs);
end

local _nIndex = 0;
function getIndex()
	return _nIndex;
end
function setIndex(n)
	_nIndex = n;
end

local _bUpdatingAllTabs = false;
local _tTabs = {};
function getTabsData()
	return _tTabs;
end
function setTabsData(tTabs)
	if not tTabs then
		return;
	end

	local nOldCount = self.getTabCount();
	local nActivate = 1;
	self.setIndex(0);
	self.cleanupAllTabWidgets();

	_bUpdatingAllTabs = true;
	local nCount = math.max(self.getTabCount(), #tTabs);
	for i = 1, nCount do
		self.deactivateTabEntry(i);
		local t = tTabs[i];
		if t then
			self.setTabData(i, t);
			if t.bActivate then
				nActivate = i;
			end
		end
	end
	for i = nCount, nOldCount do
		self.deactivateTabEntry(i);
		self.setTabData(i, nil);
	end
	_bUpdatingAllTabs = false;

	self.updateAllTabWidgets();
	self.activateTab(nActivate);
end
function getTabCount()
	return #_tTabs;
end
function getTabData(n)
	return _tTabs[n];
end
function setTabData(n, tData)
	if not tData then
		self.removeTabByIndex(n);
		return;
	end

	if n == self.getIndex() then
		self.deactivateTabEntry(n);
	end
	WindowTabManager.cleanupTabDisplay(window, _tTabs[n], tData);

	_tTabs[n] = UtilityManager.copyDeep(tData);
	self.updateTabWidget(n);

	self.updateDisplay();
	if not _bUpdatingAllTabs then
		if n == self.getIndex() then
			self.activateTabEntry(n);
		else
			self.updateTabWidgetsDisplay();
		end
	end
end
function addTabData(tData)
	if not tData then
		return;
	end
	self.setTabData(self.getTabCount() + 1, tData);
end

function getTabIndexByName(s)
	local nIndex = 0;
	for i = 1, self.getTabCount() do
		local tData = self.getTabData(i);
		if tData.sName == s then
			nIndex = i;
			break;
		end
	end
	return nIndex;
end
function insertTabAtIndex(n, tData)
	if not tData then
		return;
	end
	if n > self.getTabCount() then
		self.addTabData(tData);
	else
		if n < 1 then
			n = 1;
		end
		local tNewTabs = UtilityManager.copyDeep(self.getTabsData());
		table.insert(tNewTabs, n, tData);
		self.setTabsData(tNewTabs);
	end
end
function removeTabByIndex(n)
	if n < 1 or n > self.getTabCount() then
		return false;
	end

	if n == self.getIndex() then
		self.deactivateTabEntry(n);
	end
	WindowTabManager.cleanupTabDisplay(window, _tTabs[n]);

	self.cleanupAllTabWidgets();
	table.remove(_tTabs, n);
	self.updateAllTabWidgets();

	self.updateDisplay();
	if n == self.getIndex() then
		self.activateTabEntry(n);
	end
end
function removeTabByName(s)
	return self.removeTabByIndex(self.getTabIndexByName(s));
end

function getActiveTabName()
	local tData = self.getTabData(self.getIndex());
	if not tData then
		return "";
	end
	return tData.sName or "";
end
function activateTabByName(s)
	self.activateTab(self.getTabIndexByName(s));
end
function activateTab(n)
	local nCurrIndex = self.getIndex();
	local nNewIndex = tonumber(n) or 1;
	if nCurrIndex == nNewIndex then
		return;
	end

	self.deactivateTabEntry(nCurrIndex);
	self.setIndex(nNewIndex);
	self.activateTabEntry(nNewIndex);

	self.updateTopWidget();
end
function activateTabEntry(n)
	if n >= 1 and n <= self.getTabCount() then
		WindowTabManager.updateTabDisplay(window, self.getTabData(n), true);
		WindowTabManager.setTabDisplayVisible(window, self.getTabData(n), true);
		if window.onTabChanged then
			window.onTabChanged();
		end
	end
	self.updateTabWidgetsDisplay();
end
function deactivateTabEntry(n)
	if n >= 1 and n <= self.getTabCount() then
		WindowTabManager.setTabDisplayVisible(window, self.getTabData(n), false);
	end
end

function getTopWidget()
	return findWidget("tabtop");
end
function createTopWidget()
	if self.getTopWidget() then
		return;
	end

	if _bHorizontal then
		addBitmapWidget({ name = "tabtop", icon = "tabtop_h" }).setVisible(false);
	else
		addBitmapWidget({ name = "tabtop", icon = "tabtop" }).setVisible(false);
	end
end
function updateTopWidget()
	local wgt = self.getTopWidget();
	if not wgt then
		return;
	end

	local nIndex = self.getIndex();
	if _bHorizontal then
		wgt.setPosition("topleft", (_nTabSize * (nIndex - 1)) + _tHorzHelperIconOffset[1], _tHorzHelperIconOffset[2]);
	else
		wgt.setPosition("topleft", _tVertHelperIconOffset[1], (_nTabSize * (nIndex - 1)) + _tVertHelperIconOffset[2]);
	end
	if nIndex == 1 then
		wgt.setVisible(false);
	else
		wgt.setVisible(true);
	end
end
function getTabWidget(n)
	return findWidget("tab" .. n);
end

function updateAllTabWidgets()
	for i = 1, self.getTabCount() do
		self.updateTabWidget(i);
	end
	self.updateDisplay();
end
function updateTabWidget(n)
	local tData = self.getTabData(n);
	local sText = tData.sText or Interface.getString(tData.sTextRes or tData.sTabRes);
	local wgt = self.getTabWidget(n);
	if not wgt then
		if _bHorizontal then
			addTextWidget({
				name = "tab" .. n,
				font = "tabfont", text = sText,
				position = "topleft", x = (_nTabSize * (n - 1)) + _tHorzTextOffset[1], y = _tHorzTextOffset[2],
			});
		else
			if sText ~= "" then
				addTextWidget({
					name = "tab" .. n,
					font = "tabfont", text = tData.sText or Interface.getString(tData.sTextRes or tData.sTabRes),
					position = "topleft", x = _tVertTextOffset[1], y = (_nTabSize * (n - 1)) + _tVertTextOffset[2],
					rotation = 270,
				});
			else
				addBitmapWidget({
					name = "tab" .. n,
					icon = tData.sIcon or tData.sTabRes,
					position = "topleft", x = _tVertIconOffset[1], y = (_nTabSize * (n - 1)) + _tVertIconOffset[2],
				});
			end
		end
	else
		if _bHorizontal or (sText ~= "") then
			wgt.setText(sText);
		else
			wgt.setBitmap(tData.sIcon or tData.sTabRes);
		end
	end
end
function cleanupAllTabWidgets()
	for i = 1, self.getTabCount() do
		self.cleanupTabWidget(i);
	end
end
function cleanupTabWidget(n)
	local wgt = self.getTabWidget(n);
	if wgt then
		wgt.destroy();
	end
end

function updateTabWidgetsDisplay()
	local sFullColor, sDisabledColor = UtilityManager.getFullAndDisabledFontColors("tabfont", _sDisabledAlpha);

	local n = self.getIndex();
	for i = 1, self.getTabCount() do
		local wgt = self.getTabWidget(i);
		if wgt then
			local tData = self.getTabData(i);
			local sText = tData.sText or Interface.getString(tData.sTextRes or tData.sTabRes);
			if i == n then
				if _bHorizontal or (sText ~= "") then
					wgt.setColor(sFullColor);
				else
					wgt.setColor("FFFFFFFF");
				end
			else
				if _bHorizontal or (sText ~= "") then
					wgt.setColor(sDisabledColor);
				else
					wgt.setColor(_sDisabledAlpha .. "FFFFFF");
				end
			end
		end
	end
end
function updateDisplay()
	local n = self.getTabCount();
	if _bHorizontal then
		setAnchoredWidth(_nMargins + (_nTabSize * n));
	else
		setAnchoredHeight(_nMargins + (_nTabSize * n));
	end
	if self.getIndex() > n then
		self.activateTab(n);
	end
end

function onVisibilityChanged()
	if isVisible() then
		self.activateTabEntry(self.getIndex());
	else
		self.deactivateTabEntry(self.getIndex());
	end
end
function setVisibility(bState)
	Debug.console("buttongroup_tabs:setVisibility - DEPRECATED - 2024-10-22 - Use setVisible");
	setVisible(bState);
end

function onClickDown()
	return true;
end
function onClickRelease(_, x, y)
	local i;
	if _bHorizontal then
		local adjx = x - (_tHorzTextOffset[1] - (_nTabSize / 2));
		i = math.ceil(adjx / _nTabSize);
	else
		local adjy = y - (_tVertIconOffset[2] - (_nTabSize / 2));
		i = math.ceil(adjy / _nTabSize);
	end

	if i >= 1 and i <= self.getTabCount() then
		self.activateTab(i);
	end
	return true;
end
function onDoubleClick(x, y)
	-- Emulate click
	self.onClickRelease(1, x, y);
end

function replaceTabClass(n, sClass)
	local tData = self.getTabData(n);
	if not tData then
		return;
	end

	self.deactivateTabEntry(n);
	if (sClass or "") ~= "" then
		tData.sClass = sClass;
		if self.getIndex() == n then
			self.activateTabEntry(n);
		end
	else
		self.removeTabByIndex(n);
	end
end
function replaceTabClassByName(sName, sClass)
	for k,tTab in ipairs(self.getTabsData()) do
		if tTab.sName == sName then
			self.replaceTabClass(k, sClass);
			return;
		end
	end
end

-- DEPRECATED (CPR)
function setTab(n, sSub, sDisplay)
	self.deactivateTabEntry(n);
	if sSub and sDisplay then
		local tData = { sName = sSub, sTabRes = sDisplay, };
		self.setTabData(n, tData);
		if self.getIndex() == n then
			self.activateTabEntry(n);
		else
			self.updateTabWidgetsDisplay();
		end
	else
		self.removeTabByIndex(n);
	end
end
