--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local RECORD_DEFAULT_HEIGHT = 100;
local LIST_RIGHT_OFFSET = 40;
local LIST_BOTTOM_OFFSET = 140;

local _nLoadedFilter = 0;
local _nSharedFilter = 0;
local _nRulesetFilter = 0;
local _sNameFilterLower = "";
local _sAuthorFilterLower = "";
local _nPageSize = 10;

--
--	EVENTS
--

function onInit()
	ListManager.initCustomList(self);

	if Session.IsHost then
		sub_filter.subwindow.filter_shared.setVisible(true);
	end

	ListManager.refreshDisplayList(self);
end
function onClose()
	ListManager.onCloseWindow(self);
end

function onLayoutSizeChanged()
	local nWinWidth, nWinHeight = getSize();
	local nListLeft, nListTop = list.getPosition();
	local w = nWinWidth - nListLeft - LIST_RIGHT_OFFSET;
	local h = nWinHeight - nListTop - LIST_BOTTOM_OFFSET;

	local nColWidth = list.getColumnWidth();
	local nRecordsWide = 1;
	if nColWidth > 0 then
		nRecordsWide = math.max(math.floor(w / nColWidth), 1)
	end
	local nRecordsHigh = math.max(math.floor(h / RECORD_DEFAULT_HEIGHT), 1);

	local nNewPageSize = math.max(nRecordsWide * nRecordsHigh, 1);
	if _nPageSize ~= nNewPageSize then
		_nPageSize = nNewPageSize;
		ListManager.refreshDisplayList(self);
	end
end

function onNameFilterChanged()
	local sNewFilterLower = Utility.convertStringToLower(WindowManager.getInnerControlValue(self, "filter_name"));
	if _sNameFilterLower ~= sNewFilterLower then
		_sNameFilterLower = sNewFilterLower;
		ListManager.setDisplayOffset(self, 0);
	end
end
function onAuthorFilterChanged()
	local sNewFilterLower = Utility.convertStringToLower(WindowManager.getInnerControlValue(self, "filter_author"));
	if _sAuthorFilterLower ~= sNewFilterLower then
		_sAuthorFilterLower = sNewFilterLower;
		ListManager.setDisplayOffset(self, 0);
	end
end
function onLoadedFilterChanged()
	local nNewFilter = WindowManager.getInnerControlValue(self, "filter_loaded");
	if _nLoadedFilter ~= nNewFilter then
		_nLoadedFilter = nNewFilter;
		ListManager.setDisplayOffset(self, 0);
	end
end
function onSharedFilterChanged()
	local nNewFilter = WindowManager.getInnerControlValue(self, "filter_shared");
	if _nSharedFilter ~= nNewFilter then
		_nSharedFilter = nNewFilter;
		ListManager.setDisplayOffset(self, 0);
	end
end
function onRulesetFilterChanged()
	local nNewFilter = WindowManager.getInnerControlValue(self, "filter_ruleset");
	if _nRulesetFilter ~= nNewFilter then
		_nRulesetFilter = nNewFilter;
		ListManager.setDisplayOffset(self, 0);
	end
end

--
--	BUTTON HANDLING
--

function setPermissions(sPermission)
	for sModule,_ in pairs(ModuleManager.getAllModuleInfo()) do
		self.setModulePermissions(sModule, sPermission);
	end
end
function setModulePermissions(sModule, sPermission)
	if sPermission == "disallow" then
		Module.setModulePermissions(sModule, false, false);
	elseif sPermission == "allow" then
		Module.setModulePermissions(sModule, true, false);
	end
end
function toggleActivation(sModule)
	local tInfo = ModuleManager.getModuleInfo(sModule);
	if tInfo.loaded then
		Module.deactivate(sModule);
	else
		Module.activate(sModule);
	end
end

--
--	LIST HANDLING
--

function addDisplayListItem(v)
	local wItem = list.createWindow();
	wItem.setData(v);
end

function getAllRecords()
	return ModuleManager.getAllModuleInfo();
end
function getPageSize()
	return _nPageSize;
end

function getSortFunction()
	return self.sortFunc;
end
function sortFunc(a, b)
	if a.displayname ~= b.displayname then
		return a.displayname < b.displayname;
	end
	return a.name < b.name;
end

function isFilteredRecord(v)
	if not Session.IsHost and (v.permission == "disallow") then
		return false;
	end
	if _nRulesetFilter == 1 then
		if v.anyflag then
			return false;
		end
	elseif _nRulesetFilter == 2 then
		if not v.anyflag then
			return false;
		end
	end
	if _nLoadedFilter == 1 then
		if not v.loaded then
			return false;
		end
	elseif _nLoadedFilter == 2 then
		if v.loaded then
			return false;
		end
	end
	if _nSharedFilter == 1 then
		if v.permission == "disallow" then
			return false;
		end
	elseif _nSharedFilter == 2 then
		if v.permission ~= "disallow" then
			return false;
		end
	end
	if _sNameFilterLower ~= "" then
		if not string.find(Utility.convertStringToLower(v.displayname), _sNameFilterLower, 0, true) then
			return false;
		end
	end
	if _sAuthorFilterLower ~= "" then
		if not string.find(Utility.convertStringToLower(v.author), _sAuthorFilterLower, 0, true) then
			return false;
		end
	end
	return true;
end
