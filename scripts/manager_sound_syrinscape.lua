--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

PATH_AUTHTOKEN = "settings.sound.ss.authtoken";
PATH_SESSION = "settings.sound.ss.sessionid";

function onInit()
	SoundManager.registerSoundSystem("ss", { script = SoundManagerSyrinscape });
	SoundManagerSyrinscape.loadConfig();
end
function onClose()
	SoundManagerSyrinscape.saveConfig();
end

function loadConfig()
	SoundManagerSyrinscape.setAuthorizationToken(SoundManagerSyrinscape.loadAuthorizationToken());
	SoundManagerSyrinscape.setSession(SoundManagerSyrinscape.loadSession());

	SoundManagerSyrinscape.loadVolume();
end
function saveConfig()
	SoundManagerSyrinscape.saveAuthorizationToken(SoundManagerSyrinscape.getAuthorizationToken());
	SoundManagerSyrinscape.saveSession(SoundManagerSyrinscape.getSession());
	SoundManagerSyrinscape.cleanUpDatabase();

	SoundManagerSyrinscape.saveVolume();
end

function cleanUpDatabase()
	if not Session.IsHost then
		return;
	end
	DB.deleteNode(SoundManagerSyrinscape.PATH_AUTHTOKEN);
	DB.deleteNode(SoundManagerSyrinscape.PATH_SESSION);
end

--
--	SOUND SYSTEM SUPPORT
--

function parseSoundID(sSoundID)
	local tSplit = StringManager.splitByPattern(sSoundID, "|", true);
	if #tSplit ~= 5 then
		return nil;
	end

	local tSound = {
		sSoundID = sSoundID,
		sSoundType = "ss",
		sID = tSplit[2],
		sType = tSplit[3],
		sSubtype = tSplit[4],
		sName = tSplit[5],
	};
	SoundManagerSyrinscape.parseDisplayType(tSound);
	return tSound;
end
function playSound(sSoundID)
	local tSound = SoundManager.parseSoundID(sSoundID, true);
	if not tSound then
		return;
	end

	if not SoundManagerSyrinscape.checkAuthToken(true) then
		return;
	end

	local sURL = SoundManagerSyrinscape.buildPlayURL(tSound);
	if sURL == "" then
		ChatManager.SystemMessage(Interface.getString("sound_error_ss_invalid_type"));
		return;
	end

	Interface.openURL(sURL, nil);
	SoundManagerSyrinscape.addToNowPlaying(tSound);
end
function stopSound(sSoundID)
	local tSound = SoundManager.parseSoundID(sSoundID, true);
	if not tSound then
		return;
	end

	if not SoundManagerSyrinscape.checkAuthToken(true) then
		return;
	end

	local sURL = SoundManagerSyrinscape.buildStopURL(tSound);
	if sURL == "" then
		ChatManager.SystemMessage(Interface.getString("sound_error_ss_invalid_type"));
		return;
	end

	Interface.openURL(sURL, nil);
	SoundManagerSyrinscape.removeFromNowPlaying(tSound);
end
function stopAll()
	if not SoundManagerSyrinscape.checkAuthToken(false) then
		return;
	end

	ChatManager.SystemMessage(Interface.getString("sound_message_ss_stopall"));

	local sURL = SoundManagerSyrinscape.buildStopAllURL();
	if sURL == "" then
		return;
	end
	Interface.openURL(sURL, nil);

	SoundManagerSyrinscape.clearNowPlaying();
end

function buildPlayURL(tSound)
	if tSound.sType == "element" then
		return SoundManagerSyrinscape.getURLWithAuthToken("elements/" .. tSound.sID .. "/play/");
	elseif tSound.sType == "mood" then
		return SoundManagerSyrinscape.getURLWithAuthToken("moods/" .. tSound.sID .. "/play/");
	end
	return "";
end
function buildStopURL(tSound)
	if tSound.sType == "element" then
		return SoundManagerSyrinscape.getURLWithAuthToken("elements/" .. tSound.sID .. "/stop/");
	elseif tSound.sType == "mood" then
		return SoundManagerSyrinscape.getURLWithAuthToken("moods/" .. tSound.sID .. "/stop/");
	end
	return "";
end
function buildStopAllURL()
	return SoundManagerSyrinscape.getURLWithAuthToken("stop-all/");
end

--
--	SOUND DATA
--

INDEX_SS_ID = 1;
INDEX_SS_SUBCATEGORY = 3;
INDEX_SS_PRODUCTPACK = 4;
INDEX_SS_SOUNDSET = 5;
INDEX_SS_NAME = 6;
INDEX_SS_TYPE = 7;
INDEX_SS_SUBTYPE = 8;

local _tData = {};
function getSoundData()
	return _tData;
end
function setSoundData(tData, bSave)
	_tData = tData;
	SoundManagerSyrinscape.rebuildFilters();

	if bSave then
		SoundManagerSyrinscape.saveData();
	end

	SoundManager.refreshSettingsFilter();
	SoundManager.refreshSettingsContent();
end

function getDataFilePath()
	return File.getDataFolder() .. "sounds_syrinscape.csv";
end
local _bLoaded = false;
function loadData()
	if _bLoaded then
		return;
	end
	_bLoaded = true;

	local sFile = File.openTextFile(SoundManagerSyrinscape.getDataFilePath());
	if sFile then
		if sFile ~= "" then
			local tDecodedData = Utility.decodeCSV(sFile);
			SoundManagerSyrinscape.setSoundData(tDecodedData);
		else
			SoundManagerSyrinscape.setSoundData({});
		end
	end
end
function saveData()
	local tData = SoundManagerSyrinscape.getSoundData();
	local tEncodedData = Utility.encodeCSV(tData);
	File.saveTextFile(SoundManagerSyrinscape.getDataFilePath(), tEncodedData);
end

local _tFilters = {};
local _tFilterValues = {};
function rebuildFilters()
	_tFilters["type"] = { "mood", "music", "oneshot", "sfx" };
	_tFilters["subcategory"] = SoundManagerSyrinscape.getSoundDataFilterChoices(SoundManagerSyrinscape.INDEX_SS_SUBCATEGORY);
	_tFilters["product"] = SoundManagerSyrinscape.getSoundDataFilterChoices(SoundManagerSyrinscape.INDEX_SS_PRODUCTPACK);

	SoundManagerSyrinscape.clearFilterValues();
end
function getFilterValues(sKey)
	return _tFilters[sKey] or {};
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

function getSoundDataID(v)
	return v[SoundManagerSyrinscape.INDEX_SS_ID]:sub(3);
end
function getSoundDataRecord(v, bBuildID)
	local tSound = {
		sSoundType = "ss",
		sID = v[SoundManagerSyrinscape.INDEX_SS_ID]:sub(3),
		sType = StringManager.trim(v[SoundManagerSyrinscape.INDEX_SS_TYPE]):lower(),
		sSubtype = StringManager.trim(v[SoundManagerSyrinscape.INDEX_SS_SUBTYPE]):lower(),
		sName = StringManager.trim(v[SoundManagerSyrinscape.INDEX_SS_NAME]),
		sSoundSet = v[SoundManagerSyrinscape.INDEX_SS_SOUNDSET],
		sProductPack = SoundManagerSyrinscape.cleanUpProductPack(v[SoundManagerSyrinscape.INDEX_SS_PRODUCTPACK]),
		sSubcategory = v[SoundManagerSyrinscape.INDEX_SS_SUBCATEGORY],
	};
	SoundManagerSyrinscape.parseDisplayType(tSound);
	if bBuildID then
		tSound.sSoundID = string.format("ss|%s|%s|%s|%s", tSound.sID, tSound.sType, tSound.sSubtype, tSound.sName);
	end
	return tSound;
end
function getSoundDataFilterChoices(index)
	local tUniqueChoices = {};
	for _,v in ipairs(SoundManagerSyrinscape.getSoundData()) do
		if not tUniqueChoices[v[index]] then
			tUniqueChoices[v[index]] = true;
		end
	end

	local tChoices = {};
	for k,_ in pairs(tUniqueChoices) do
		table.insert(tChoices, k);
	end

	table.sort(tChoices);

	if index == SoundManagerSyrinscape.INDEX_SS_PRODUCTPACK then
		for i = 1, #tChoices do
			tChoices[i] = SoundManagerSyrinscape.cleanUpProductPack(tChoices[i]);
		end
	end

	return tChoices;
end
function cleanUpProductPack(s)
	return StringManager.capitalizeAll(StringManager.trim(s):gsub(" %- Free with Syrinscape Fantasy Player$", ""));
end
function parseDisplayType(tSound)
	if tSound.sType == "element" and tSound.sSubtype ~= "" then
		tSound.sDisplayType = tSound.sSubtype;
	else
		tSound.sDisplayType = tSound.sType;
	end
end

--
--	UI HANDLING
--

function sortfuncSettingsContent(a, b)
	local sNameA = StringManager.trim(a[SoundManagerSyrinscape.INDEX_SS_NAME]);
	local sNameB = StringManager.trim(b[SoundManagerSyrinscape.INDEX_SS_NAME]);
	return sNameA < sNameB;
end
function isSettingsContentFilteredRecord(v)
	local tSound = SoundManagerSyrinscape.getSoundDataRecord(v);

	local sFilter = SoundManagerSyrinscape.getFilterValue("name");
	if sFilter ~= "" then
		if not string.find(tSound.sName:lower(), sFilter, 0, true) then
			return false;
		end
	end
	sFilter = SoundManagerSyrinscape.getFilterValue("id");
	if sFilter ~= "" then
		if not string.find(tSound.sID:lower(), sFilter, 0, true) then
			return false;
		end
	end
	sFilter = SoundManagerSyrinscape.getFilterValue("type");
	if sFilter ~= "" then
		if not string.find(tSound.sDisplayType, sFilter, 0, true) then
			return false;
		end
	end
	sFilter = SoundManagerSyrinscape.getFilterValue("subcategory");
	if sFilter ~= "" then
		if not string.find(tSound.sSubcategory:lower(), sFilter, 0, true) then
			return false;
		end
	end
	sFilter = SoundManagerSyrinscape.getFilterValue("product");
	if sFilter ~= "" then
		if not string.find(tSound.sProductPack:lower(), sFilter, 0, true) then
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

	if SoundManagerSyrinscape.getFilterValue("name") ~= (tValuesLower["name"] or "") then
		SoundManagerSyrinscape.setFilterValue("name", tValuesLower["name"]);
		bChanged = true;
	end
	if SoundManagerSyrinscape.getFilterValue("id") ~= (tValuesLower["id"] or "") then
		SoundManagerSyrinscape.setFilterValue("id", tValuesLower["id"]);
		bChanged = true;
	end
	if SoundManagerSyrinscape.getFilterValue("type") ~= (tValuesLower["type"] or "") then
		SoundManagerSyrinscape.setFilterValue("type", tValuesLower["type"]);
		bChanged = true;
	end
	if SoundManagerSyrinscape.getFilterValue("subtype") ~= (tValuesLower["subtype"] or "") then
		SoundManagerSyrinscape.setFilterValue("subtype", tValuesLower["subtype"]);
		bChanged = true;
	end
	if SoundManagerSyrinscape.getFilterValue("subcategory") ~= (tValuesLower["subcategory"] or "") then
		SoundManagerSyrinscape.setFilterValue("subcategory", tValuesLower["subcategory"]);
		bChanged = true;
	end
	if SoundManagerSyrinscape.getFilterValue("product") ~= (tValuesLower["product"] or "") then
		SoundManagerSyrinscape.setFilterValue("product", tValuesLower["product"]);
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

function openSettingsAuthorization()
	if not Session.IsHost then
		return;
	end
	Interface.openWindow("sound_settings_ss_authorization", "settings.sound.ss");
end

-- Manually import CSV file from desktop  (Replace)
function onButtonImportCSV()
	if not Session.IsHost then
		return;
	end
	Interface.dialogFileOpen(SoundManagerSyrinscape.onDialogEndImportCSV, { csv = "CSV Files" }, File.getDataFolder(), false);
end
function onDialogEndImportCSV(sResult, sPath)
	if sResult ~= "ok" then
		return;
	end

	local sFile = File.openTextFile(sPath);
	local tDecodedData = Utility.decodeCSV(sFile);
	table.remove(tDecodedData, 1); -- Used to "pop" header row off the results

	SoundManagerSyrinscape.setSoundData(tDecodedData, true);
end

-- Request download of CSV Sheet from Syrinscape [ONLINE NEEDED]  (Replace)
function onButtonImportWeb()
	if not Session.IsHost then
		return;
	end
	if not SoundManagerSyrinscape.checkAuthToken(true) then
		return;
	end

	Interface.openURL(SoundManagerSyrinscape.getWebImportURL(), SoundManagerSyrinscape.onWebImportComplete);

	ChatManager.SystemMessage(Interface.getString("sound_message_ss_import_web"));
end
function onWebImportComplete(_, sResponse)
	if not sResponse then
		ChatManager.SystemMessage(Interface.getString("sound_error_ss_import_web"));
		return;
	end

	local tDecodedData = Utility.decodeCSV(sResponse);
	table.remove(tDecodedData, 1); -- Used to "pop" header row off the results

	-- Sanitize data and strip off anything we don't want from the syrinscape spreadsheet
	for _,v in ipairs(tDecodedData) do
		if v then
			local nMax = #v;
			for i = 9, nMax do
				v[i] = nil;
			end
		end
	end

	SoundManagerSyrinscape.setSoundData(tDecodedData, true);

	ChatManager.SystemMessage(Interface.getString("sound_message_ss_import_web_success"));
end

--
--	UI CONTEXT SUPPORT
--

local _tNowPlaying = {};
function getNowPlaying(tData)
	for _,v in ipairs(_tNowPlaying) do
		table.insert(tData, v);
	end
end

function clearNowPlaying()
	if #_tNowPlaying == 0 then
		return;
	end

	_tNowPlaying = {};
	SoundManager.refreshNowPlaying();
end
function addToNowPlaying(tSound)
	if not tSound then
		return;
	end
	if SoundManagerSyrinscape.helperAddToNowPlayingTable(tSound) then
		SoundManager.refreshNowPlaying();
	end
end
function removeFromNowPlaying(tSound)
	if not tSound then
		return;
	end
	if SoundManagerSyrinscape.helperRemoveFromNowPlayingTable(tSound) then
		SoundManager.refreshNowPlaying();
	end
end

function helperAddToNowPlayingTable(tSound)
	-- Check to see if this is repeating sound we should be tracking in Now Playing list
	if (tSound.sType ~= "mood") and StringManager.contains({"", "oneshot"}, tSound.sSubtype) then
		return false;
	end
	if SoundManagerSyrinscape.helperFindInNowPlayingTable(tSound) then
		return false;
	end
	-- If "mood", then Syrinscape will automatically stop any other moods or non one-shot sounds
	if tSound.sType == "mood" then
		SoundManagerSyrinscape.clearNowPlaying();
	end
	table.insert(_tNowPlaying, tSound);
	return true;
end
function helperRemoveFromNowPlayingTable(tSound)
	for k,v in ipairs(_tNowPlaying) do
		if v.sSoundID == tSound.sSoundID then
			table.remove(_tNowPlaying, k);
			return true;
		end
	end
	return false;
end
function helperFindInNowPlayingTable(tSound)
	for _,v in ipairs(_tNowPlaying) do
		if v.sSoundID == tSound.sSoundID then
			return true;
		end
	end
	return false;
end

--
--	VOLUME CONTROL
--

local VOLUME_DEFAULT_GLOBAL = 100;
local VOLUME_DEFAULT_ONESHOT = 100;

local VOLUME_MIN = 0;
local VOLUME_MAX = 150;
local VOLUME_STEP = 5;

local _bGlobalMuted = false;
local _bOneShotMuted = false;
local _nGlobalVolume = VOLUME_DEFAULT_GLOBAL;
local _nOneShotVolume = VOLUME_DEFAULT_ONESHOT;

function loadVolume()
	if not Session.IsHost then
		return;
	end
	if not GlobalRegistry then
		return;
	end
	if GlobalRegistry.sound and GlobalRegistry.sound.ss then
		_nGlobalVolume = GlobalRegistry.sound.ss.volume_global or VOLUME_DEFAULT_GLOBAL;
		_nOneShotVolume = GlobalRegistry.sound.ss.volume_oneshot or VOLUME_DEFAULT_ONESHOT;
	end
end
function saveVolume()
	if not Session.IsHost then
		return;
	end
	if not GlobalRegistry then
		return;
	end
	GlobalRegistry.sound = GlobalRegistry.sound or {};
	GlobalRegistry.sound.ss = GlobalRegistry.sound.ss or {};
	GlobalRegistry.sound.ss.volume_global = _nGlobalVolume;
	GlobalRegistry.sound.ss.volume_oneshot = _nOneShotVolume;
end

function getGlobalMute()
	return _bGlobalMuted;
end
function setGlobalMute(bValue)
	if not Session.IsHost then
		return;
	end
	if _bGlobalMuted == bValue then
		return;
	end

	_bGlobalMuted = bValue;
	SoundManagerSyrinscape.updateVolumeDisplay();

	SoundManagerSyrinscape.postGlobalVolume(true);
end
function getOneShotMute()
	return _bOneShotMuted;
end
function setOneShotMute(bValue)
	if not Session.IsHost then
		return;
	end
	if _bOneShotMuted == bValue then
		return;
	end

	_bOneShotMuted = bValue;
	SoundManagerSyrinscape.updateVolumeDisplay();

	SoundManagerSyrinscape.postOneShotVolume(true);
end
function getGlobalVolume()
	if _bGlobalMuted then
		return VOLUME_MIN;
	end
	return _nGlobalVolume;
end
function getOneShotVolume()
	if _bOneShotMuted then
		return VOLUME_MIN;
	end
	return _nOneShotVolume;
end
function setGlobalVolume(n)
	if not Session.IsHost then
		return;
	end
	if SoundManagerSyrinscape.getGlobalMute() then
		return;
	end

	_nGlobalVolume = math.max(VOLUME_MIN, math.min(VOLUME_MAX, n));
	SoundManagerSyrinscape.updateVolumeDisplay();

	SoundManagerSyrinscape.postGlobalVolume(true);
end
function setOneShotVolume(n)
	if not Session.IsHost then
		return;
	end
	if SoundManagerSyrinscape.getOneShotMute() then
		return;
	end

	_nOneShotVolume = math.max(VOLUME_MIN, math.min(VOLUME_MAX, n));
	SoundManagerSyrinscape.updateVolumeDisplay();

	SoundManagerSyrinscape.postOneShotVolume(true);
end
function stepGlobalVolume(nStep)
	SoundManagerSyrinscape.setGlobalVolume(_nGlobalVolume + (nStep * VOLUME_STEP));
end
function stepOneShotVolume(nStep)
	SoundManagerSyrinscape.setOneShotVolume(_nOneShotVolume + (nStep * VOLUME_STEP));
end

function updateVolumeDisplay(wContext)
	if not wContext then
		wContext = SoundManager.getContextWindow();
	end
	if wContext then
		wContext.sub_ss.subwindow.globalvolume.setValue(SoundManagerSyrinscape.getGlobalVolume());
		wContext.sub_ss.subwindow.oneshotvolume.setValue(SoundManagerSyrinscape.getOneShotVolume());
	end
end

function postGlobalVolume(bShowError)
	if SoundManagerSyrinscape.checkAuthToken(bShowError) then
		local nVolume = SoundManagerSyrinscape.getGlobalVolume();
		local sURLPart = string.format("global-volume/%.2f", nVolume / 100);
		Interface.openURL(SoundManagerSyrinscape.getURLWithAuthToken(sURLPart), nil);
	end
end
function postOneShotVolume(bShowError)
	if SoundManagerSyrinscape.checkAuthToken(bShowError) then
		local nVolume = SoundManagerSyrinscape.getOneShotVolume();
		local sURLPart = string.format("global-oneshot-volume/%.2f", nVolume / 100);
		Interface.openURL(SoundManagerSyrinscape.getURLWithAuthToken(sURLPart), nil);
	end
end

--
--	URL SUPPORT
--

local URL_CONTROLPANEL = "https://syrinscape.com/online/cp/";
local URL_ACCOUNT = "https://syrinscape.com/account/remote-control-links-csv/";

local URL_PART_SERVER = "https://syrinscape.com/online/frontend-api/";
local URL_PART_SERVER_APP = "https://app.syrinscape.com/";

local URL_PART_FORMAT_JSON = "?format=json";
local URL_PART_AUTH = "?auth_token=";

function getURLWithAuthToken(sPath)
	return SoundManagerSyrinscape.helperURLAppendAuthToken(URL_PART_SERVER .. sPath);
end

function getControlPanelURL()
	return URL_CONTROLPANEL;
end
function getWebImportURL()
	return SoundManagerSyrinscape.helperURLAppendAuthToken(URL_ACCOUNT);
end
function getSessionGenerateURL()
	return SoundManagerSyrinscape.helperURLAppendAuthToken(URL_PART_SERVER_APP .. "new/" .. URL_PART_FORMAT_JSON .. "&");
end
function getSessionGMURL(sSessionID)
	return URL_PART_SERVER_APP .. sSessionID .. "/gm/";
end
function getSessionPlayerURL(sSessionID)
	return URL_PART_SERVER_APP .. sSessionID .. "/player/";
end

function helperURLAppendAuthToken(sURL)
	return sURL .. URL_PART_AUTH .. SoundManagerSyrinscape.getAuthorizationToken();
end

--
--	PLAYER SESSION MANAGEMENT
--

function sendPlayerInvite()
	if not Session.IsHost then
		return;
	end

	local sID = SoundManagerSyrinscape.getSession();
	if sID == "" then
		ChatManager.SystemMessage(Interface.getString("sound_error_ss_session_missing"));
		return;
	end

	local sGMLink = SoundManagerSyrinscape.getSessionGMURL(sID);
	local msgGM = { secret = true, font = "systemfont" };
	msgGM.shortcuts = { { class = "url", recordname = sGMLink } };
	msgGM.text = Interface.getString("sound_message_ss_session_gm");
	Comm.addChatMessage(msgGM);

	local sPlayerLink = SoundManagerSyrinscape.getSessionPlayerURL(sID);
	local msgPlayer = { icon = "portrait_gm_token", font = "systemfont" };
	msgPlayer.shortcuts = { { class = "url", recordname = sPlayerLink } };
	msgPlayer.text = Interface.getString("sound_message_ss_session_player");
	Comm.deliverChatMessage(msgPlayer);
end

function generateSessionID()
	if not Session.IsHost then
		return;
	end
	if not SoundManagerSyrinscape.checkAuthToken(true) then
		return;
	end

	Interface.openURL(SoundManagerSyrinscape.getSessionGenerateURL(), SoundManagerSyrinscape.onSessionGenerated);
	ChatManager.SystemMessage(Interface.getString("sound_message_ss_session_generate"));
end
function onSessionGenerated(_, sResponse)
	if not sResponse then
		ChatManager.SystemMessage(Interface.getString("sound_error_ss_session_generate"));
		return;
	end

	local tResponse = Utility.decodeJSON(sResponse);
	SoundManagerSyrinscape.setSession(tostring(tResponse.session_id));
	ChatManager.SystemMessage(Interface.getString("sound_message_ss_session_generate_success"));
end

--
--	MISC
--

function openWebControlPanel()
	if not Session.IsHost then
		return;
	end
	Interface.openWindow("url", SoundManagerSyrinscape.getControlPanelURL());
end

function loadAuthorizationToken()
	if not Session.IsHost then
		return "";
	end
	if not GlobalRegistry then
		return "";
	end
	if not GlobalRegistry.sound or not GlobalRegistry.sound.ss then
		return "";
	end
	return GlobalRegistry.sound.ss.authtoken or "";
end
function saveAuthorizationToken(s)
	if not Session.IsHost then
		return;
	end
	if not GlobalRegistry then
		return;
	end
	if not GlobalRegistry.sound then
		GlobalRegistry.sound = {};
	end
	if not GlobalRegistry.sound.ss then
		GlobalRegistry.sound.ss = {};
	end
	GlobalRegistry.sound.ss.authtoken = s;
end
function getAuthorizationToken()
	if not Session.IsHost then
		return "";
	end
	return DB.getValue(SoundManagerSyrinscape.PATH_AUTHTOKEN, "");
end
function setAuthorizationToken(s)
	if not Session.IsHost then
		return;
	end
	DB.setValue(SoundManagerSyrinscape.PATH_AUTHTOKEN, "string", s);
end
function checkAuthToken(bShowErrors)
	local sAuthToken = SoundManagerSyrinscape.getAuthorizationToken();
	if sAuthToken == "" then
		if bShowErrors then
			ChatManager.SystemMessage(Interface.getString("sound_error_ss_authtoken_missing"));
		end
		return false;
	end
	return true;
end

function loadSession()
	if not Session.IsHost then
		return "";
	end
	if not GlobalRegistry then
		return "";
	end
	if not GlobalRegistry.sound or not GlobalRegistry.sound.ss then
		return "";
	end
	if GlobalRegistry.sound.ss.sessionid then
		return GlobalRegistry.sound.ss.sessionid;
	-- Retrieve and clean up old format
	elseif GlobalRegistry.sound.ss.playersession then
		-- Ex: "https://app.syrinscape.com/8bfc3aa713e944e8badf24bc49007ffc/"
		local sID = GlobalRegistry.sound.ss.playersession:match("/(%x+)/$");
		GlobalRegistry.sound.ss.playersession = nil;
		return sID;
	end
	return "";
end
function saveSession(s)
	if not Session.IsHost then
		return;
	end
	if not GlobalRegistry then
		return;
	end
	if not GlobalRegistry.sound then
		GlobalRegistry.sound = {};
	end
	if not GlobalRegistry.sound.ss then
		GlobalRegistry.sound.ss = {};
	end
	GlobalRegistry.sound.ss.sessionid = s;
end
function getSession()
	if not Session.IsHost then
		return "";
	end
	return DB.getValue(SoundManagerSyrinscape.PATH_SESSION, "");
end
function setSession(s)
	if not Session.IsHost then
		return "";
	end
	return DB.setValue(SoundManagerSyrinscape.PATH_SESSION, "string", s);
end
function checkSession()
	local sSession = SoundManagerSyrinscape.getSession();
	if sSession == "" then
		return false;
	end
	return true;
end
