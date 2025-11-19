--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function getViewData()
	return LibraryData.getRecordViewData();
end

function initViews()
	for sRecordType,tRecordTypeViews in pairs(RecordIndexViewManager.getViewData()) do
		for sRecordView,_ in pairs(tRecordTypeViews) do
			RecordIndexViewManager.initRecordTypeView(sRecordType, sRecordView);
		end
	end
end
function initRecordTypeView(sRecordType, sRecordView)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	local tRecordView = RecordIndexViewManager.getRecordTypeView(sRecordType, sRecordView);
	if not tRecordType or not tRecordView then
		return;
	end

	local sRecordViewLabelRes = string.format("library_recordview_label_%s_%s", sRecordType, sRecordView);
	local sRecordViewLabel = Interface.getString(sRecordViewLabelRes);
	if (sRecordViewLabel or "") ~= "" then
		local sDisplay = RecordDataManager.getRecordTypeDisplayText(sRecordType);
		RecordIndexViewManager.setDisplayText(sRecordType, sRecordView, "sDisplayText", string.format("%s - %s", sDisplay, sRecordViewLabel));
		local sExport = RecordDataManager.getRecordTypeDisplayTextExport(sRecordType);
		RecordIndexViewManager.setDisplayText(sRecordType, sRecordView, "sExportDisplayText", string.format("%s - %s", sExport, sRecordViewLabel));
	else
		local sDisplayText = Interface.getString(tRecordView.sTitleRes);
		if (sDisplayText or "") == "" then
			sDisplayText = tRecordView.sTitle or "";
		end
		RecordIndexViewManager.setDisplayText(sRecordType, sRecordView, "sDisplayText", sDisplayText);
		RecordIndexViewManager.setDisplayText(sRecordType, sRecordView, "sExportDisplayText", sDisplayText);
	end
end

function getRecordTypeViews(sRecordType, bCreate)
	if not sRecordType then
		return nil;
	end
	local tViewData = RecordIndexViewManager.getViewData();
	if bCreate then
		tViewData[sRecordType] = tViewData[sRecordType] or {};
	end
	return tViewData[sRecordType];
end
function getRecordTypeView(sRecordType, sRecordView)
	local tRecordViewData = RecordIndexViewManager.getRecordTypeViews(sRecordType);
	if not tRecordViewData then
		return nil;
	end
	return tRecordViewData[sRecordView];
end
function setRecordViews(tViewData)
	for sRecordType,tRecordTypeViews in pairs(tViewData) do
		for sRecordView,tRecordView in pairs(tRecordTypeViews) do
			RecordIndexViewManager.setRecordTypeView(sRecordType, sRecordView, tRecordView);
		end
	end
end
function setRecordTypeView(sRecordType, sRecordView, tView)
	local tRecordViewData = RecordIndexViewManager.getRecordTypeViews(sRecordType, true);
	tRecordViewData[sRecordView] = tView;

	if RecordDataManager.isInitialized() then
		RecordIndexViewManager.initRecordTypeView(sRecordType, sRecordView);
	end
end

function getDisplayText(sRecordType, sRecordView, sKey)
	if not sKey then
		return "";
	end
	local tRecordView = RecordIndexViewManager.getRecordTypeView(sRecordType, sRecordView);
	if not tRecordView then
		return "";
	end
	if not tRecordView.tDisplayText then
		return "";
	end
	return tRecordView.tDisplayText[sKey];
end
function setDisplayText(sRecordType, sRecordView, sKey, s)
	if not sKey then
		return false;
	end
	local tRecordView = RecordIndexViewManager.getRecordTypeView(sRecordType, sRecordView);
	if not tRecordView then
		return false;
	end
	tRecordView.tDisplayText = tRecordView.tDisplayText or {};
	tRecordView.tDisplayText[sKey] = s;
	return true;
end

local _tCustomFilterHandlers = {};
function setCustomFilterHandler(sKey, fn)
	if not sKey then
		return;
	end
	_tCustomFilterHandlers[sKey] = fn;
end
function getCustomFilterValue(sKey, nodeRecord, rFilter)
	if sKey and _tCustomFilterHandlers[sKey] then
		return _tCustomFilterHandlers[sKey](nodeRecord, rFilter);
	end
	if rFilter then
		return rFilter.vDefaultVal;
	end
	return nil;
end

local _tCustomColumnHandlers = {};
function setCustomColumnHandler(sKey, fn)
	if not sKey then
		return;
	end
	_tCustomColumnHandlers[sKey] = fn;
end
function getCustomColumnValue(sKey, nodeRecord, vDefault)
	if sKey and _tCustomColumnHandlers[sKey] then
		return _tCustomColumnHandlers[sKey](nodeRecord, vDefault);
	end
	return vDefault;
end

local _tCustomGroupOutputHandlers = {};
function setCustomGroupOutputHandler(sKey, fn)
	if not sKey then
		return;
	end
	_tCustomGroupOutputHandlers[sKey] = fn;
end
function getCustomGroupOutput(sKey, vGroupValue)
	if sKey and _tCustomGroupOutputHandlers[sKey] then
		return _tCustomGroupOutputHandlers[sKey](vGroupValue);
	end
	return vGroupValue;
end
