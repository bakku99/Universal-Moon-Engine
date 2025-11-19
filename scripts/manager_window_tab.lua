--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
-- 	Assumptions
-- 		Tabs/Buttons connect to subwindows using the template "sub_content_hidden"
--
--	Styles = "" (default tabs), "button"
--
-- 	tData = {
-- 		sName = "", -- Name of subwindow control to create in window
--		sClass = "", -- Window class to assign to subwindow control
--
-- 		sIcon = "", -- Tab icon to use for default tab style
--		sText = "", -- Button text to use for button tab style
--
-- 		sInsertBefore = "",  -- Name of control to insert before
-- 		bActivate = bool, -- Default active tab
--		sOption = "", -- If option is "on", then tab is displayed
--		sMode = "", -- If "host", then only show on host; If "client", then only show on client
-- 	};
--

function onTabletopInit()
	DB.addHandler("options.*", "onUpdate", WindowTabManager.onOptionChanged);
end

local _sDefaultTabTemplate = nil;
local _tWindowTabTemplate = {};
function getTabTemplate(sClass)
	if _tWindowTabTemplate[sClass] then
		return _tWindowTabTemplate[sClass];
	end
	return _sDefaultTabTemplate or "";
end
function setTabTemplate(sClass, s)
	_tWindowTabTemplate[sClass] = s;
end
function setDefaultTabTemplate(s)
	_sDefaultTabTemplate = s;
end

local _tWindowTabs = {};
function getTabs(sClass)
	_tWindowTabs[sClass] = _tWindowTabs[sClass] or {};
	return _tWindowTabs[sClass];
end
function getAllTabData()
	return _tWindowTabs;
end

function registerTab(sClass, tData)
	if not tData then
		return;
	end
	if ((tData.sName or "") == "") then
		return;
	end

	WindowTabManager.unregisterTab(sClass, tData.sName)

	local tClassTabs = WindowTabManager.getTabs(sClass);
	if (tData.sInsertBefore or "") ~= "" then
		local nIndex = #tClassTabs+1
		for k,v in ipairs(tClassTabs) do
			if v.sName == tData.sInsertBefore then
				nIndex = k;
				break;
			end
		end
		table.insert(tClassTabs, nIndex, tData);
	else
		table.insert(tClassTabs, tData);
	end
end
function unregisterTab(sClass, sName)
	if (sName or "") == "" then
		return;
	end

	local tClassTabs = WindowTabManager.getTabs(sClass);
	for k,v in ipairs(tClassTabs) do
		if v.sName == sName then
			table.remove(tClassTabs, k);
			break;
		end
	end
end
function getTabsFromWindow(w)
	local sClass = w.getClass();
	local tTabs = WindowTabManager.getTabs(sClass);
	if #tTabs > 0 then
		return tTabs;
	end

	if w.getTabsData then
		tTabs = w.getTabsData();
	elseif w.tab and type(w.tab) == "table" then
		for _,v in ipairs(w.tab) do
			local bAdd = true;
			if v.gmvisibleonly and not Session.IsHost then
				bAdd = false;
			elseif v.playervisibleonly and Session.IsHost then
				bAdd = false;
			end

			if bAdd then
				local tData = {
					sName = v.name and v.name[1],
					sClass = v.class and v.class[1],
					sTabRes = v.resource and v.resource[1],
					sIcon = v.icon and v.icon[1],
					sTextRes = v.textres and v.textres[1],
					sText = v.text and v.text[1],
					sMode = v.mode and v.mode[1],
					bEmbed = v.embed and true,
					bFramed = v.framed and true,
					bScroll = v.scroll and true,
					sInsertBefore = v.insertbefore and v.insertbefore[1],
					bActivate = v.activate and true,
				};
				table.insert(tTabs, tData);
			end
		end
	end

	return tTabs;
end

function populate(w)
	if w.tabs then
		w.tabs.destroy();
	end

	local sTabTemplate = self.getTabTemplate(w.getClass());
	if sTabTemplate == "" then
		sTabTemplate = string.format("tabs_%s", w.getFrame());
	end
	w.createControl(sTabTemplate, "tabs");

	self.populateTabs(w);
end
function populateTabs(w)
	if not w.tabs then
		return;
	end

	local tTabs = WindowTabManager.getTabsFromWindow(w);

	local tVisualTabs = {};
	for _,v in ipairs(tTabs) do
		local bAdd = true;
		if bAdd and ((v.sMode or "") ~= "") then
			if v.sMode == "host" and not Session.IsHost then
				bAdd = false;
			elseif v.sMode == "client" and Session.IsHost then
				bAdd = false;
			end
		end
		if bAdd and ((v.sOption or "") ~= "") and not OptionsManager.isOption(v.sOption, "on") then
			bAdd = false;
		end
		if bAdd then
			local kInsertAt = nil;
			if (v.sInsertBefore or "") ~= "" then
				for kVisual, vVisual in ipairs(tVisualTabs) do
					if (vVisual.sName or "") == v.sInsertBefore then
						kInsertAt = kVisual;
						break;
					end
				end
			end
			if kInsertAt then
				table.insert(tVisualTabs, kInsertAt, v);
			else
				table.insert(tVisualTabs, v);
			end
		end
	end
	for _,v in ipairs(self.getTabsData(w)) do
		WindowTabManager.destroyTabDisplay(w, v);
	end
	w.tabs.setTabsData(tVisualTabs);
end
function getTabsData(w)
	if not w.tabs then
		return {};
	end
	return w.tabs.getTabsData();
end

function getTabDisplay(w, tData, bCreate)
	if not w then
		return nil;
	end
	if not tData or ((tData.sName or "") == "") then
		return nil;
	end
	local c = w[tData.sName];
	if not c then
		if bCreate then
			if tData.bFramed or tData.bEmbed then
				c = w.createControl("sub_content_framed_groupbox_hidden", tData.sName);
			else
				c = w.createControl("sub_content_hidden", tData.sName);
			end
			WindowTabManager.getTabScrollbar(w, tData, true);
			tData.bCreated = true;
		end
		if not c then
			return nil;
		end
	end
	return c;
end
function getTabScrollbar(w, tData, bCreate)
	if not w then
		return nil;
	end
	if not tData or ((tData.sName or "") == "") then
		return nil;
	end
	if not tData.bScroll and not tData.bEmbed then
		return;
	end
	local sScroll = string.format("scrollbar_%s", tData.sName);
	local c = w[sScroll];
	if not c then
		if bCreate then
			c = WindowTabManager.createTabScrollbar(w, tData);
		end
		if not c then
			return nil;
		end
	end
	return c;
end
function createTabScrollbar(w, tData)
	if not w then
		return nil;
	end
	if not tData or ((tData.sName or "") == "") then
		return nil;
	end

	local sScroll = string.format("scrollbar_%s", tData.sName);
	local cScroll = w[sScroll];
	if not cScroll then
		cScroll = w.createControl("scrollbar_content_base", sScroll);
	end

	local t = cScroll.getAnchor("top");
	t["parent"] = tData.sName;
	cScroll.setAnchor("top", t);
	t = cScroll.getAnchor("left");
	t["parent"] = tData.sName;
	cScroll.setAnchor("left", t);
	t = cScroll.getAnchor("bottom");
	t["parent"] = tData.sName;
	cScroll.setAnchor("bottom", t);

	cScroll.setTarget(tData.sName);
end
function destroyTabDisplay(w, tData)
	local c = WindowTabManager.getTabDisplay(w, tData);
	if c then
		c.destroy();
	end
	local cScroll = WindowTabManager.getTabScrollbar(w, tData);
	if cScroll then
		cScroll.destroy();
	end
	tData.bCreated = false;
end
function cleanupTabDisplay(w, tData1, tData2)
	if not tData1 or ((tData1.sName or "") == "") then
		return;
	end
	if not tData2 or ((tData2.sName or "") == "") then
		return;
	end

	if tData1.bCreated and (tData1.sName ~= tData2.sName) then
		WindowTabManager.destroyTabDisplay(w, tData1);
	end
end
function updateTabDisplay(w, tData, bCreate)
	if not w or not tData or ((tData.sName or "") == "") or ((tData.sClass or "") == "") then
		return;
	end
	local c = WindowTabManager.getTabDisplay(w, tData, bCreate);
	if not c then
		return;
	end
	if type(c) == "subwindow" then
		local s = c.getValue() or "";
		if (s ~= tData.sClass) then
			c.setValue(tData.sClass, w.getDatabasePath() or "");
			if c.subwindow and c.subwindow.update then
				c.subwindow.update();
			end
		end
	end
end
function setTabDisplayVisible(w, tData, bVisible)
	local c = WindowTabManager.getTabDisplay(w, tData);
	if c then
		c.setVisible(bVisible);
	end
end

function onOptionChanged(nodeOption)
	local sKey = DB.getName(nodeOption);
	for sClass, tClass in pairs(WindowTabManager.getAllTabData()) do
		local bUpdate = false;
		for _,v in ipairs(tClass) do
			if v.sOption and (v.sOption == sKey) then
				bUpdate = true;
				break;
			end
		end
		if bUpdate then
			for _,w in ipairs(Interface.getWindows(sClass)) do
				WindowTabManager.populateTabs(w);
			end
		end
	end
end
