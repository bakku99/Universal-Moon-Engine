--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

DEFAULT_USER_COLOR = "FF000000";
DEFAULT_DICE_BODY_COLOR = "FF000000";
DEFAULT_DICE_TEXT_COLOR = "FFFFFFFF";

local _tUserColor;

function onInit()
	UserManager.setColorsFromCharID("");
end
function onTabletopInit()
	if not Session.IsHost then
		User.addEventHandler("onIdentityStateChange", UserManager.onUserIdentityStateChange);
	end
	Interface.addKeyedEventHandler("onHotkeyActivated", "diceskin", UserManager.onDiceSkinHotKeyActivate);
	ChatManager.registerDropCallback("diceskin", UserManager.onDiceSkinChatDrop);
end
function onTabletopClose()
	UserManager.saveIdentityState();
end

function onUserIdentityStateChange(sIdentity, sUser, sKey, sValue)
	if (sUser == Session.UserName) and (sKey == "current") then
		if sValue then
			UserManager.setColorsFromCharID(sIdentity);
		else
			UserManager.setColorsFromCharID("");
		end
	end
end
function onDiceSkinHotKeyActivate(draginfo)
	UserManager.helperDragInfoActivate(draginfo);
end
function onDiceSkinChatDrop(draginfo)
	UserManager.helperDragInfoActivate(draginfo);
	return true;
end
function helperDragInfoActivate(draginfo)
	local tDiceSkin = UserManager.convertDiceSkinStringToTable(draginfo.getStringData());
	UserManager.setDiceSkinTable(tDiceSkin);
end

function convertDiceSkinStringToTable(s)
	if not s then
		return nil;
	end

	local tColor = {};
	local tDataSplit = StringManager.split(s, "|");
	tColor.diceskin = tonumber(tDataSplit[1]) or 0;
	if DiceSkinManager.isDiceSkinTintable(_tUserColor) then
		tColor.dicebodycolor = tDataSplit[2] or UserManager.DEFAULT_DICE_BODY_COLOR;
		tColor.dicetextcolor = tDataSplit[3] or UserManager.DEFAULT_DICE_TEXT_COLOR;
	end
	return tColor;
end

--
--	CHARACTER ID MANAGEMENT
--

function loadIdentityState()
	if Session.IsHost then
		return;
	end

	local bCharFound = false;
	if CampaignRegistry then
		for _,sCharID in ipairs(CampaignRegistry.identitystate or {}) do
			bCharFound = true;
			UserManager.requestIdentity(sCharID);
		end
	end

	if not bCharFound then
		Interface.openWindow("charselect_client", "");
	end
end
function saveIdentityState()
	if Session.IsHost then
		return;
	end

	if not CampaignRegistry then
		return;
	end

	CampaignRegistry.identitystate = {};
	for _,sCharID in ipairs(User.getActiveIdentities()) do
		table.insert(CampaignRegistry.identitystate, sCharID);
	end
end

-- tData = {
-- 	nodeLocal = ...,
-- 	fnResponse = ...,
-- }
function requestIdentity(sCharID, tData)
	if Session.IsHost then
		return;
	end

	User.requestIdentity(sCharID, nil, nil, tData and tData.nodeLocal, tData and tData.fnResponse or UserManager.defaultIdentityRequestResponse);
end
function defaultIdentityRequestResponse()
	-- Do Nothing
end
function releaseIdentityPath(sPath)
	UserManager.releaseIdentity(CharacterListManager.convertPathToIdentity(sPath));
end
function releaseIdentity(sCharID)
	if Session.IsHost then
		return;
	end
	if (sCharID or "") == "" then
		return;
	end

	User.releaseIdentity(sCharID);
end
function activatePlayerID(sCharID)
	if Session.IsHost then
		return;
	end

	User.setCurrentIdentity(sCharID);
	UserManager.setColorsFromCharID(sCharID);
end

function getColorsFromCurrentID()
	return UserManager.getColorsFromCharIDRegistry(User.getCurrentIdentity());
end
function setColorsFromCharID(sCharID)
	local tColor = UserManager.getColorsFromCharIDRegistry(sCharID);
	User.setCurrentIdentityColors(tColor.color);
	User.setCurrentIdentityDiceColors(tColor.dicebodycolor, tColor.dicetextcolor, tColor.diceskin);
	UserManager.refreshColor();
end
function setColorsToCurrentID(tColor)
	UserManager.setColorsToCharIDRegistry(User.getCurrentIdentity(), tColor);

	User.setCurrentIdentityColors(tColor.color or UserManager.DEFAULT_DICE_BODY_COLOR);
	User.setCurrentIdentityDiceColors(tColor.dicebodycolor or UserManager.DEFAULT_DICE_BODY_COLOR, tColor.dicetextcolor or UserManager.DEFAULT_DICE_TEXT_COLOR, tColor.diceskin or 0);
end

--
--	CHARACTER ID REGISTRY
--

function getColorsFromCharIDRegistry(sCharID)
	sCharID = sCharID or "";

	local tResult = {};
	if CampaignRegistry.colortables then
		local t = CampaignRegistry.colortables[sCharID];
		if t then
			tResult.color = t.color;
			tResult.dicebodycolor = t.dicebodycolor;
			tResult.dicetextcolor = t.dicetextcolor;
			tResult.diceskin = t.diceskin;
		end
	end
	if not tResult.color then
		tResult.color = UserManager.DEFAULT_USER_COLOR;
	end
	if not tResult.dicebodycolor then
		tResult.dicebodycolor = UserManager.DEFAULT_DICE_BODY_COLOR;
	end
	if not tResult.dicetextcolor then
		tResult.dicetextcolor = UserManager.DEFAULT_DICE_TEXT_COLOR;
	end
	if not tResult.diceskin then
		tResult.diceskin = 0;
	end
	return tResult;
end
function setColorsToCharIDRegistry(sCharID, tParam)
	sCharID = sCharID or "";
	CampaignRegistry.colortables = CampaignRegistry.colortables or {};
	CampaignRegistry.colortables[sCharID] = CampaignRegistry.colortables[sCharID] or {};

	local t = CampaignRegistry.colortables[sCharID];
	t.color = tParam.color;
	t.dicebodycolor = tParam.dicebodycolor;
	t.dicetextcolor = tParam.dicetextcolor;
	t.diceskin = tParam.diceskin;
end

--
--	USER COLOR HANDLING
--

local _tColorCallbacks = {};
function registerColorCallback(fn)
	UtilityManager.registerCallback(_tColorCallbacks, fn);
end
function unregisterColorCallback(fn)
	UtilityManager.unregisterCallback(_tColorCallbacks, fn);
end
function onColorChanged()
	UtilityManager.performAllCallbacks(_tColorCallbacks);
end

function refreshColor()
	_tUserColor = UserManager.getColorsFromCurrentID();
	UserManager.onColorChanged();
end
function getColor()
	return _tUserColor;
end
function getIdentityColor()
	return _tUserColor.color;
end
function setIdentityColor(sColor)
	_tUserColor.color = sColor;
	UserManager.setColorsToCurrentID(_tUserColor);
	UserManager.onColorChanged();
end
function getDiceBodyColor()
	return _tUserColor.dicebodycolor;
end
function setDiceBodyColor(sColor)
	_tUserColor.dicebodycolor = sColor;
	UserManager.setColorsToCurrentID(_tUserColor);
	UserManager.onColorChanged();
end
function getDiceTextColor()
	return _tUserColor.dicetextcolor;
end
function setDiceTextColor(sColor)
	_tUserColor.dicetextcolor = sColor;
	UserManager.setColorsToCurrentID(_tUserColor);
	UserManager.onColorChanged();
end
function getDiceSkin()
	return _tUserColor.diceskin;
end
function setDiceSkin(nID)
	_tUserColor.diceskin = nID;
	UserManager.setColorsToCurrentID(_tUserColor);
	UserManager.onColorChanged();
end
function setDiceSkinTable(tDiceSkin)
	_tUserColor.dicebodycolor = tDiceSkin.dicebodycolor;
	_tUserColor.dicetextcolor = tDiceSkin.dicetextcolor;
	_tUserColor.diceskin = tDiceSkin.diceskin;
	UserManager.setColorsToCurrentID(_tUserColor);
	UserManager.onColorChanged();
end
