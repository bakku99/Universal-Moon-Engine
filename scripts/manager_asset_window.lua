--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals MAX_HISTORY MAX_HISTORY_SAVE

MAX_HISTORY = 50;
MAX_HISTORY_SAVE = 10;

function onTabletopInit()
	AssetWindowManager.initAssetLinks();
end

--
--	CONFIGURATION
--

local _tAssetWindowClass = {
	["tokenbag"] = {},
	["decal_select"] = {},
	["initind_select"] = {},
};
function getAssetWindowData(w)
	return _tAssetWindowClass[w and w.getClass() or ""];
end
function setAssetWindowClassData(sClass, tData)
	if (sClass or "") == "" then
		return;
	end
	_tAssetWindowClass[sClass] = tData;
end
function getAssetWindowDataField(w, sField)
	local t = AssetWindowManager.getAssetWindowData(w);
	if not t then
		return nil;
	end
	return t[sField];
end
function setAssetWindowDataField(w, sField, v)
	local t = AssetWindowManager.getAssetWindowData(w);
	if not t then
		return nil;
	end
	t[sField] = v;
end
function isAssetWindow(w)
	return (AssetWindowManager.getAssetWindowData(w) ~= nil);
end
function clearAssetWindowData(w)
	AssetWindowManager.setAssetWindowClassData(w.getClass(), {});
end

function getAssetWindowLastPathAndFilter(w)
	local t = AssetWindowManager.getAssetWindowData(w);
	if not t then
		return nil;
	end
	return t.sLastPath, t.sLastFilter;
end
function setAssetWindowLastPathAndFilter(w, sPath, sFilter)
	local t = AssetWindowManager.getAssetWindowData(w);
	if not t then
		return "";
	end
	t.sLastPath = sPath;
	t.sLastFilter = sFilter;
end

--
--	ASSET LINK SUPPORT
--

function initAssetLinks()
	Interface.addKeyedEventHandler("onLinkActivate", "assetlink", AssetWindowManager.handleAssetLink);
end
function onMenuLinkDrag(w, draginfo)
	draginfo.setType("shortcut");
	draginfo.setIcon(Interface.getLinkIcon("assetlink"));
	draginfo.setShortcutData("assetlink", AssetWindowManager.getViewState(w));

	local sView = AssetWindowManager.getViewDescription(w);
	if (sView or "") ~= "" then
		draginfo.setDescription(string.format("%s - \r%s", w.title.getValue(), sView));
	else
		draginfo.setDescription(w.title.getValue());
	end
	return true;
end
function handleAssetLink(_, sPath)
	local w = Interface.openWindow("tokenbag", "");
	AssetWindowManager.setViewState(w, sPath, true);
end

--
--	ASSET WINDOW SUPPORT
--

function initAssetWindow(w)
	if not AssetWindowManager.isAssetWindow(w) then
		return;
	end

	AssetWindowManager.initControls(w);
	AssetWindowManager.loadViewState(w);
	AssetWindowManager.setAssetWindowDataField(w, "bInit", true);

	AssetWindowManager.handleViewTypeUpdate(w, true);
	AssetWindowManager.handleValueUpdate(w, true);
end
function initControls(w)
	if not w then
		return;
	end

	if w.nohistory then
		AssetWindowManager.setAssetWindowDataField(w, "bNoHistory", true);
	end

	if w.sub_controls_top then
		w.sub_controls_top.subwindow.createControl("button_asset_typefilter_all", "button_all");
		w.sub_controls_top.subwindow.createControl("button_asset_typefilter_image", "button_image");
		w.sub_controls_top.subwindow.createControl("button_asset_typefilter_portrait", "button_portrait");
		w.sub_controls_top.subwindow.createControl("button_asset_typefilter_token", "button_token");
	end
end
function closeAssetWindow(w)
	if not AssetWindowManager.isAssetWindow(w) then
		return;
	end

	AssetWindowManager.saveViewState(w);
	AssetWindowManager.clearAssetWindowData(w);
end

function getTypeFilter(w)
	if not w or not w.assets then
		return "";
	end
	return w.assets.getTypeFilter();
end

function onLayoutSizeChanged(w)
	AssetWindowManager.helperUpdatePageView(w);
end

function onActivate(w, sAssetName, sAssetType)
	if w.onActivate then
		w.onActivate(sAssetName, sAssetType);
		return;
	end

	local wPreview = Interface.openWindow("asset_preview", "");
	if wPreview then
		wPreview.setData(sAssetName, sAssetType);
	end
end

function onHomeButtonPressed(w)
	AssetWindowManager.setViewState(w, "", true);
end
function onBackButtonPressed(w)
	AssetWindowManager.popHistoryState(w);
end
function onPagePrevButtonPressed(w)
	if not w or not w.assets then
		return;
	end
	w.assets.setPage(w.assets.getPage() - 1);
end
function onPageNextButtonPressed(w)
	if not w or not w.assets then
		return;
	end
	w.assets.setPage(w.assets.getPage() + 1);
end
function onTypeFilterSelected(w, s)
	if not w or not w.assets then
		return;
	end
	w.assets.setTypeFilter(s);
end
function onClearFilterButtonPressed(w)
	if not w or not w.assets then
		return;
	end
	w.assets.setSearchFilter("");
end
function onViewPathSelected(w, s)
	if not w or not w.assets then
		return;
	end
	w.assets.setPathFilter(s);
end
function onViewTypeButtonPressed(w)
	if w.button_viewchange and w.assets then
		w.assets.setView((w.button_viewchange.getValue() == 1) and "list" or "grid");
		AssetWindowManager.helperUpdatePageView(w);
	end
end

function handleViewTypeUpdate(w)
	if not AssetWindowManager.getAssetWindowDataField(w, "bInit") then
		return;
	end

	if w.button_viewchange and w.assets then
		w.button_viewchange.setValue((w.assets.getView() == "list") and 1 or 0);
	end
end
function handleValueUpdate(w, bSkipHistory)
	if not AssetWindowManager.getAssetWindowDataField(w, "bInit") then
		return;
	end

	if AssetWindowManager.getAssetWindowDataField(w, "bViewSet") or AssetWindowManager.getAssetWindowDataField(w, "bUpdating") then
		return;
	end
	AssetWindowManager.setAssetWindowDataField(w, "bUpdating", true);

	AssetWindowManager.helperUpdatePathView(w);
	AssetWindowManager.helperUpdateTypeFilter(w);
	AssetWindowManager.helperUpdatePageView(w);
	if not bSkipHistory then
		AssetWindowManager.pushHistoryState(w);
	end

	AssetWindowManager.setAssetWindowDataField(w, "bUpdating", nil);
end
function helperUpdatePathView(w)
	if not w or not w.assets then
		return;
	end

	local sCurrentPath = w.assets.getPathFilter();
	local sCurrentFilter = w.assets.getSearchFilter();

	local sLastPath, sLastFilter = AssetWindowManager.getAssetWindowLastPathAndFilter(w);
	if not sLastPath or not sLastFilter or (sLastPath ~= sCurrentPath) or (sLastFilter ~= sCurrentFilter) then
		AssetWindowManager.setAssetWindowLastPathAndFilter(w, sCurrentPath, sCurrentFilter);
		AssetWindowManager.helperUpdatePathViewList(w);
	end
end
function helperUpdatePathViewList(w)
	if not w or not w.sub_filter_path then
		return;
	end

	w.sub_filter_path.subwindow.list.closeAll();

	local sLastPath, sLastFilter = AssetWindowManager.getAssetWindowLastPathAndFilter(w);
	if ((sLastPath or "") == "") and ((sLastFilter or "") == "") then
		w.sub_filter_path.setVisible(false);
		return;
	end

	w.sub_filter_path.setVisible(true);

	if ((sLastFilter or "") ~= "") then
		w.sub_filter_path.subwindow.list.createWindowWithClass("asset_path_filter").setData(sLastFilter);
	end

	if ((sLastPath or "") ~= "") then
		local tPathComps = StringManager.split(sLastPath, "/");
		local tPathSoFar = {};
		for k,s in ipairs(tPathComps) do
			if k == #tPathComps then
				w.sub_filter_path.subwindow.list.createWindowWithClass("asset_path_item_current").setData(s);
			else
				table.insert(tPathSoFar, s);
				w.sub_filter_path.subwindow.list.createWindow().setData(s, table.concat(tPathSoFar, "/"));
			end
		end
	end
end
function helperUpdateTypeFilter(w)
	if not w or not w.sub_controls_top or not w.assets then
		return;
	end

	local sFilterName = w.assets.getTypeFilter();
	if sFilterName == "image" then
		w.sub_controls_top.subwindow.button_token.setValue(0);
		w.sub_controls_top.subwindow.button_portrait.setValue(0);
		w.sub_controls_top.subwindow.button_image.setValue(1);
		w.sub_controls_top.subwindow.button_all.setValue(0);
	elseif sFilterName == "portrait" then
		w.sub_controls_top.subwindow.button_token.setValue(0);
		w.sub_controls_top.subwindow.button_portrait.setValue(1);
		w.sub_controls_top.subwindow.button_image.setValue(0);
		w.sub_controls_top.subwindow.button_all.setValue(0);
	elseif sFilterName == "token" then
		w.sub_controls_top.subwindow.button_token.setValue(1);
		w.sub_controls_top.subwindow.button_portrait.setValue(0);
		w.sub_controls_top.subwindow.button_image.setValue(0);
		w.sub_controls_top.subwindow.button_all.setValue(0);
	else
		w.sub_controls_top.subwindow.button_token.setValue(0);
		w.sub_controls_top.subwindow.button_portrait.setValue(0);
		w.sub_controls_top.subwindow.button_image.setValue(0);
		w.sub_controls_top.subwindow.button_all.setValue(1);
	end
end
function helperUpdatePageView(w)
	if not w or not w.assets then
		return;
	end
	local nPage = w.assets.getPage();
	local nMaxPage = w.assets.getPageMax();
	if w.page_prev then
		w.page_prev.setVisible(nPage > 1);
	end
	if w.page_next then
		w.page_next.setVisible(nPage < nMaxPage);
	end
end

--
--	ASSET VIEW STATE AND LINKS
--
--	NOTE: View History Entries separated by |||
--

function loadViewState(w)
	local tRegistry = CampaignRegistry and CampaignRegistry.windowstate and CampaignRegistry.windowstate[w.getClass()];
	if not tRegistry then
		return;
	end

	if w.assets then
		if tRegistry.viewtype then
			w.assets.setView(tRegistry.viewtype);
		end
		if tRegistry.viewzoom then
			w.assets.setZoom(tRegistry.viewzoom);
		end
	end

	if not AssetWindowManager.getAssetWindowDataField(w, "bNoHistory") then
		AssetWindowManager.setHistory(w, StringManager.splitByPattern(tRegistry.history, "|||", true));
		AssetWindowManager.synchViewToHistory(w);
	end
end
function saveViewState(w)
	if not CampaignRegistry then
		return;
	end

	local sClass = w.getClass();
	CampaignRegistry.windowstate = CampaignRegistry.windowstate or {};
	CampaignRegistry.windowstate[sClass] = CampaignRegistry.windowstate[sClass] or {};
	local tState = CampaignRegistry.windowstate[sClass];

	if w.assets then
		tState.viewtype = w.assets.getView();
		tState.viewzoom = w.assets.getZoom();
	end

	if not AssetWindowManager.getAssetWindowDataField(w, "bNoHistory") then
		-- NOTE: Append delimiter to end to handle empty string as home state
		local t = AssetWindowManager.getHistory(w);
		local s = table.concat(t, "|||", math.max(1, #t - MAX_HISTORY_SAVE + 1), #t);
		if s ~= "" then
			tState.history = s .. "|||";
		else
			tState.history = nil;
		end
	end
end

function getViewState(w)
	local tLink = AssetWindowManager.getViewData(w);
	if not tLink then
		return nil;
	end
	return UtilityManager.encodeKVPToString(tLink);
end
-- NOTE: Type filter must be set first, since it clears path filter
function setViewState(w, s, bSaveHistory)
	if not s then
		return;
	end
	AssetWindowManager.setViewLink(w, UtilityManager.decodeKVPFromString(s), bSaveHistory);
end
function setViewLink(w, tLink, bSaveHistory)
	if not w or not w.assets or not tLink then
		return;
	end

	AssetWindowManager.setAssetWindowDataField(w, "bViewSet", true);
	w.assets.setTypeFilter(tLink.sFilterType or "");
	w.assets.setPathFilter(tLink.sPath or "");
	w.assets.setSearchFilter(tLink.sFilterSearch or "");
	w.assets.setDisplayIndex(tonumber(tLink.nDisplayIndex) or 1);
	AssetWindowManager.setAssetWindowDataField(w, "bViewSet", nil);

	AssetWindowManager.handleValueUpdate(w, true);

	if bSaveHistory then
		AssetWindowManager.pushHistoryState(w);
	end
end
function getViewData(w)
	if not w or not w.assets then
		return nil;
	end
	local tLink = {
		sPath = w.assets.getPathFilter(),
		sFilterType = w.assets.getTypeFilter(),
		sFilterSearch = w.assets.getSearchFilter(),
		nDisplayIndex = w.assets.getDisplayIndex(),
	};
	if tLink.sPath == "" then
		tLink.sPath = nil;
	end
	if tLink.sFilterType == "" then
		tLink.sFilterType = nil;
	end
	if tLink.sFilterSearch == "" then
		tLink.sFilterSearch = nil;
	end
	if tLink.nDisplayIndex <= 1 then
		tLink.nDisplayIndex = nil;
	end
	return tLink;
end
function getViewDescription(w)
	local tLink = AssetWindowManager.getViewData(w);
	if not tLink then
		return nil;
	end
	local tResults = {};
	if tLink.sFilterType then
		if tLink.sFilterType == "image" then
			table.insert(tResults, string.format("%s: %s", Interface.getString("asset_label_type"), Interface.getString("asset_label_type_image")));
		elseif tLink.sFilterType == "portrait" then
			table.insert(tResults, string.format("%s: %s", Interface.getString("asset_label_type"), Interface.getString("asset_label_type_portrait")));
		elseif tLink.sFilterType == "token" then
			table.insert(tResults, string.format("%s: %s", Interface.getString("asset_label_type"), Interface.getString("asset_label_type_token")));
		end
	end
	if tLink.sPath then
		table.insert(tResults, string.format("%s: %s", Interface.getString("asset_label_path"), tLink.sPath));
	end
	if tLink.sFilterSearch then
		table.insert(tResults, string.format("%s: %s", Interface.getString("asset_label_filter"), tLink.sFilterSearch));
	end
	if tLink.nDisplayIndex then
		table.insert(tResults, string.format("%s: %d", Interface.getString("asset_label_index"), tLink.nDisplayIndex));
	end
	return table.concat(tResults, "\r");
end

local _tHistory = {};
function getHistory(w)
	return _tHistory[w.getClass()] or {};
end
function setHistory(w, t)
	_tHistory[w.getClass()] = t;
end

function pushHistoryState(w)
	if AssetWindowManager.getAssetWindowDataField(w, "bNoHistory") then
		return;
	end

	local sCurrState = AssetWindowManager.getViewState(w);
	if not sCurrState then
		return;
	end

	local t = AssetWindowManager.getHistory(w);
	if (#t > 0) and (t[#t] == sCurrState) then
		return;
	end

	table.insert(t, sCurrState);
	while #t > MAX_HISTORY do
		table.remove(t, 1);
	end
end
function popHistoryState(w)
	if AssetWindowManager.getAssetWindowDataField(w, "bNoHistory") then
		return;
	end

	table.remove(AssetWindowManager.getHistory(w));
	AssetWindowManager.synchViewToHistory(w);
end
function synchViewToHistory(w)
	local t = AssetWindowManager.getHistory(w);
	if #t > 0 then
		AssetWindowManager.setViewState(w, t[#t]);
	else
		AssetWindowManager.setViewState(w, "");
	end
end
