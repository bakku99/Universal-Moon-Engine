--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

function onInit()
	SoundManager.registerSoundSystem("file", { script = SoundManagerFile });
end

--
--	SOUND SYSTEM SUPPORT
--

function parseSoundID(sSoundID)
	local tSplit = StringManager.splitByPattern(sSoundID, "|", true);
	if #tSplit ~= 3 then
		return nil;
	end

	return {
		sSoundID = sSoundID,
		sSoundType = "file",
		sPath = tSplit[2],
		sName = tSplit[3],
	};
end
function playSound(sSoundID)
	local tSound = SoundManager.parseSoundID(sSoundID, true);
	if not tSound then
		return;
	end

	-- Build and encode the file path
	local sUnencodedFilePath = File.getDataFolder() .. tSound.sPath;
	local sEncodedFilePath = sUnencodedFilePath:gsub("&", "%%26"):gsub(" ", "%%20");

	-- Generate file URL and send
	local sFileURL;
	if StringManager.startsWith(sEncodedFilePath, "/") then
		sFileURL = string.format("file://%s", sEncodedFilePath);
	else
		sFileURL = string.format("file:///%s", sEncodedFilePath);
	end
	Interface.openWindow("url", sFileURL);
end

-- NOTE: No way to stop file sounds. User will have to stop in whatever player they set to play the sound.
-- function stopSound(sSoundID)
-- end

--
--	SOUND DATA
--

local _tData = {};
function getSoundData()
	return _tData;
end
function setSoundData(tData, bSave)
	_tData = tData;
	SoundManagerFile.rebuildFilters();

	if bSave then
		SoundManagerFile.saveData();
	end

	SoundManager.refreshSettingsFilter();
	SoundManager.refreshSettingsContent();
end

function getDataFilePath()
	return File.getDataFolder() .. "sounds_file.csv";
end
local _bLoaded = false;
function loadData()
	if _bLoaded then
		return;
	end
	_bLoaded = true;

	local sFile = File.openTextFile(SoundManagerFile.getDataFilePath());
	if sFile then
		local tSoundData = {};
		if sFile ~= "" then
			local tDecodedData = Utility.decodeCSV(sFile);
			for _,v in pairs(tDecodedData) do
				local tSound = SoundManagerFile.parseSoundID(v[1]);
				if tSound then
					table.insert(tSoundData, tSound);
				end
			end
		end
		SoundManagerFile.setSoundData(tSoundData);
	end
end
function saveData()
	local tProcessed = {};
	for _,v in ipairs(SoundManagerFile.getSoundData()) do
		table.insert(tProcessed, { v.sSoundID });
	end

	local tEncodedData = Utility.encodeCSV(tProcessed);
	File.saveTextFile(SoundManagerFile.getDataFilePath(), tEncodedData);
end

local _tFilterValues = {};
function rebuildFilters()
	SoundManagerFile.clearFilterValues();
end
function getFilterValues(sKey)
	return _tFilterValues[sKey] or {};
end
function clearFilterValues()
	_tFilterValues = {};
end
function setFilterValue(sKey, s)
	_tFilterValues[sKey] = s;
end
function getFilterValue(sKey)
	return _tFilterValues[sKey] or "";
end

--
--	UI HANDLING
--

function sortfuncSettingsContent(a, b)
	return (a.sName or "") < (b.sName or "");
end
function isSettingsContentFilteredRecord(v)
	local sFilter = SoundManagerFile.getFilterValue("");
	if sFilter ~= "" then
		if not string.find(v.sPath:lower(), sFilter, 0, true) then
			return false;
		end
	end

	return true;
end
function onSettingsFilterChanged(tValuesLower)
	if not SoundManager.getFilterUpdate() then
		return;
	end

	local bChanged = false;

	if SoundManagerFile.getFilterValue("") ~= (tValuesLower[""] or "") then
		SoundManagerFile.setFilterValue("", tValuesLower[""]);
		bChanged = true;
	end

	if bChanged then
		SoundManager.refreshSettingsContent();
	end
end
function handleSettingsContentDrop(draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		local sRecordType = RecordDataManager.getRecordTypeFromDisplayClass(sClass);
		if sRecordType ~= "" then
			local sName = DB.getValue(DB.findNode(sRecord), "name", "");

			SoundManagerFile.clearFilterValues();
			SoundManagerFile.setFilterValue("name", sName);
			SoundManager.setFilterNameControl(sName);
			return true;
		end
	end
end

-- Manually import text list (comma-separated) filepaths  (Append)
function onButtonImportText()
	if not Session.IsHost then
		return;
	end
	Interface.openWindow("sound_settings_file_import_text", "");
end
function processImportText(sText)
	local tSoundData = SoundManagerFile.getSoundData();
	local nOriginalData = #tSoundData;

	local bFilePathError = false;
	local tSplit = StringManager.split(sText, "\r\n", true);
	for _,sEntry in ipairs(tSplit) do
		local tSound = SoundManagerFile.helperImportFilePath(sEntry);
		if tSound then
			table.insert(tSoundData, tSound);
		else
			bFilePathError = true;
		end
	end
	if #tSoundData ~= nOriginalData then
		SoundManagerFile.setSoundData(tSoundData, true);
	end

	if bFilePathError then
		ChatManager.SystemMessage(Interface.getString("sound_error_file_invalid_filepath"));
	end
end

-- Manually import CSV file from desktop CSV file  (Replace)
function onButtonImportCSV()
	if not Session.IsHost then
		return;
	end
	Interface.dialogFileOpen(SoundManagerFile.onDialogEndImportCSV, { csv = "CSV Files" }, File.getDataFolder(), false);
end
function onDialogEndImportCSV(sResult, sPath)
	if sResult ~= "ok" then
		return;
	end

	local bFilePathError = false;
	local sCSV = File.openTextFile(sPath);
	local tDecodedData = Utility.decodeCSV(sCSV);
	local tSoundData = {};
	for _,v in ipairs(tDecodedData) do
		local tSound = SoundManagerFile.helperImportFilePath(v[1]);
		if tSound then
			table.insert(tSoundData, tSound);
		else
			bFilePathError = true;
		end
	end
	SoundManagerFile.setSoundData(tSoundData, true);

	if bFilePathError then
		ChatManager.SystemMessage(Interface.getString("sound_error_file_invalid_filepath"));
	end
end

function onButtonClear()
	Interface.dialogMessage(SoundManagerFile.onDialogEndClear,
		Interface.getString("sound_dialog_settings_file_clear_message"),
		Interface.getString("sound_dialog_settings_file_clear_title"),
		"okcancel");
end
function onDialogEndClear(sResult)
	if sResult ~= "ok" then
		return;
	end
	SoundManagerFile.setSoundData({}, true);
end

--
--	MISC
--

function helperImportFilePath(sFilePath)
	if (sFilePath or "") == "" then
		return nil;
	end

	-- Ensure all path separators are the same
	sFilePath = sFilePath:gsub("\\", "/");

	-- Remove encapsulating quotes (for import)
	local sSansQuotes = sFilePath:match("^\"(.*)\"$");
	if sSansQuotes then
		sFilePath = sSansQuotes;
	end

	local sDataFolder = File.getDataFolder();
	if not StringManager.startsWith(sFilePath, sDataFolder) then
		return nil;
	end
	local sSubPath = sFilePath:sub(#sDataFolder + 1);

	-- Split by path separator
	local tPathSplit = StringManager.split(sSubPath, "/", true);
	if #tPathSplit < 1 then
		return nil;
	end

	return {
		sSoundID = string.format("file|%s|%s", sSubPath, tPathSplit[#tPathSplit]),
		sSoundType = "file",
		sPath = sSubPath,
		sName = tPathSplit[#tPathSplit],
	};
end
