--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function getRecordData()
	return LibraryData.getRecordData();
end

local _bInitialized = false;
function isInitialized()
	return _bInitialized;
end
function setInitialized(bState)
	_bInitialized = bState;
end

function initialize()
	RecordDataManager.initRecordTypes();
	RecordIndexViewManager.initViews();
	RecordDataManager.setInitialized(true);
end
function initRecordTypes()
	for sRecordType,_ in pairs(RecordDataManager.getRecordData()) do
		RecordDataManager.initRecordType(sRecordType);
	end
end
function initRecordType(sRecordType)
	if not RecordDataManager.isRecordType(sRecordType) then
		return;
	end

	RecordDataManager.setDisplayText(sRecordType, "sDisplayText", Interface.getString("library_recordtype_label_" .. sRecordType));
	RecordDataManager.setDisplayText(sRecordType, "sEmptyNameText", Interface.getString("library_recordtype_empty_" .. sRecordType));
	local sExport = Interface.getString("library_recordtype_export_" .. sRecordType);
	if sExport == "" then
		sExport = RecordDataManager.getRecordTypeDisplayText(sRecordType);
	end
	RecordDataManager.setDisplayText(sRecordType, "sExportDisplayText", sExport);
	local sSingle = Interface.getString("library_recordtype_single_" .. sRecordType);
	if sSingle == "" then
		sSingle = RecordDataManager.getRecordTypeDisplayText(sRecordType):gsub("s$", "");
	end
	RecordDataManager.setDisplayText(sRecordType, "sSingleDisplayText", sSingle);

	if RecordDataManager.getRecordTypeOption(sRecordType, "bID") then
		RecordDataManager.setDisplayText(sRecordType, "sEmptyUnidentifiedNameText", Interface.getString("library_recordtype_empty_nonid_" .. sRecordType));
	end

	RecordDataManager.initRecordTypeExport(sRecordType);
end
function initRecordTypeExport(sRecordType)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return;
	end
	local aMappings = RecordDataManager.getDataPaths(sRecordType);
	if #(aMappings or {}) <= 0 then
		return;
	end
	local rExport = {};
	rExport.name = sRecordType;
	rExport.label = RecordDataManager.getRecordTypeDisplayTextExport(sRecordType);
	rExport.listclass = tRecordType.sExportListClass;
	if not rExport.listclass and not RecordDataManager.getRecordTypeOption(sRecordType, "bExportListSkip") then
		rExport.listclass = "reference_list";
	end

	if tRecordType.sExportPath then
		rExport.source = aMappings[1];
		rExport.export = tRecordType.sExportPath;
		rExport.exportref = tRecordType.sExportPath;
	elseif tRecordType.nExport then
		local aExportMappings = {};
		local aExportRefMappings = {};
		for i = 1, tRecordType.nExport do
			if aMappings[i] then
				table.insert(aExportMappings, aMappings[i]);
			end
			if aMappings[tRecordType.nExport + i] then
				table.insert(aExportRefMappings, aMappings[tRecordType.nExport + i]);
			elseif aMappings[i] then
				table.insert(aExportRefMappings, aMappings[i]);
			end
		end
		if #aExportMappings > 0 then
			rExport.source = UtilityManager.copyDeep(aExportMappings);
			rExport.export = UtilityManager.copyDeep(aExportMappings);
			rExport.exportref = UtilityManager.copyDeep(aExportRefMappings);
		end
	elseif RecordDataManager.getRecordTypeOption(sRecordType, "bExportNoReadOnly") then
		rExport.source = aMappings[1];
		rExport.export = aMappings[1];
		rExport.exportref = aMappings[1];
	elseif RecordDataManager.getRecordTypeOption(sRecordType, "bExport") then
		rExport.source = aMappings[1];
		rExport.export = aMappings[1];
		rExport.exportref = aMappings[2];
	end

	if tRecordType.aExportAuxSource and tRecordType.aExportAuxTarget and (#(tRecordType.aExportAuxSource) == #(tRecordType.aExportAuxTarget)) then
		if type(rExport.source) ~= "table" then
			rExport.source = { rExport.source };
		end
		if type(rExport.export) ~= "table" then
			rExport.export = { rExport.export };
		end
		if rExport.exportref and (type(rExport.exportref) ~= "table") then
			rExport.exportref = { rExport.exportref };
		end

		for _,v in ipairs(tRecordType.aExportAuxSource) do
			table.insert(rExport.source, v);
		end
		for _,v in ipairs(tRecordType.aExportAuxTarget) do
			table.insert(rExport.export, v);
		end
		if rExport.exportref then
			for _,v in ipairs(tRecordType.aExportAuxRefTarget or tRecordType.aExportAuxTarget) do
				table.insert(rExport.exportref, v);
			end
		end
	end

	if rExport.source then
		ExportManager.registerExportNode(rExport);
	end
end

function getRecordTypes()
	local tResults = {};
	for sRecordType,_ in pairs(RecordDataManager.getRecordData()) do
		table.insert(tResults, sRecordType);
	end
	table.sort(tResults);
	return tResults;
end
function getRecordTypesWithOption(sOption)
	local tResults = {};
	for sRecordType,_ in pairs(RecordDataManager.getRecordData()) do
		if RecordDataManager.getRecordTypeOption(sRecordType, sOption) then
			table.insert(tResults, sRecordType);
		end
	end
	table.sort(tResults);
	return tResults;
end
function getRecordTypesWithoutOption(sOption)
	local tResults = {};
	for sRecordType,_ in pairs(RecordDataManager.getRecordData()) do
		if not RecordDataManager.getRecordTypeOption(sRecordType, sOption) then
			table.insert(tResults, sRecordType);
		end
	end
	table.sort(tResults);
	return tResults;
end

function getRecordTypeData(sRecordType)
	if not sRecordType then
		return nil;
	end
	return RecordDataManager.getRecordData()[sRecordType];
end
function setRecordTypeData(sRecordType, tRecordType)
	if not sRecordType then
		return;
	end
	RecordDataManager.getRecordData()[sRecordType] = tRecordType;
end
function overrideRecordData(tRecordTypes)
	for k,v in pairs(tRecordTypes) do
		RecordDataManager.overrideRecordTypeData(k, v);
	end
end
function overrideRecordTypeData(sRecordType, tOverrides)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if tRecordType then
		for k,v in pairs(tOverrides) do
			local bFullCopy = true;
			if (k == "tOptions") or (k == "aCustom") then
				if RecordDataManager.helperOverrideTable(tRecordType[k], tOverrides[k]) then
					bFullCopy = false;
				end
			end
			if bFullCopy then
				tRecordType[k] = v;
			end
		end
	else
		RecordDataManager.setRecordTypeData(sRecordType, tOverrides);
	end
end
function helperOverrideTable(tExisting, tOverrides)
	if type(tExisting) ~= "table" or type(tOverrides) ~= "table" then
		return false;
	end
	for k,v in pairs(tOverrides) do
		tExisting[k] = v;
	end
	return true;
end
function isRecordType(sRecordType)
	if RecordDataManager.getRecordData()[sRecordType] then
		return true;
	end
	return false;
end

function getDataPaths(sRecordType)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if tRecordType then
		local sType = type(tRecordType.aDataMap);
		if sType == "table" then
			return tRecordType.aDataMap;
		elseif sType == "string" then
			return { tRecordType.aDataMap };
		end
	end
	return {};
end
function getDataPathRoot(sRecordType)
	return RecordDataManager.getDataPaths(sRecordType)[1];
end
function getAltDataPaths(sRecordType, bCreate)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return {};
	end
	if bCreate then
		tRecordType.tAltDataPaths = tRecordType.tAltDataPaths or {};
	end
	return tRecordType.tAltDataPaths or {};
end
function addAltDataPath(sRecordType, sPath)
	if (sPath or "") == "" then
		return;
	end
	local tAltDataPaths = RecordDataManager.getAltDataPaths(sRecordType, true);
	if not StringManager.contains(tAltDataPaths, sPath) then
		table.insert(tAltDataPaths, sPath);
	end
end
function removeAltDataPath(sRecordType, sPath)
	if (sPath or "") == "" then
		return;
	end
	local tAltDataPaths = RecordDataManager.getAltDataPaths(sRecordType);
	for k, s in ipairs(tAltDataPaths) do
		if s == sPath then
			table.remove(tAltDataPaths, k);
			return;
		end
	end
end

local _tLegacyTags = {
	"bExport",
	"bExportListSkip",
	"bExportNoReadOnly",
	"bHidden",
	"bID",
	"bNoCategories",
	"bNoLock",
	"bNoShare",
};
function getRecordTypeOption(sRecordType, sKey)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return false;
	end
	if tRecordType.tOptions and tRecordType.tOptions[sKey] then
		return true;
	end

	if StringManager.contains(_tLegacyTags, sKey) then
		if tRecordType[sKey] then
			return true;
		end
	end
	return false;
end
function setRecordTypeOption(sRecordType, sKey, bState)
	if RecordDataManager.getRecordTypeOption(sRecordType, sKey) == bState then
		return false;
	end

	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return false;
	end
	tRecordType.tOptions = tRecordType.tOptions or {};
	tRecordType.tOptions[sKey] = bState;
	return true;
end
function getDisplayText(sRecordType, sKey)
	if not sKey then
		return "";
	end
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return "";
	end
	if not tRecordType.tDisplayText then
		return "";
	end
	return tRecordType.tDisplayText[sKey] or "";
end
function setDisplayText(sRecordType, sKey, s)
	if not sKey then
		return false;
	end
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return false;
	end
	tRecordType.tDisplayText = tRecordType.tDisplayText or {};
	tRecordType.tDisplayText[sKey] = s;
	return true;
end

function getFieldData(sRecordType, sField, vDefault)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return vDefault;
	end
	return tRecordType[sField] or vDefault;
end

function getCustomData(sRecordType, sKey, vDefault)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType or not tRecordType.aCustom then
		return vDefault;
	end
	return tRecordType.aCustom[sKey] or vDefault;
end
function setCustomData(sRecordType, sKey, v)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return nil;
	end
	tRecordType.aCustom = tRecordType.aCustom or {};
	tRecordType.aCustom[sKey] = v;
end

function isRecordTypeDisplayClass(sRecordType, sClass)
	if not sClass then
		return false;
	end
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return false;
	end

	if tRecordType.fIsRecordDisplayClass then
		return tRecordType.fIsRecordDisplayClass(sClass);
	elseif tRecordType.aRecordDisplayClasses then
		return StringManager.contains(tRecordType.aRecordDisplayClasses, sClass);
	elseif tRecordType.sRecordDisplayClass then
		return (tRecordType.sRecordDisplayClass == sClass);
	end
	return (sRecordType == sClass);
end
function getAllRecordTypesFromDisplayClass(sClass)
	local tResults = {};
	for sRecordType,_ in pairs(RecordDataManager.getRecordData()) do
		if RecordDataManager.isRecordTypeDisplayClass(sRecordType, sClass) then
			table.insert(tResults, sRecordType);
		end
	end
	return tResults;
end
function getRecordTypeFromDisplayClass(sClass)
	return RecordDataManager.getAllRecordTypesFromDisplayClass(sClass)[1] or "";
end
function getRecordTypeDisplayClass(sRecordType, sPath)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return "";
	end

	if tRecordType.fRecordDisplayClass then
		return tRecordType.fRecordDisplayClass(sPath);
	elseif tRecordType.aRecordDisplayClasses then
		return tRecordType.aRecordDisplayClasses[1];
	elseif tRecordType.sRecordDisplayClass then
		return tRecordType.sRecordDisplayClass;
	end
	return sRecordType;
end

function getRecordTypeFromWindow(w)
	if not w then
		return "";
	end
	return RecordDataManager.getRecordTypeFromClassAndPath(w.getClass(), w.getDatabasePath());
end
function getRecordTypeFromClassAndPath(sClass, sRecord)
	local tRecordTypes = RecordDataManager.getAllRecordTypesFromDisplayClass(sClass);
	if #tRecordTypes == 1 then
		return tRecordTypes[1];
	end
	return RecordDataManager.getRecordTypeFromRecordPath(sRecord);
end
function getListPathFromRecordPath(sRecordPath)
	local sPathSansModule = StringManager.splitByPattern(sRecordPath, "@")[1];
	local tPathSansModule = StringManager.splitByPattern(sPathSansModule, "%.");
	tPathSansModule[#tPathSansModule] = nil;
	return table.concat(tPathSansModule, ".");
end
function getRecordTypeFromRecordPath(sRecordPath)
	if (sRecordPath or "") == "" then
		return "";
	end

	local sListPathSansModule = RecordDataManager.getListPathFromRecordPath(sRecordPath);
	local sRecordType = RecordDataManager.getRecordTypeFromListPath(sListPathSansModule);

	if (sRecordType == "") and CombatManager.isTrackerCT(sListPathSansModule) then
		local sClass,_ = DB.getValue(DB.getPath(sRecordPath, "link"), "", "");
		sRecordType = RecordDataManager.getRecordTypeFromDisplayClass(sClass);
	end

	return sRecordType;
end
function getRecordTypeFromListPath(sListPath)
	for sRecordType,_ in pairs(RecordDataManager.getRecordData()) do
		for _,s in ipairs(RecordDataManager.getDataPaths(sRecordType)) do
			if s == sListPath then
				return sRecordType;
			end
		end
	end
	for sRecordType,_ in pairs(RecordDataManager.getRecordData()) do
		for _,s in ipairs(RecordDataManager.getAltDataPaths(sRecordType)) do
			if UtilityManager.isPathMatch(sListPath, s) then
				return sRecordType;
			end
		end
	end
	return "";
end

function getRecordTypeDisplayText(sRecordType)
	return RecordDataManager.getDisplayText(sRecordType, "sDisplayText");
end
function getRecordTypeDisplayTextSingle(sRecordType)
	return RecordDataManager.getDisplayText(sRecordType, "sSingleDisplayText");
end
function getRecordTypeDisplayTextEmpty(sRecordType)
	return RecordDataManager.getDisplayText(sRecordType, "sEmptyNameText");
end
function getRecordTypeDisplayTextEmptyUnidentified(sRecordType)
	return RecordDataManager.getDisplayText(sRecordType, "sEmptyUnidentifiedNameText");
end
function getRecordTypeDisplayTextExport(sRecordType)
	return RecordDataManager.getDisplayText(sRecordType, "sExportDisplayText");
end

function isHidden(sRecordType)
	return RecordDataManager.getRecordTypeOption(sRecordType, "bHidden");
end
function setHidden(sRecordType, bState)
	if RecordDataManager.setRecordTypeOption(sRecordType, "bHidden", bState) then
		DesktopManager.rebuildSidebar();
	end
end

function getDuplicateMode(sRecordType)
	if not RecordDataManager.isRecordType(sRecordType) then
		return false;
	end
	return RecordIndexManager.getEditMode(sRecordType) and not RecordDataManager.getRecordTypeOption(sRecordType, "bNoDuplicate");
end

function getLockMode(sRecordType)
	if not RecordDataManager.isRecordType(sRecordType) then
		return false;
	end
	return not RecordDataManager.getRecordTypeOption(sRecordType, "bNoLock");
end
function getShareMode(sRecordType)
	if not RecordDataManager.isRecordType(sRecordType) then
		return false;
	end
	return not RecordDataManager.getRecordTypeOption(sRecordType, "bNoShare");
end
function getTokenMode(sRecordType)
	return RecordDataManager.getRecordTypeOption(sRecordType, "bToken");
end
function getPictureMode(sRecordType)
	return RecordDataManager.getRecordTypeOption(sRecordType, "bPicture");
end
function getCustomDieMode(sRecordType)
	return RecordDataManager.getRecordTypeOption(sRecordType, "bCustomDie");
end

function getExportMode(sRecordType)
	return (RecordDataManager.getExportTag(sRecordType) ~= "");
end
function getExportTag(sRecordType)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return "";
	end
	return tRecordType.sExportTag or (Session.IsHost and tRecordType.sGMExportTag) or "";
end

function getIDMode(sRecordType)
	return RecordDataManager.getRecordTypeOption(sRecordType, "bID");
end
function isIdentifiable(sRecordType, nodeRecord)
	if not RecordDataManager.getIDMode(sRecordType) then
		return;
	end

	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return false;
	end

	if tRecordType.fIsIdentifiable then
		return tRecordType.fIsIdentifiable(nodeRecord);
	end
	return true;
end
function getIDState(sRecordType, nodeRecord, bIgnoreHost)
	local bID = true;

	if RecordDataManager.isIdentifiable(sRecordType, nodeRecord) then
		local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
		if tRecordType then
			if tRecordType.fGetIDState then
				bID = tRecordType.fGetIDState(nodeRecord, bIgnoreHost);
			else
				if (bIgnoreHost or not Session.IsHost) then
					bID = (DB.getValue(nodeRecord, "isidentified", 1) == 1);
				end
			end
		end
	end

	return bID;
end

function getRecordDisplayName(nodeRecord, sClass, bPrefix)
	if not nodeRecord then
		return "";
	end

	local sRecordType = RecordDataManager.getRecordTypeFromClassAndPath(sClass, DB.getPath(nodeRecord));

	local sDesc;
	if (sRecordType or "") ~= "" then
		if RecordDataManager.getIDState(sRecordType, nodeRecord, true) then
			sDesc = DB.getValue(nodeRecord, "name", "");
			if sDesc == "" then
				sDesc = Interface.getString("library_recordtype_empty_" .. sRecordType);
			end
		else
			sDesc = DB.getValue(nodeRecord, "nonid_name", "");
			if sDesc == "" then
				sDesc = Interface.getString("library_recordtype_empty_nonid_" .. sRecordType);
			end
		end

		if bPrefix then
			local sDisplayTitle = RecordDataManager.getRecordTypeDisplayTextSingle(sRecordType);
			if (sDisplayTitle or "") ~= "" then
				sDesc = sDisplayTitle .. ": " .. sDesc;
			end
		end
	else
		sDesc = DB.getValue(nodeRecord, "name", "");
	end

	return sDesc;
end
