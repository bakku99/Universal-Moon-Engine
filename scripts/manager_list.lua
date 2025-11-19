--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- NOTE: Reference lists and views are static; and will not update dynamically if record data changes

DRAGTYPE_RECORDVIEW = "recordview";

DEFAULT_START_WIDTH = 350;
DEFAULT_START_HEIGHT = 450;
MAX_START_HEIGHT = 650;

DEFAULT_PAGE_SIZE = 50;

DEFAULT_LINK_OFFSET = 25;

DEFAULT_ROW_SIZE = 24;

DEFAULT_COL_WIDTH = 50;
DEFAULT_COL_PADDING = 5;

DEFAULT_FT_COL_LENGTH = 100;

function onInit()
	-- Backward compatibility for original Savage Worlds implementation assumptions
	if ListManager.isSavageWorlds() then
		ListManager.DEFAULT_COL_WIDTH = 250;
	end
end
function onTabletopInit()
	Interface.addKeyedEventHandler("onHotkeyActivated", ListManager.DRAGTYPE_RECORDVIEW, ListManager.onHotkeyRecordView);
end
function onHotkeyRecordView(draginfo)
	ListManager.onHotkeyRecordView(draginfo);
	return true;
end

function isSavageWorlds()
	return StringManager.contains({ "SavageWorlds", "SWD", "SWPF" }, Session.RulesetName);
end

--
--	SIMPLE LIST HANDLING
--

function initSimpleListFromNode(w)
	local rListNode = ListManager.helperBuildSimpleListRecordFromNode(w.getDatabaseNode());
	ListManager.initSimpleListFromRecord(w, rListNode);
end
function helperBuildSimpleListRecordFromNode(nodeMain)
	if not nodeMain then
		return nil;
	end

	local sSource = DB.getValue(nodeMain, "source");
	local sRecordType = DB.getValue(nodeMain, "recordtype");
	if not sSource and not sRecordType then
		return nil;
	end

	local rList = {};

	rList.sSource = sSource;
	rList.sRecordType = sRecordType;
	rList.sDisplayClass = DB.getValue(nodeMain, "displayclass");

	rList.sTitle = DB.getValue(nodeMain, "name", "");
	if (rList.sTitle == "") and (rList.sRecordType or "") ~= "" then
		rList.sTitle = RecordDataManager.getRecordTypeDisplayText(rList.sRecordType);
	end
	rList.nWidth = tonumber(DB.getValue(nodeMain, "width")) or nil;
	rList.nHeight = tonumber(DB.getValue(nodeMain, "height")) or nil;
	if DB.getChild(nodeMain, "notes") then
		rList.sDBNotesField = "notes";
	end

	rList.aFilters = {};
	for _,nodeFilter in ipairs(DB.getChildList(nodeMain, "filters")) do
		local rFilter = {};
		rFilter.sDBField = DB.getValue(nodeFilter, "field");
		rFilter.vFilterValue = DB.getValue(nodeFilter, "value");
		if rFilter.sDBField and rFilter.vFilterValue then
			rFilter.vDefaultVal = DB.getValue(nodeFilter, "defaultvalue");
			table.insert(rList.aFilters, rFilter);
		end
	end

	return rList;
end

function initSimpleListFromRecord(w, rListParam)
	if not rListParam then
		return;
	end
	local rInfo = ListManager.getWindowInfo(w);
	if rInfo and rInfo.tListDef then
		return;
	end
	local rList = UtilityManager.copyDeep(rListParam);

	ListManager.setWindowInfo(w, { tListDef = rList });

	ListManager.populateWindow(w);
end

--
--	VIEW HANDLING
--

function toggleRecordView(sRecordType, sRecordView, sRecordPath)
	if ((sRecordType or "") == "") or ((sRecordView or "") == "") then
		return;
	end
	if (sRecordPath or "") == "" then
		sRecordPath = string.format("reference.%s%s", sRecordType, sRecordView);
	end

	return ListManager.toggleRecordViewFromRecord({ sRecordType = sRecordType, sListView = sRecordView }, sRecordPath);
end
function toggleRecordViewFromRecord(tList, sRecordPath)
	local w = Interface.findWindow("reference_groupedlist", sRecordPath);
	if w then
		Interface.toggleWindow("reference_groupedlist", sRecordPath);
		w = nil;
	else
		w = Interface.openWindow("reference_groupedlist", sRecordPath);
		ListManager.initViewFromRecord(w, tList);
	end
	return w;
end
function onDragRecordView(draginfo, sRecordType, sRecordView, sRecordPath)
	if ((sRecordType or "") == "") or ((sRecordView or "") == "") then
		return;
	end
	local tRecordView = RecordIndexViewManager.getRecordTypeView(sRecordType, sRecordView);
	if not tRecordView then
		return;
	end

	draginfo.setType(ListManager.DRAGTYPE_RECORDVIEW);
	draginfo.setIcon(Interface.getLinkIcon(""));
	draginfo.setDescription(RecordIndexViewManager.getDisplayText(sRecordType, sRecordView, "sDisplayText"));

	draginfo.setMetaData("sRecordType", sRecordType);
	draginfo.setMetaData("sRecordView", sRecordView);
	draginfo.setMetaData("sRecordPath", sRecordPath);
	return true;
end
function onHotkeyRecordView(draginfo)
	local sRecordType = draginfo.getMetaData("sRecordType");
	local sRecordView = draginfo.getMetaData("sRecordView");
	local sRecordPath = draginfo.getMetaData("sRecordPath");
	ListManager.toggleRecordView(sRecordType, sRecordView, sRecordPath);
end

function initViewFromNode(w)
	local tListNode = ListManager.helperBuildViewRecordFromNode(w.getDatabaseNode());
	ListManager.initViewFromRecord(w, tListNode);
end
function helperBuildViewRecordFromNode(nodeMain)
	if not nodeMain then
		return nil;
	end

	local sSource = DB.getValue(nodeMain, "source");
	local sRecordType = DB.getValue(nodeMain, "recordtype");
	if not sSource and not sRecordType then
		return nil;
	end

	local bSavageWorlds = ListManager.isSavageWorlds();

	local rList = {};

	-- Determine basic list data
	rList.sSource = sSource;
	rList.sRecordType = sRecordType;
	rList.sDisplayClass = DB.getValue(nodeMain, "displayclass");
	if not rList.sDisplayClass and bSavageWorlds then
		rList.sDisplayClass = DB.getValue(nodeMain, "itemclass");
	end
	rList.sListView = DB.getValue(nodeMain, "listview");

	rList.sTitle = DB.getValue(nodeMain, "name", "");
	if (rList.sTitle == "") and (rList.sRecordType or "") ~= "" then
		rList.sTitle = RecordDataManager.getRecordTypeDisplayText(rList.sRecordType);
	end
	rList.nWidth = tonumber(DB.getValue(nodeMain, "width")) or nil;
	rList.nHeight = tonumber(DB.getValue(nodeMain, "height")) or nil;
	if DB.getChild(nodeMain, "notes") then
		rList.sDBNotesField = "notes";
	end

	-- Determine list column data
	rList.aColumns = {};
	for _,nodeColumn in ipairs(UtilityManager.getNodeSortedChildren(nodeMain, "columns")) do
		local rColumn = {};
		rColumn.sName = DB.getValue(nodeColumn, "name");
		rColumn.sTooltip = DB.getValue(nodeColumn, "tooltip");
		rColumn.sTooltipRes = DB.getValue(nodeColumn, "tooltipres");
		rColumn.sHeading = DB.getValue(nodeColumn, "heading");
		rColumn.sHeadingRes = DB.getValue(nodeColumn, "headingres");
		rColumn.nWidth = tonumber(DB.getValue(nodeColumn, "width")) or nil;
		if DB.getChild(nodeColumn, "center") then
			rColumn.bCentered = true;
		end
		if DB.getChild(nodeColumn, "wrap") then
			rColumn.bWrapped = true;
		end
		rColumn.nSortOrder = DB.getValue(nodeColumn, "sortorder");
		if DB.getChild(nodeColumn, "sortdesc") then
			rColumn.bSortDesc = true;
		end

		local sTempType = DB.getValue(nodeColumn, "type");
		if sTempType then
			if sTempType == "custom" then
				rColumn.sType = "custom";
			elseif sTempType:match("formattedtext") then
				rColumn.sType = "formattedtext";
			elseif sTempType:match("number") then
				rColumn.sType = "number";
				if DB.getChild(nodeColumn, "displaysign") then
					rColumn.bDisplaySign = true;
				end
			end
		end
		if not rColumn.sType then
			rColumn.sType = "string";
		end

		rColumn.sTemplate = DB.getValue(nodeColumn, "template");

		table.insert(rList.aColumns, rColumn);
	end

	-- Determine list filter data
	rList.aFilters = {};
	for _,nodeFilter in ipairs(DB.getChildList(nodeMain, "filters")) do
		local rFilter = {};
		rFilter.sDBField = DB.getValue(nodeFilter, "field");
		rFilter.vFilterValue = DB.getValue(nodeFilter, "value");
		if rFilter.sDBField and rFilter.vFilterValue then
			rFilter.vDefaultVal = DB.getValue(nodeFilter, "defaultvalue");
			table.insert(rList.aFilters, rFilter);
		end
	end
	if #(rList.aFilters) == 0 and bSavageWorlds then
		local sOldFilter = DB.getValue(nodeMain, "catname");
		if sOldFilter then
			table.insert(rList.aFilters, { sDBField = "catname", vFilterValue = sOldFilter });
		end
	end

	-- Determine list group data
	rList.aGroups = {};
	for _,nodeGroup in ipairs(UtilityManager.getNodeSortedChildren(nodeMain, "groups")) do
		local rGroup = {};
		rGroup.sDBField = DB.getValue(nodeGroup, "field");
		rGroup.sType = DB.getValue(nodeGroup, "type");
		rGroup.nLength = DB.getValue(nodeGroup, "length");
		rGroup.sPrefix = DB.getValue(nodeGroup, "prefix");
		if rGroup.sDBField then
			table.insert(rList.aGroups, rGroup);
		end
	end
	if #(rList.aGroups) == 0 and bSavageWorlds then
		table.insert(rList.aGroups, { sDBField = "group" });
	end
	rList.aGroupValueOrder = StringManager.split(DB.getValue(nodeMain, "grouporder", ""), "|", true);
	if #(rList.aGroupValueOrder) == 0 and bSavageWorlds then
		rList.aGroupValueOrder = StringManager.split(DB.getValue(nodeMain, "order", ""), ",", true);
	end

	return rList;
end

function initViewFromRecord(w, rListParam)
	if not rListParam then
		return;
	end
	local rList = ListManager.helperResolveViewRecord(rListParam);
	if not rList then
		Interface.openWindow("reference_list", w.getDatabaseNode());
		w.close();
		return;
	end

	ListManager.setWindowInfo(w, { bView = true, tListDef = rList });

	ListManager.populateWindow(w);
end
function helperResolveViewRecord(rListParam)
	local rList;
	if (rListParam.sListView or "") ~= "" then
		local rView = RecordIndexViewManager.getRecordTypeView(rListParam.sRecordType, rListParam.sListView)
		if not rView then
			return nil;
		end
		rList = UtilityManager.copyDeep(rView);
		rList.sSource = rListParam.sSource;
		rList.sRecordType = rListParam.sRecordType;
		rList.sListView = rListParam.sListView;
	else
		rList = UtilityManager.copyDeep(rListParam);
	end
	return rList;
end

local _fnViewEntryControlHandler = nil;
function setCustomViewEntryControlHandler(fn)
	_fnViewEntryControlHandler = fn;
end
function getCustomViewEntryControlHandler()
	return _fnViewEntryControlHandler;
end

function createViewEntryControl(wEntry, nColumn, rColumn)
	local fOverride = ListManager.getCustomViewEntryControlHandler();
	if fOverride then
		if fOverride(wEntry, nColumn, rColumn) then
			return;
		end
	end

	local sControlClass;
	if (rColumn.sTemplate or "") ~= "" then
		sControlClass = rColumn.sTemplate;
	else
		-- Determine column base control type
		if rColumn.sType == "number" then
			sControlClass = "number_refgroupedlistgroupitem";
		elseif rColumn.sType == "formattedtext" then
			sControlClass = "string_refgroupedlistgroupitem_ft";
		elseif rColumn.sType == "custom" then
			sControlClass = "string_refgroupedlistgroupitem_custom";
		else
			sControlClass = "string_refgroupedlistgroupitem";
		end

		-- Adjust template based on base control type and column attributes
		if sControlClass == "string_refgroupedlistgroupitem" then
			if nColumn == 1 then
				if rColumn.bWrapped then
					sControlClass = "string_refgroupedlistgroupitem_link_wrap";
				else
					sControlClass = "string_refgroupedlistgroupitem_link";
				end
			elseif rColumn.bCentered then
				if rColumn.bWrapped then
					sControlClass = "string_refgroupedlistgroupitem_center";
				else
					sControlClass = "string_refgroupedlistgroupitem_center_wrap";
				end
			else
				if rColumn.bWrapped then
					sControlClass = "string_refgroupedlistgroupitem_wrap";
				end
			end
		elseif sControlClass == "number_refgroupedlistgroupitem" then
			if rColumn.bDisplaySign then
				sControlClass = "number_signed_refgroupedlistgroupitem";
			end
		elseif sControlClass == "string_refgroupedlistgroupitem_ft" then
			if rColumn.bWrapped then
				sControlClass = "string_refgroupedlistgroupitem_ft_wrap";
			end
		elseif sControlClass == "string_refgroupedlistgroupitem_custom" then
			if rColumn.bCentered then
				if rColumn.bWrapped then
					sControlClass = "string_refgroupedlistgroupitem_custom_center";
				else
					sControlClass = "string_refgroupedlistgroupitem_custom_center_wrap";
				end
			else
				if rColumn.bWrapped then
					sControlClass = "string_refgroupedlistgroupitem_custom_wrap";
				end
			end
		end
	end

	local cField = wEntry.createControl(sControlClass, rColumn.sName);
	if rColumn.sType == "formattedtext" then
		cField.setValue(ListManager.getFTColumnValue(wEntry.getDatabaseNode(), rColumn.sName, rColumn.nMaxLength) or "");
	elseif rColumn.sType == "custom" then
		cField.setValue(RecordIndexViewManager.getCustomColumnValue(rColumn.sCustomKey or rColumn.sName, wEntry.getDatabaseNode()) or "");
	end
	cField.setAnchoredWidth(rColumn.nWidth or ListManager.DEFAULT_COL_WIDTH);
end

--
--	LIST WINDOW SETUP
--

function populateWindow(w)
	local rInfo = ListManager.getWindowInfo(w);
	if not rInfo then
		return;
	end
	if not rInfo.tListDef then
		return;
	end

	-- Set up list title and notes fields
	ListManager.helperSetupTitle(w, rInfo);
	ListManager.helperSetupNotes(w, rInfo);

	-- Create column headers
	ListManager.helperSetupHeaders(w, rInfo);

	-- Initialize the data records
	ListManager.helperSetupData(w, rInfo);

	-- Initialize source controls
	ListManager.helperSetupSource(w, rInfo);

	-- Initialize sorting data
	ListManager.helperSetupSortOrder(rInfo);

	-- Populate the list
	ListManager.refreshDisplayList(w, true);

	-- Set the starting size
	ListManager.helperSetupStartSize(w, rInfo);
end
function helperSetupTitle(w, rInfo)
	local c = w.title or w.reftitle;
	if c and rInfo and rInfo.tListDef then
		local rList = rInfo.tListDef;

		local sTitle = RecordIndexViewManager.getDisplayText(rList.sRecordType, rList.sListView, "sDisplayText");
		if (sTitle or "") == "" then
			sTitle = rList.sTitle;
		end
		if (sTitle or "") == "" then
			sTitle = Interface.getString(rList.sTitleRes);
		end
		c.setValue(sTitle);
	end
end
function helperSetupNotes(w, rInfo)
	local wNotes = ListManager.getNotesWindow(w);
	if not wNotes.notes then
		return;
	end

	if rInfo and rInfo.tListDef and rInfo.tListDef.sDBNotesField then
		wNotes.notes.setValue("", "");
		if wNotes.notes.getValue() ~= "reference_list_notes" then
			wNotes.notes.setValue("reference_list_notes", w.getDatabaseNode());
			wNotes.notes.subwindow.createControl("ft_reflist_notes", "text", rInfo.tListDef.sDBNotesField);
			wNotes.notes.subwindow.createControl("scrollbar_content_text");
		end
		wNotes.notes.setVisible(true);
	else
		wNotes.notes.setVisible(false);
		wNotes.notes.setValue("", "");
	end
end
function helperSetupSource(w, rInfo)
	if not rInfo or not rInfo.bView then
		return;
	end
	rInfo.sCategory = "*";

	local wSource = ListManager.getSourceWindow(w);
	local nodeSource = w.getDatabaseNode();
	local sModule = DB.getModule(nodeSource);
	if ((sModule or "") ~= "") then
		if wSource.label_source then
			wSource.label_source.setValue(Interface.getString("ref_view_source_module"));
		end
		if wSource.source_module then
			local tModuleInfo = Module.getModuleInfo(sModule);
			if tModuleInfo then
				wSource.source_module.setValue(tModuleInfo.displayname);
				wSource.source_module.setVisible(true);
			end
		end
	else
		if wSource.label_source then
			wSource.label_source.setValue(Interface.getString("ref_view_source_category"));
		end
		if wSource.source_category then
			local tDataCategories = {};
			for _,v in pairs(rInfo.tRecords) do
				tDataCategories[v.sCategory] = true;
			end
			local tCategories = {};
			for k,_ in pairs(tDataCategories) do
				table.insert(tCategories, { sValue = k });
			end
			table.sort(tCategories, function(a,b) return a.sValue < b.sValue; end);
			table.insert(tCategories, 1, { sValue = "", sText = Interface.getString("masterindex_label_category_empty") });
			table.insert(tCategories, 1, { sValue = "*", sText = Interface.getString("masterindex_label_category_all") });

			for _,v in ipairs(tCategories) do
				wSource.source_category.add(v.sValue, v.sText);
			end
			wSource.source_category.setListIndex(1);
			wSource.source_category.setComboBoxVisible(true);
		end
	end
end
function helperSetupData(w, rInfo)
	if rInfo then
		rInfo.tRecords = {};
		if rInfo.bView then
			rInfo.tGroups = {};
		end

		if rInfo.tListDef then
			local rList = rInfo.tListDef;

			if rList.sSource then
				ListManager.helperSetupDataBySource(rInfo, w.getDatabaseNode());
			elseif rList.sRecordType then
				ListManager.helperSetupDataByType(rInfo, w.getDatabaseNode());
			elseif rList.aRecordList then
				ListManager.helperSetupDataByList(rInfo);
			end
		end
	end
end
function helperSetupDataBySource(rInfo, nodeSource)
	local sModule = DB.getModule(nodeSource);
	if ((sModule or "") ~= "") and not rInfo.tListDef.sSource:match("@") then
		rInfo.tListDef.sSource = rInfo.tListDef.sSource .. "@" .. sModule;
	end
	for _,v in ipairs(DB.getChildList(rInfo.tListDef.sSource)) do
		ListManager.helperAddDataRecord(rInfo, v);
	end
end
function helperSetupDataByType(rInfo, nodeSource)
	local sModule = DB.getModule(nodeSource);
	local aMappings = RecordDataManager.getDataPaths(rInfo.tListDef.sRecordType);
	for _,sMapping in ipairs(aMappings) do
		if (sModule or "") ~= "" then
			local nodeSource = DB.findNode(sMapping .. "@" .. sModule);
			if nodeSource then
				for _,v in ipairs(DB.getChildList(nodeSource)) do
					ListManager.helperAddDataRecord(rInfo, v);
				end
			end
		else
			for _,v in ipairs(DB.getChildrenGlobal(sMapping)) do
				ListManager.helperAddDataRecord(rInfo, v);
			end
		end
	end
end
function helperSetupDataByList(rInfo)
	for _,v in ipairs(rInfo.tListDef.aRecordList) do
		ListManager.helperAddDataRecord(rInfo, v);
	end
end
function helperAddDataRecord(rInfo, node)
	if not ListManager.helperAddDataRecordFilterCheck(rInfo, node) then
		return;
	end

	local aGroups = {};
	if rInfo.bView then
		if rInfo.tListDef.aGroups then
			for _,rGroup in ipairs(rInfo.tListDef.aGroups) do
				local sSubGroup = DB.getValue(node, rGroup.sDBField);
				if rGroup.sCustom then
					sSubGroup = RecordIndexViewManager.getCustomGroupOutput(rGroup.sCustom, sSubGroup);
				elseif rGroup.nLength then
					sSubGroup = sSubGroup:sub(1, rGroup.nLength);
				end
				if rGroup.sPrefix then
					if (sSubGroup or "") ~= "" then
						sSubGroup = " " .. sSubGroup;
					end
					sSubGroup = rGroup.sPrefix .. (sSubGroup or "");
				end
				table.insert(aGroups, (sSubGroup or ""));
			end
		end
	end
	local sGroup = StringManager.capitalizeAll(table.concat(aGroups, " - "));
	if rInfo.bView then
		rInfo.tGroups[sGroup] = { nOrder = 10000 };
	end

	local rRecord = {};
	rRecord.vNode = node;
	rRecord.sDisplayName = DB.getValue(node, "name", "");
	rRecord.sDisplayNameLower = Utility.convertStringToLower(rRecord.sDisplayName);
	if rInfo.bView then
		rRecord.sGroup = sGroup;
		rRecord.sCategory = DB.getCategory(node);
	end
	rInfo.tRecords[node] = rRecord;
end
function helperAddDataRecordFilterCheck(rInfo, node)
	local bAdd = true;
	if rInfo.tListDef.aFilters then
		for _,rFilter in ipairs(rInfo.tListDef.aFilters) do
			local v;
			if rFilter.sCustom then
				if not RecordIndexViewManager.getCustomFilterValue(rFilter.sCustom, node, rFilter) then
					bAdd = false;
					break;
				end
			else
				if rFilter.fGetValue then
					v = rFilter.fGetValue(node);
				else
					v = tostring(DB.getValue(node, rFilter.sDBField, rFilter.vDefaultVal));
				end
				if v then
					v = tostring(v):lower();
				end

				local tRecordValues;
				if rFilter.bCommaDelim then
					tRecordValues = StringManager.split(v, ",", true);
				elseif rFilter.sDelim then
					tRecordValues = StringManager.split(v, rFilter.sDelim, true);
				else
					tRecordValues = { v };
				end

				local tFilterSplit = StringManager.split(rFilter.vFilterValue:lower() or "", "|", true);
				local bMatch = false;
				for _,sFilter in ipairs(tFilterSplit) do
					if StringManager.contains(tRecordValues, sFilter) then
						bMatch = true;
						break;
					end
				end
				if not bMatch then
					bAdd = false;
					break;
				end

				if not bAdd then
					break;
				end
			end
		end
	end
	return bAdd;
end
function helperSetupHeaders(w, rInfo)
	if rInfo and rInfo.tListDef then
		local rList = rInfo.tListDef;

		rList.nContentWidth = ListManager.DEFAULT_LINK_OFFSET;

		if rInfo.bView then
			local wList = ListManager.getListWindow(w);
			if wList.labelleftanchor and rList.aColumns then
				for _,rColumn in ipairs(rList.aColumns) do
					local nColumnWidth = rColumn.nWidth or ListManager.DEFAULT_COL_WIDTH;

					local sLabelName = "list_label_" .. rColumn.sName;
					local cColumn = w[sLabelName];
					if not cColumn then
						if rColumn.bCentered then
							cColumn = w.createControl("label_refgroupedlist_center", sLabelName);
						else
							cColumn = w.createControl("label_refgroupedlist", sLabelName);
						end
						local sHeading = rColumn.sHeading;
						if (sHeading or "") == "" then
							sHeading = Interface.getString(rColumn.sHeadingRes);
						end
						local sTooltip = rColumn.sTooltip;
						if (sTooltip or "") == "" then
							sTooltip = Interface.getString(rColumn.sTooltipRes);
						end
						cColumn.setValue(sHeading);
						cColumn.setTooltipText(sTooltip);
						cColumn.setAnchoredWidth(nColumnWidth);
					end

					rList.nContentWidth = rList.nContentWidth + nColumnWidth + ListManager.DEFAULT_COL_PADDING;
				end
				local bShowLinkSpacer = true;
				if not rList.sRecordType then
					bShowLinkSpacer = false;
				end
				wList.list_spacer_link.setVisible(bShowLinkSpacer);
			end
		else
			rList.nContentWidth = rList.nContentWidth + 200;
		end
	end
end
function helperSetupSortOrder(rInfo)
	if rInfo then
		if rInfo.bView then
			-- Set up group order
			if rInfo.tListDef and rInfo.tListDef.aGroupValueOrder then
				for k,sGroup in ipairs(rInfo.tListDef.aGroupValueOrder) do
					if rInfo.tGroups[sGroup] then
						rInfo.tGroups[sGroup].nOrder = k;
					end
				end
			end

			-- Set up column sort order
			rInfo.tColumnSort = {};
			if rInfo.tListDef and rInfo.tListDef.aColumns then
				for _,rColumn in ipairs(rInfo.tListDef.aColumns) do
					if (rColumn.nSortOrder or 0) > 0 then
						rInfo.tColumnSort[rColumn.nSortOrder] = { sName = rColumn.sName, sType = rColumn.sType, bDesc = rColumn.bSortDesc };
					end
				end
				for _,rColumn in ipairs(rInfo.tListDef.aColumns) do
					if (rColumn.nSortOrder or 0) <= 0 then
						rInfo.tColumnSort[#(rInfo.tColumnSort) + 1] = { sName = rColumn.sName, sType = rColumn.sType, bDesc = rColumn.bSortDesc };
					end
				end
			end
		end
	end
end
function helperSetupStartSize(w, rInfo)
	local wList = ListManager.getListWindow(w);
	if wList.list and rInfo and rInfo.tListDef then
		local rList = rInfo.tListDef;

		local ww, wh = w.getSize();
		local lw, lh = wList.list.getSize();
		local nTotalWidth = rList.nContentWidth + (ww - lw);
		local nTotalHeight = math.min((ListManager.getDisplayRecordCount(w) * ListManager.DEFAULT_ROW_SIZE) + (wh-lh), ListManager.MAX_START_HEIGHT);

		local wStart = rList.nWidth or math.max(ListManager.DEFAULT_START_WIDTH, nTotalWidth);
		local hStart = rList.nHeight or math.max(ListManager.DEFAULT_START_HEIGHT, nTotalHeight);
		w.setSize(wStart, hStart);
	end
end

--
--	WINDOW AND ATTRIBUTE TRACKING
--

local _tWindowInfo = {};
function hasWindowInfo(w)
	return (ListManager.getWindowInfo(w) ~= nil);
end
function getWindowInfo(w)
	local rInfo = _tWindowInfo[w];
	if not rInfo then
		return nil;
	end
	return rInfo;
end
function setWindowInfo(w, rInfo)
	_tWindowInfo[w] = rInfo;
end

--
--	EVENT HANDLERS
--

function initCustomList(w)
	ListManager.setWindowInfo(w, {});
end

function onCloseWindow(w)
	ListManager.setWindowInfo(w, nil);
end

function onCategoryChanged(w, sCategory)
	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		rInfo.sCategory = sCategory or "";
		ListManager.refreshDisplayList(w, true);
		return;
	end
end

function onFilterChanged(w, sFilter)
	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		rInfo.sFilter = Utility.convertStringToLower(sFilter or "");
		ListManager.refreshDisplayList(w, true);
		return;
	end
end

function onGroupToggle(w, sGroup)
	local rInfo = ListManager.getWindowInfo(w);
	if rInfo and rInfo.bView then
		if not rInfo.tCollapsedGroups then
			rInfo.tCollapsedGroups = {};
		end
		if rInfo.tCollapsedGroups[sGroup] then
			rInfo.tCollapsedGroups[sGroup] = nil;
		else
			rInfo.tCollapsedGroups[sGroup] = true;
		end

		ListManager.refreshDisplayList(w);
		return;
	end
end

--
-- DISPLAY HELPERS
--

function getSourceWindow(w)
	if w.getSourceWindow then
		return w.getSourceWindow();
	end
	return w;
end
function getListWindow(w)
	if w.getListWindow then
		return w.getListWindow();
	end
	return w;
end
function getPagingWindow(w)
	if w.getPagingWindow then
		return w.getPagingWindow();
	end
	return w;
end
function getNotesWindow(w)
	if w.getNotesWindow then
		return w.getNotesWindow();
	end
	return w;
end

function refreshDisplayList(w, bResetScroll)
	ListManager.helperSaveScrollPosition(w, bResetScroll);

	-- Filter records available in list
	local tFilteredRecords = {};
	for _,v in pairs(ListManager.helperGetRecords(w)) do
		if ListManager.helperIsFilteredRecord(w, v) then
			table.insert(tFilteredRecords, v);
		end
	end
	ListManager.setDisplayRecordCount(w, #tFilteredRecords);

	-- Sort filtered records
	ListManager.helperSortFilteredRecords(w, tFilteredRecords);

	-- Ensure display offset is valid
	local nDisplayOffset = ListManager.getDisplayOffset(w);
	if (nDisplayOffset < 0) or (nDisplayOffset >= #tFilteredRecords) then
		nDisplayOffset = 0;
	end
	local nDisplayOffsetMax = nDisplayOffset + ListManager.getPageSize(w);

	-- Clear current windows
	ListManager.helperClearDisplayList(w);

	-- Create windows for current page
	for kRecord,v in ipairs(tFilteredRecords) do
		if kRecord > nDisplayOffset and kRecord <= nDisplayOffsetMax then
			ListManager.helperAddDisplayListItem(w, v);
		end
	end

	-- Sort current windows
	ListManager.helperApplyDisplayListSort(w);

	-- Show/hide page info/buttons based on number of pages and current page
	ListManager.updatePageControls(w);

	ListManager.helperRestoreScrollPosition(w);
end
function helperSaveScrollPosition(w, bResetScroll)
	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		local wList = ListManager.getListWindow(w);
		if bResetScroll or not wList.list then
			rInfo.nSavedScrollPos = nil;
		elseif not rInfo.nSavedScrollPos then
			_,_,_,_,rInfo.nSavedScrollPos,_ = wList.list.getScrollState();
		end
	end
end
function helperRestoreScrollPosition(w)
	local rInfo = ListManager.getWindowInfo(w);
	if rInfo and rInfo.nSavedScrollPos then
		local wList = ListManager.getListWindow(w);
		if wList.list then
			wList.list.setScrollPosition(0, rInfo.nSavedScrollPos);
			rInfo.nSavedScrollPos = nil;
		end
	end
end
function helperGetRecords(w)
	if w.getAllRecords then
		return w.getAllRecords();
	end

	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		return rInfo.tRecords or {};
	end
end
function helperIsFilteredRecord(w, v)
	if w.isFilteredRecord then
		return w.isFilteredRecord(v);
	end

	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		if (rInfo.sFilter or "") ~= "" then
			if not string.find(v.sDisplayNameLower, rInfo.sFilter, 0, true) then
				return false;
			end
		end
		if rInfo.bView and (rInfo.sCategory or "") ~= "*" then
			if v.sCategory ~= rInfo.sCategory then
				return false;
			end
		end
		return true;
	end

	return true;
end
function helperClearDisplayList(w)
	if w.clearDisplayList then
		w.clearDisplayList();
		return;
	end

	local rInfo = ListManager.getWindowInfo(w);
	if rInfo and rInfo.bView then
		rInfo.nDisplayWindowCount = 0;
		rInfo.tDisplayedGroupHeaders = {};
		if not rInfo.tCollapsedGroups then
			rInfo.tCollapsedGroups = {};
		end
	end

	local wList = ListManager.getListWindow(w);
	if wList.list then
		wList.list.closeAll();
	end
end
function helperAddDisplayListItem(w, v)
	if w.addDisplayListItem then
		w.addDisplayListItem(v);
		return;
	end

	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		local wList = ListManager.getListWindow(w);
		if rInfo.bView then
			if not rInfo.tDisplayedGroupHeaders[v.sGroup] then
				local wGroup = wList.list.createWindowWithClass("reference_groupedlist_group");
				wGroup.group.setValue(v.sGroup);
				rInfo.tDisplayedGroupHeaders[v.sGroup] = true;

				rInfo.nDisplayWindowCount = rInfo.nDisplayWindowCount + 1;
				wGroup.order.setValue(rInfo.nDisplayWindowCount);
			end

			if not rInfo.tCollapsedGroups[v.sGroup] then
				local wItem = wList.list.createWindow(v.vNode);
				if rInfo.tListDef then
					if rInfo.tListDef.sDisplayClass then
						wItem.setItemClass(rInfo.tListDef.sDisplayClass);
					else
						wItem.setItemRecordType(rInfo.tListDef.sRecordType);
					end
					wItem.setColumnInfo(rInfo.tListDef.aColumns);
				end

				rInfo.nDisplayWindowCount = rInfo.nDisplayWindowCount + 1;
				wItem.order.setValue(rInfo.nDisplayWindowCount);
			end
		else
			local wItem = wList.list.createWindow(v.vNode);
			if rInfo.tListDef then
				if rInfo.tListDef.sDisplayClass then
					wItem.setItemClass(rInfo.tListDef.sDisplayClass);
				else
					wItem.setItemRecordType(rInfo.tListDef.sRecordType);
				end
				wItem.name.setValue(v.sDisplayName);
			end
		end
	end
end
function helperApplyDisplayListSort(w)
	local wList = ListManager.getListWindow(w);
	if wList.list then
		wList.list.applySort();
	end
end

local _tSortInfo = nil;
function helperSortFilteredRecords(w, tFilteredRecords)
	if w.getSortFunction then
		local fSort = nil;
		if w.getSortFunction then
			fSort = w.getSortFunction();
		end
		table.sort(tFilteredRecords, fSort or ListManager.defaultSortFunc);
		return;
	end

	_tSortInfo = ListManager.getWindowInfo(w);
	if _tSortInfo then
		table.sort(tFilteredRecords, ListManager.defaultSortFunc);
		_tSortInfo = nil;
		return;
	end

	table.sort(tFilteredRecords, ListManager.defaultSortFunc);
end
function defaultSortFunc(a, b)
	if _tSortInfo and _tSortInfo.bView then
		-- First, sort by group
		if _tSortInfo.tGroups then
			if _tSortInfo.tGroups[a.sGroup].nOrder ~= _tSortInfo.tGroups[b.sGroup].nOrder then
				return _tSortInfo.tGroups[a.sGroup].nOrder < _tSortInfo.tGroups[b.sGroup].nOrder;
			end
		end

		if a.sGroup ~= b.sGroup then
			return a.sGroup < b.sGroup;
		end

		-- Then, sort by item sort order
		if _tSortInfo.tColumnSort then
			for _,vColumn in ipairs(_tSortInfo.tColumnSort) do
				local v1 = DB.getValue(a.vNode, vColumn.sName);
				if not v1 then
					if (vColumn.sType or "") == "number" then
						v1 = 0;
					else
						v1 = "";
					end
				end
				local v2 = DB.getValue(b.vNode, vColumn.sName);
				if not v2 then
					if (vColumn.sType or "") == "number" then
						v2 = 0;
					else
						v2 = "";
					end
				end
				if v1 ~= v2 then
					if vColumn.bDesc then
						return v1 > v2;
					else
						return v1 < v2;
					end
				end
			end
		end
	else
		if a.sDisplayNameLower ~= b.sDisplayNameLower then
			return a.sDisplayNameLower < b.sDisplayNameLower;
		end
	end

	return DB.getPath(a.vNode) < DB.getPath(b.vNode);
end

--
--  PAGE BUTTON HELPERS
--

-- NOTE: Assumes page controls are located in same window; or within subwindow named "sub_paging"
-- 		Or must define getPagingWindow in top window
function updatePageControls(w)
	local wList = ListManager.getListWindow(w);
	if not wList.list then
		return;
	end

	local wPaging = ListManager.getPagingWindow(w);
	if wPaging.pageanchor then
		local nPages = ListManager.getMaxPages(w);
		if nPages > 1 then
			local nCurrentPage = ListManager.getCurrentPage(w);

			local sPageText = string.format(Interface.getString("label_page_info"), nCurrentPage, nPages)
			wPaging.pageanchor.setVisible(true);
			wPaging.page_info.setValue(sPageText);
			wPaging.page_info.setVisible(true);
			wPaging.page_start.setVisible(nCurrentPage > 1);
			wPaging.page_prev.setVisible(nCurrentPage > 1);
			wPaging.page_next.setVisible(nCurrentPage < nPages);
			wPaging.page_end.setVisible(nCurrentPage < nPages);
		else
			wPaging.pageanchor.setVisible(false);
			wPaging.page_info.setVisible(false);
			wPaging.page_start.setVisible(false);
			wPaging.page_prev.setVisible(false);
			wPaging.page_next.setVisible(false);
			wPaging.page_end.setVisible(false);
		end
	elseif wPaging.sub_paging then
		local nPages = ListManager.getMaxPages(w);
		if nPages > 1 then
			local nCurrentPage = ListManager.getCurrentPage(w);

			local sPageText = string.format(Interface.getString("label_page_info"), nCurrentPage, nPages)
			wPaging.sub_paging.setVisible(true);
			wPaging.sub_paging.subwindow.page_info.setVisible(true);
			wPaging.sub_paging.subwindow.page_info.setValue(sPageText);
			wPaging.sub_paging.subwindow.page_start.setVisible(nCurrentPage > 1);
			wPaging.sub_paging.subwindow.page_prev.setVisible(nCurrentPage > 1);
			wPaging.sub_paging.subwindow.page_next.setVisible(nCurrentPage < nPages);
			wPaging.sub_paging.subwindow.page_end.setVisible(nCurrentPage < nPages);
		else
			wPaging.sub_paging.setVisible(false);
		end
	end
end

function getListContextWindow(w)
	local wContext = w;
	while wContext and not ListManager.hasWindowInfo(wContext) and (wContext.windowlist or wContext.parentcontrol) do
		if wContext.windowlist then
			wContext = wContext.windowlist.window;
		else
			wContext = wContext.parentcontrol.window;
		end
	end
	return wContext;
end
function handlePageStart(w)
	if WindowManager.hasOuterWindowFunction(w, "handlePageStart") then
		WindowManager.callOuterWindowFunction(w, "handlePageStart");
		return;
	end

	local w = ListManager.getListContextWindow(w);
	ListManager.setDisplayOffset(w, 0);
end
function handlePagePrev(w)
	if WindowManager.hasOuterWindowFunction(w, "handlePagePrev") then
		WindowManager.callOuterWindowFunction(w, "handlePagePrev");
		return;
	end

	local w = ListManager.getListContextWindow(w);
	local nNewOffset = ListManager.getDisplayOffset(w) - ListManager.getPageSize(w);
	ListManager.setDisplayOffset(w, nNewOffset);
end
function handlePageNext(w)
	if WindowManager.hasOuterWindowFunction(w, "handlePageNext") then
		WindowManager.callOuterWindowFunction(w, "handlePageNext");
		return;
	end

	local w = ListManager.getListContextWindow(w);
	local nNewOffset = ListManager.getDisplayOffset(w) + ListManager.getPageSize(w);
	ListManager.setDisplayOffset(w, nNewOffset);
end
function handlePageEnd(w)
	if WindowManager.hasOuterWindowFunction(w, "handlePageEnd") then
		WindowManager.callOuterWindowFunction(w, "handlePageEnd");
		return;
	end

	local w = ListManager.getListContextWindow(w);
	local nPages = ListManager.getMaxPages(w);
	if nPages > 1 then
		local nNewOffset = (nPages - 1) * ListManager.getPageSize(w);
		ListManager.setDisplayOffset(w, nNewOffset);
	else
		ListManager.setDisplayOffset(w, 0);
	end
end

function getDisplayOffset(w)
	if w.getDisplayOffset then
		return w.getDisplayOffset();
	end

	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		return rInfo.nDisplayOffset or 0;
	end

	return 0;
end
function setDisplayOffset(w, n, bSkipRefresh)
	if w.setDisplayOffset then
		w.setDisplayOffset(n);
		return;
	end

	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		rInfo.nDisplayOffset = n;
		if not bSkipRefresh then
			if rInfo.bView then
				rInfo.tCollapsedGroups = {};
			end
			ListManager.refreshDisplayList(w, true);
		end
		return;
	end
end
function getDisplayRecordCount(w)
	if w.getDisplayRecordCount then
		return w.getDisplayRecordCount();
	end

	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		return rInfo.nDisplayRecordCount or 0;
	end

	return 0;
end
function setDisplayRecordCount(w, n)
	if w.setDisplayRecordCount then
		w.setDisplayRecordCount(n);
		return;
	end

	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		rInfo.nDisplayRecordCount = n;
		return;
	end
end

function setPageSize(w, nPageSize)
	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		rInfo.nPageSize = nPageSize;
	end
end
function getPageSize(w)
	if w.getPageSize then
		return w.getPageSize();
	end

	local rInfo = ListManager.getWindowInfo(w);
	if rInfo then
		return rInfo.nPageSize or ListManager.DEFAULT_PAGE_SIZE;
	end

	return ListManager.DEFAULT_PAGE_SIZE;
end
function getCurrentPage(w)
	return math.max(math.ceil(ListManager.getDisplayOffset(w) / ListManager.getPageSize(w)), 0) + 1;
end
function getMaxPages(w)
	local nCurrentPage = ListManager.getCurrentPage(w);
	local nRemainingPages = math.max(math.ceil((ListManager.getDisplayRecordCount(w) - ListManager.getDisplayOffset(w)) / ListManager.getPageSize(w)), 0);
	local nPages = (nCurrentPage - 1) + nRemainingPages;
	return nPages;
end

--
--	MISC HELPERS
--

-- Return just the first line of formatted text up to max characters
-- 	(if multi-line add ... at the end).
function getFTColumnValue(node, sField, nMax)
	if not node or ((sField or "") == "") then
		return "";
	end
	local sText = DB.getText(node, sField)
	if (sText or "") == "" then
		return "";
	end

	if nMax and nMax < 0 then
		return sText:gsub("\n\n", "\n"):gsub("\n", "; ");
	end

	local sTemp = sText:sub(1, math.min(sText:find("\n") or #sText, nMax or ListManager.DEFAULT_FT_COL_LENGTH));
	if #sTemp < #sText then
		local nSpaceBreak = sTemp:reverse():find("%s");
		if nSpaceBreak then
			sTemp = sTemp:sub(1, #sTemp - nSpaceBreak);
		end
		sTemp = sTemp .. "...";
	end
	return sTemp;
end
