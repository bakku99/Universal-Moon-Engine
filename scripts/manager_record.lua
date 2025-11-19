--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_RECORD_ADD = "recordadd";

function onInit()
	if Session.IsHost then
		OOBManager.registerOOBMsgHandler(RecordManager.OOB_MSGTYPE_RECORD_ADD, RecordManager.handleRecordAdd);
	end
end

--
--	INDEX HANDLING
--

function openRecordIndex(sRecordType)
	if ((sRecordType or "") == "") then
		return;
	end

	local w = Interface.findWindow("masterindex", sRecordType);
	if w then
		w.bringToFront();
		return w, true;
	end
	w = Interface.openWindow("masterindex", sRecordType);
	return w, false;
end
function openRecordWindow(sRecordType, v)
	if not v then
		return;
	end
	local w = Interface.openWindow(RecordDataManager.getRecordTypeDisplayClass(sRecordType), v);
	if not w then
		return nil;
	end
	local tControls = w.getControls();
	for _,v in ipairs(tControls) do
		if v.getName() == "header" then
			if v.subwindow and v.subwindow.name then
				v.subwindow.name.setFocus(true);
			end
			break;
		end
	end
	return w;
end

function getRecordWindows(sRecordType)
	if ((sRecordType or "") == "") then
		return {};
	end

	local t = {};
	for _,w in ipairs(Interface.getWindows()) do
		local sWinRecordType = RecordDataManager.getRecordTypeFromDisplayClass(w.getClass());
		if sWinRecordType == sRecordType then
			table.insert(t, w);
		end
	end
	return t;
end

--
--  FIND RECORD HELPERS
--

function findRecordByString(sRecordType, sField, sValue)
	return RecordManager.findRecordByFilter(sRecordType, { { sField = sField, sValue = sValue, } });
end
function findRecordByStringI(sRecordType, sField, sValue)
	return RecordManager.findRecordByFilter(sRecordType, { { sField = sField, sValue = sValue, bIgnoreCase = true, } });
end
function findRecordByFilter(sRecordType, tFilters)
	if ((sRecordType or "") == "") or (#(tFilters or {}) == 0) then
		return nil;
	end

	for _,tFilter in ipairs(tFilters) do
		if tFilter.bIgnoreCase then
			tFilter.sFind = StringManager.trim(tFilter.sValue or ""):lower();
		else
			tFilter.sFind = StringManager.trim(tFilter.sValue or "");
		end
	end

	local tMappings = RecordDataManager.getDataPaths(sRecordType);
	for _,sMapping in ipairs(tMappings) do
		for _,v in ipairs(DB.getChildrenGlobal(sMapping)) do
			local bMatch = true;
			for _,tFilter in ipairs(tFilters) do
				if ((tFilter.sField or "") ~= "") then
					if tFilter.bIgnoreCase then
						local sMatch = StringManager.trim(DB.getValue(v, tFilter.sField, "")):lower();
						if sMatch ~= tFilter.sFind then
							bMatch = false;
						end
					else
						local sMatch = StringManager.trim(DB.getValue(v, tFilter.sField, ""));
						if sMatch ~= tFilter.sFind then
							bMatch = false;
						end
					end
					if not bMatch then
						break;
					end
				end
			end
			if bMatch then
				return v;
			end
		end
	end

	return nil;
end

--
--	OPTIONS RECORD HELPERS
--

function getRecordOptionsByString(sRecordType, sField, sValue, bSorted)
	return RecordManager.getRecordOptionsByFilter(sRecordType, { { sField = sField, sValue = sValue, } }, bSorted);
end
function getRecordOptionsByStringI(sRecordType, sField, sValue, bSorted)
	return RecordManager.getRecordOptionsByFilter(sRecordType, { { sField = sField, sValue = sValue, bIgnoreCase = true, } }, bSorted);
end
function getRecordOptionsByFilter(sRecordType, tFilters, bSorted)
	local tData = {
		sClass = LibraryData.getRecordDisplayClass(sRecordType),
		tOptions = {},
	};
	RecordManager.callForEachRecordByFilter(sRecordType, tFilters, RecordManager.helperGetRecordOptionsByFilter, tData);
	if bSorted then
		table.sort(tData.tOptions, function(a,b) return a.text < b.text; end);
	end
	return tData.tOptions;
end
function helperGetRecordOptionsByFilter(node, tData)
	local sName = StringManager.trim(DB.getValue(node, "name", ""));
	if sName ~= "" then
		table.insert(tData.tOptions, { text = sName, linkclass = tData.sClass, linkrecord = DB.getPath(node) });
	end
end

--
--  CALL FOR ALL RECORDS HELPERS
--

function callForEachRecord(sRecordType, fn, ...)
	if not sRecordType or not fn then
		return;
	end

	local tMappings = RecordDataManager.getDataPaths(sRecordType);
	for _,sMapping in ipairs(tMappings) do
		for _,v in ipairs(DB.getChildrenGlobal(sMapping)) do
			fn(v, ...);
		end
	end
end
function callForEachCampaignRecord(sRecordType, fn, ...)
	RecordManager.callForEachModuleRecord(sRecordType, "", fn, ...);
end
function callForEachModuleRecord(sRecordType, sModule, fn, ...)
	if not sRecordType or not fn then
		return;
	end

	local tMappings = RecordDataManager.getDataPaths(sRecordType);
	for _,sMapping in ipairs(tMappings) do
		sMapping = string.format("%s@%s", sMapping, sModule or "");
		for _,v in ipairs(DB.getChildList(sMapping)) do
			fn(v, ...);
		end
	end
end

function callForEachRecordByString(sRecordType, sField, sValue, fn, ...)
	RecordManager.callForEachRecordByFilter(sRecordType, { { sField = sField, sValue = sValue, } }, fn, ...);
end
function callForEachRecordByStringI(sRecordType, sField, sValue, fn, ...)
	RecordManager.callForEachRecordByFilter(sRecordType, { { sField = sField, sValue = sValue, bIgnoreCase = true, } }, fn, ...);
end
function callForEachRecordByFilter(sRecordType, tFilters, fn, ...)
	if ((sRecordType or "") == "") or (#(tFilters or {}) == 0) or not fn then
		return nil;
	end

	for _,tFilter in ipairs(tFilters) do
		tFilter.tFindValues = {};
		if tFilter.bIgnoreCase then
			if tFilter.tValues then
				for _,s in ipairs(tFilter.tValues) do
					table.insert(tFilter.tFindValues, StringManager.trim(s):lower());
				end
			else
				table.insert(tFilter.tFindValues, StringManager.trim(tFilter.sValue or ""):lower());
			end
		else
			if tFilter.tValues then
				for _,s in ipairs(tFilter.tValues) do
					table.insert(tFilter.tFindValues, StringManager.trim(s));
				end
			else
				table.insert(tFilter.tFindValues, StringManager.trim(tFilter.sValue or ""));
			end
		end
	end

	local tMappings = RecordDataManager.getDataPaths(sRecordType);
	for _,sMapping in ipairs(tMappings) do
		for _,v in ipairs(DB.getChildrenGlobal(sMapping)) do
			local bMatch = true;
			for _,tFilter in ipairs(tFilters) do
				if ((tFilter.sField or "") ~= "") then
					local sMatch;
					if tFilter.bIgnoreCase then
						sMatch = StringManager.trim(tostring(DB.getValue(v, tFilter.sField, "")) or ""):lower();
					else
						sMatch = StringManager.trim(tostring(DB.getValue(v, tFilter.sField, "")) or "");
					end
					if not StringManager.contains(tFilter.tFindValues, sMatch) then
						bMatch = false;
						break;
					end
				end
			end
			if bMatch then
				fn(v, ...);
			end
		end
	end
end

--
--	ACTIONS
--

local _tRecordAddCallbacks = {};
function setRecordAddCallback(sRecordType, fn)
	UtilityManager.setKeySingleCallback(_tRecordAddCallbacks, sRecordType, fn);
end
function getRecordAddCallback(sRecordType)
	return UtilityManager.getKeySingleCallback(_tRecordAddCallbacks, sRecordType);
end
function hasRecordAddCallback(sRecordType)
	return UtilityManager.hasKeySingleCallback(_tRecordAddCallbacks, sRecordType);
end
function onRecordAddEvent(sRecordType, node)
	if UtilityManager.performKeySingleCallback(_tRecordAddCallbacks, sRecordType, node, sRecordType) then
		return true;
	end
	return UtilityManager.performKeySingleCallback(_tRecordAddCallbacks, "", node, sRecordType);
end

function addRecordByType(sRecordType, nodeList)
	if not nodeList or ((sRecordType or "") == "") then
		return;
	end

	if Session.IsHost then
		local nodeNew = DB.createChild(nodeList);
		if nodeNew then
			RecordManager.onRecordAddEvent(sRecordType, nodeNew);
			RecordManager.openRecordWindow(sRecordType, nodeNew);
		end
	else
		RecordManager.sendRecordAdd(sRecordType, DB.getPath(nodeList));
	end
end
function sendRecordAdd(sRecordType, sListPath)
	local msgOOB = {};
	msgOOB.type = RecordManager.OOB_MSGTYPE_RECORD_ADD;
	msgOOB.user = Session.UserName;
	msgOOB.sRecordType = sRecordType;
	msgOOB.sListPath = sListPath;

	Comm.deliverOOBMessage(msgOOB, "");
end
function handleRecordAdd(msgOOB)
	if (msgOOB.sListPath or "") == "" then
		return;
	end
	local sClass = RecordDataManager.getRecordTypeDisplayClass(msgOOB.sRecordType);
	if (sClass or "") == "" then
		return;
	end

	local nodeNew = DB.createChild(msgOOB.sListPath);
	if not nodeNew then
		return;
	end
	RecordManager.onRecordAddEvent(msgOOB.sRecordType, nodeNew);

	DB.setOwner(nodeNew, msgOOB.user);

	Interface.openRemoteWindow(sClass, nodeNew, msgOOB.user);
end

function performRevertByWindow(w)
	if not w then
		return;
	end
	RecordManager.performRevert(RecordDataManager.getRecordTypeFromWindow(w), w.getDatabaseNode());
end
function performRevert(sRecordType, node)
	if not node then
		return;
	end
	if DB.isIntact(node) then
		return;
	end

	local tData = {
		sTitleRes = "revert_dialog_title",
		sPath = DB.getPath(node),
		fnCallback = RecordManager.handleRevertDialog,
	};
	local sDisplayText = Interface.getString("revert_dialog_text");
	local sDisplayType = RecordDataManager.getRecordTypeDisplayTextSingle(sRecordType or RecordDataManager.getRecordTypeFromListPath(tData.sPath));
	local sDisplayName = DB.getValue(node, "name", "");
	tData.sText = string.format("%s\r\r%s: %s", sDisplayText, sDisplayType, sDisplayName);

	DialogManager.openDialog("dialog_okcancel", tData);
end
function handleRevertDialog(sResult, tData)
	if sResult == "ok" then
		DB.revert(tData.sPath);
	end
end

local _tRecordDeleteCallbacks = {};
function setRecordDeleteCallback(sRecordType, fn)
	UtilityManager.setKeySingleCallback(_tRecordDeleteCallbacks, sRecordType, fn);
end
function getRecordDeleteCallback(sRecordType)
	return UtilityManager.getKeySingleCallback(_tRecordDeleteCallbacks, sRecordType);
end
function hasRecordDeleteCallback(sRecordType)
	return UtilityManager.hasKeySingleCallback(_tRecordDeleteCallbacks, sRecordType);
end
function onRecordDeleteEvent(sRecordType, node)
	if UtilityManager.performKeySingleCallback(_tRecordDeleteCallbacks, sRecordType, node, sRecordType) then
		return true;
	end
	return UtilityManager.performKeySingleCallback(_tRecordDeleteCallbacks, "", node, sRecordType);
end

function performDeleteByWindow(w)
	if not w then
		return;
	end

	local node = w.getDatabaseNode();
	RecordManager.onRecordDeleteEvent(m_sRecordType, node);
	if node then
		DB.deleteNode(node);
	else
		w.close();
	end
end
