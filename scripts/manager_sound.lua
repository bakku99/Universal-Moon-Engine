--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

function onInit()
	OptionsManager.registerOptionData({
		sKey = "SOUND", sGroupRes = "option_header_game", sType = "option_entry_checkbox_and_button",
		tCustom = { values = "on", baseval = "off", default = "on", buttonclass = "sound_settings", buttonlabelres = "sound_button_settings", },
	});
end
function onTabletopInit()
	if Session.IsHost then
		Interface.addKeyedEventHandler("onLinkActivate", "soundplay", SoundManager.handlerSoundPlay);
		Interface.addKeyedEventHandler("onLinkActivate", "soundstop", SoundManager.handlerSoundStop);
		Interface.addKeyedEventHandler("onLinkActivate", "soundstopall", SoundManager.handlerSoundStopAll);
		ChatManager.registerDropCallback("shortcut", SoundManager.onChatDrop);

		SoundManager.onOptionChanged();
		OptionsManager.registerCallback("SOUND", SoundManager.onOptionChanged);
	end
end

function isEnabled()
	return OptionsManager.isOption("SOUND", "on");
end
function onOptionChanged()
	if not Session.IsHost then
		return;
	end

	if SoundManager.isEnabled() then
		DesktopManager.registerSidebarToolButton({ class = "sound_context", sInsertBefore = "options", });
		RecordDataManager.setHidden("soundset", false);
	else
		DesktopManager.removeSidebarToolButton("sound_context");
		RecordDataManager.setHidden("soundset", true);
	end
end

--
--	SOUND SYSTEM HANDLING
--

local _tSoundSystems = {};
function registerSoundSystem(sKey, tData)
	if sKey then
		_tSoundSystems[sKey] = tData;
	end
end
function getSoundSystems()
	return _tSoundSystems;
end
function getSoundSystemKeys()
	local tKeys = {};
	for k,_ in pairs(SoundManager.getSoundSystems()) do
		table.insert(tKeys, k);
	end
	return tKeys;
end
function getSoundSystemByKey(sKey)
	return _tSoundSystems[sKey];
end
function hasSoundSystemFunctionByID(sFunction, sSoundID)
	local sKey = sSoundID:match("^(%w+)|");
	if sKey then
		local tData = SoundManager.getSoundSystemByKey(sKey);
		if tData and tData.script then
			if tData.script[sFunction] then
				return true;
			end
		end
	end
	return false;
end
function callSoundSystemByID(sFunction, sSoundID, ...)
	local sKey = sSoundID:match("^(%w+)|");
	if sKey then
		local tData = SoundManager.getSoundSystemByKey(sKey);
		if tData and tData.script then
			if tData.script[sFunction] then
				return tData.script[sFunction](sSoundID, ...);
			end
		end
	end
	return nil;
end
function callForAllSoundSystems(sFunction, ...)
	for _,tData in pairs(SoundManager.getSoundSystems()) do
		if tData.script and tData.script[sFunction] then
			tData.script[sFunction](...);
		end
	end
end

--
--	HANDLERS
--

function handlerSoundPlay(_, sPath)
	SoundManager.playSound(sPath);
	return true;
end
function handlerSoundStop(_, sPath)
	SoundManager.stopSound(sPath);
	return true;
end
function handlerSoundStopAll()
	SoundManager.stopAll();
	return true;
end
function onChatDrop(draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sPath = draginfo.getShortcutData();
		if sClass == "soundplay" then
			SoundManager.playSound(sPath);
			return true;
		elseif sClass == "soundstop" then
			SoundManager.stopSound(sPath);
			return true;
		end
	end
end

--
--	UI FUNCTIONS
--

function getSettingsWindow()
	return Interface.findWindow("sound_settings", "");
end
function openSettingsWindow()
	if not Session.IsHost then
		return;
	end
	Interface.openWindow("sound_settings", "");
end
function populateSettingsWindow(wSettings)
	local tKeys = SoundManager.getSoundSystemKeys();
	if #tKeys > 0 then
		for _,sKey in ipairs(tKeys) do
			local wSystem = wSettings.sub_systems.subwindow.list.createWindow();
			wSystem.setData(sKey);
		end
		SoundManager.onSettingsSystemButtonPressed(tKeys[1], wSettings);
	end
end
function onSettingsSystemButtonPressed(sKey, wSettings)
	if not wSettings then
		wSettings = SoundManager.getSettingsWindow();
	end
	if wSettings then
		for _,wSystem in ipairs(wSettings.sub_systems.subwindow.list.getWindows()) do
			if wSystem.getKey() == sKey then
				wSystem.button.setValue(1);
			else
				wSystem.button.setValue(0);
			end
		end
		wSettings.sub_manage.setValue("sound_settings_manage_" .. sKey, "");
		wSettings.sub_filter.setValue("sound_settings_filter_" .. sKey, "");
		wSettings.sub_content.setValue("sound_settings_content_" .. sKey, "");
	end
end
function refreshSettingsFilter(wSettings)
	if not wSettings then
		wSettings = SoundManager.getSettingsWindow();
	end
	if wSettings then
		if wSettings.sub_filter.subwindow and wSettings.sub_filter.subwindow.refresh then
			SoundManager.setFilterUpdate(false);
			wSettings.sub_filter.subwindow.refresh();
			SoundManager.setFilterUpdate(true);
		end
	end
end
function setFilterNameControl(s)
	local wSettings = SoundManager.getSettingsWindow();
	if wSettings then
		if wSettings.sub_filter.subwindow and wSettings.sub_filter.subwindow.setFilterNameControl then
			SoundManager.setFilterUpdate(false);
			wSettings.sub_filter.subwindow.setFilterNameControl(s);
			SoundManager.setFilterUpdate(true);
		end
		SoundManager.refreshSettingsContent();
	end
end
local _bFilterUpdate = true;
function setFilterUpdate(bValue)
	_bFilterUpdate = bValue;
end
function getFilterUpdate()
	return _bFilterUpdate;
end
function refreshSettingsContent()
	local wSettings = SoundManager.getSettingsWindow();
	if wSettings then
		if wSettings.sub_content.subwindow and wSettings.sub_content.subwindow.refresh then
			wSettings.sub_content.subwindow.refresh();
		end
	end
end

function getContextWindow()
	return Interface.findWindow("sound_context", "");
end
function populateContextWindow(wContext)
	SoundManagerSyrinscape.updateVolumeDisplay(wContext);
	SoundManager.refreshNowPlaying(wContext);
	SoundsetManager.populateContextWindow(wContext);
end
function refreshNowPlaying(wContext)
	if not wContext then
		wContext = SoundManager.getContextWindow();
	end
	if wContext then
		wContext.sub_nowplaying.subwindow.list.closeAll();

		local tData = {};
		SoundManager.callForAllSoundSystems("getNowPlaying", tData);
		if #tData > 0 then
			for _,v in ipairs(tData) do
				local wChild = wContext.sub_nowplaying.subwindow.list.createWindow();
				wChild.setData(v);
			end
			wContext.sub_nowplaying.setVisible(true);
		else
			wContext.sub_nowplaying.setVisible(false);
		end
	end
end

function performPlay(w, draginfo)
	if not Session.IsHost then
		return;
	end

	if draginfo then
		draginfo.setType("shortcut");
		draginfo.setIcon("sound_play");
		draginfo.setShortcutData("soundplay", w.soundid.getValue());
		draginfo.setDescription(string.format("Sound - %s", w.name.getValue()));
		return true;
	end

	SoundManager.playSound(w.soundid.getValue());
end
function performStop(w, draginfo)
	if not Session.IsHost then
		return;
	end

	if draginfo then
		draginfo.setType("shortcut");
		draginfo.setIcon("sound_stop");
		draginfo.setShortcutData("soundstop", w.soundid.getValue());
		draginfo.setDescription(string.format("Sound - %s", w.name.getValue()));
		return true;
	end

	SoundManager.stopSound(w.soundid.getValue());
end
function performStopAll(draginfo)
	if not Session.IsHost then
		return;
	end

	if draginfo then
		draginfo.setType("shortcut");
		draginfo.setIcon("sound_stop");
		draginfo.setShortcutData("soundstopall", "");
		draginfo.setDescription("Sound - Stop All");
		return true;
	end

	SoundManager.stopAll();
end

--
--	CORE FUNCTIONS
--

function parseSoundID(sSoundID, bShowError)
	local tSound = SoundManager.callSoundSystemByID("parseSoundID", sSoundID);
	if not tSound and bShowError then
		ChatManager.SystemMessage(string.format("%s (%s)", Interface.getString("sound_error_link"), sSoundID));
	end
	return tSound;
end
function playSound(sSoundID)
	if not Session.IsHost then
		return;
	end
	if not SoundManager.isEnabled() then
		ChatManager.SystemMessage(Interface.getString("sound_error_disabled"));
		return;
	end
	SoundManager.callSoundSystemByID("playSound", sSoundID);
end
function stopSound(sSoundID)
	if not Session.IsHost then
		return;
	end
	SoundManager.callSoundSystemByID("stopSound", sSoundID);
end
function stopAll()
	if not Session.IsHost then
		return;
	end
	SoundManager.callForAllSoundSystems("stopAll");
end
