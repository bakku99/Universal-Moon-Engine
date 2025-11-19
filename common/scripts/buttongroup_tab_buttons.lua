--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _nIndex = 0;
function getIndex()
	return _nIndex;
end
function setIndex(n)
	_nIndex = n;
end

local _tTabs = {};
function getTabsData()
	return _tTabs;
end
function setTabsData(tTabs)
	if not tTabs then
		return;
	end

	local nActivate = 1;
	self.setIndex(0);
	self.cleanupAllTabControls();

	local nCount = math.max(self.getTabCount(), #tTabs);
	for i = 1, nCount do
		self.deactivateTabEntry(i)
		local t = tTabs[i];
		if t then
			self.setTabData(i, t);
			if t.bActivate then
				nActivate = i;
			end
		end
	end

	self.updateAllTabControls();
	self.activateTab(nActivate, true);
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
	self.updateTabControls(n);

	if n == self.getIndex() then
		self.activateTabEntry(n);
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

	self.cleanupAllTabControls();
	table.remove(_tTabs, n);
	self.updateAllTabControls();

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
function activateTab(n, bForceUpdate)
	local nCurrIndex = self.getIndex();
	local nNewIndex = tonumber(n) or 1;
	if not bForceUpdate and (nCurrIndex == nNewIndex) then
		return;
	end

	self.deactivateTabEntry(nCurrIndex);
	self.setIndex(nNewIndex);
	self.activateTabEntry(nNewIndex);
end
function activateTabEntry(n)
	if n >= 1 and n <= self.getTabCount() then
		WindowTabManager.updateTabDisplay(window, self.getTabData(n), true);
		WindowTabManager.setTabDisplayVisible(window, self.getTabData(n), true);
		if window.onTabChanged then
			window.onTabChanged();
		end
	end
	self.updateTabControlsDisplay();
end
function deactivateTabEntry(n)
	if n >= 1 and n <= self.getTabCount() then
		WindowTabManager.setTabDisplayVisible(window, self.getTabData(n), false);
	end
end

function getTabControl(n)
	return subwindow["button" .. n];
end
function createTabControls(n)
	return subwindow.createControl("button_content_tab", "button" .. n);
end
function updateAllTabControls()
	for i = 1, self.getTabCount() do
		self.updateTabControls(i);
	end
end
function updateTabControls(n)
	local tData = self.getTabData(n);
	local c = self.getTabControl(n);
	if c then
		c.bringToFront();
	else
		c = self.createTabControls(n);
		c.setIndex(n);
	end
	c.setStateText(0, tData.sText or Interface.getString(tData.sTextRes or tData.sTabRes));
end
function cleanupAllTabControls()
	for i = 1, self.getTabCount() do
		self.cleanupTabControls(i);
	end
end
function cleanupTabControls(n)
	local c = self.getTabControl(n);
	if c then
		c.destroy();
	end
end
function updateTabControlsDisplay()
	local n = self.getIndex();
	for i = 1, self.getTabCount() do
		local c = self.getTabControl(i);
		if c then
			if i == n then
				c.setValue(1);
			else
				c.setValue(0);
			end
		end
	end
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
	self.updateDisplay();
end
function replaceTabClassByName(sName, sClass)
	for k,tTab in ipairs(self.getTabsData()) do
		if tTab.sName == sName then
			self.replaceTabClass(k, sClass);
			return;
		end
	end
end
