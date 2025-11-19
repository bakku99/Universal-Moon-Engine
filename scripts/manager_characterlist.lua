--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

PORTRAIT_SIZE = 100;
PORTRAIT_PADDING_W = 5;
LEFT_MARGIN = 10;
RIGHT_MARGIN = 10;
TOP_MARGIN = 10;
BOTTOM_MARGIN = 10;

CHARLIST_NAME_WIDGET_POSITION = "bottom";
CHARLIST_NAME_WIDGET_X = 0;
CHARLIST_NAME_WIDGET_Y = -12;
CHARLIST_NAME_WIDGET_W = 90;
CHARLIST_NAME_WIDGET_FONT = "mini_name";
CHARLIST_NAME_WIDGET_FONT_CURRENT = "mini_name_selected";
CHARLIST_NAME_WIDGET_FRAME = "mini_name";
CHARLIST_NAME_WIDGET_FRAME_OFFSET = "5,2,5,2";

CHARLIST_COLOR_WIDGET_POSITION = "topleft";
CHARLIST_COLOR_WIDGET_X = 10;
CHARLIST_COLOR_WIDGET_Y = 10;
CHARLIST_COLOR_WIDGET_W = 20;
CHARLIST_COLOR_WIDGET_H = 20;

CHARLIST_STATE_WIDGET_POSITION = "topleft";
CHARLIST_STATE_WIDGET_X = 23;
CHARLIST_STATE_WIDGET_Y = 22;

OOB_MSGTYPE_SETAFK = "setafk";

-- Structure for desktop list
--{
--	sUser = ..., (user/identity)
--	sPath = ..., (party/identity)
--	sName = ..., (party/identity)
--	bCurrent = ..., (identity)
--	sColor = ..., (identity)
--}

function onInit()
	CharacterListManager.addStandardDropSupport();
	CharacterListManager.addStandardAFKSupport();
	OptionsManager.registerCallback("CLSH", CharacterListManager.onOptionChanged);
end
function onTabletopInit()
	CharacterListManager.refreshParty();
	CharacterListManager.addUserHandlers();
	CharacterListManager.addPartyHandlers();
end

function addStandardDropSupport()
	if Session.IsHost then
		CharacterListManager.registerDropHandler("number", CharacterListManager.onNumberDrop)
	end
	CharacterListManager.registerDropHandler("string", CharacterListManager.onStringDrop)
	CharacterListManager.registerDropHandler("shortcut", CharacterListManager.onShortcutDrop)
	if Session.IsHost then
		CharacterListManager.registerDropHandler("", CharacterListManager.onDefaultDrop);
	end
end
function addStandardAFKSupport()
	if not Session.IsHost then
		Comm.registerSlashHandler("afk", CharacterListManager.processAFK);
	end
	OOBManager.registerOOBMsgHandler(CharacterListManager.OOB_MSGTYPE_SETAFK, CharacterListManager.handleAFK);
end

function onOptionChanged()
	CharacterListManager.refreshDisplayList();
end

function convertIdentityToPath(sIdentity)
	if (sIdentity or "") == "" then
		return nil;
	end
	return "charsheet." .. sIdentity;
end
function convertPathToIdentity(sPath)
	if (sPath or "") == "" then
		return nil;
	end

	return (sPath:match("^charsheet%.([^.]+)$"));
end

--
--	DISPLAY MANAGEMENT
--

local _wCharList = nil;
function registerWindow(w)
	_wCharList = w;
	if w then
		w.anchor.setStaticBounds(CharacterListManager.LEFT_MARGIN - CharacterListManager.PORTRAIT_PADDING_W, CharacterListManager.TOP_MARGIN, 0, 0);
		CharacterListManager.refreshDisplayList();
	else
		CharacterListManager.clearDisplayList();
	end
end
function getWindow()
	return _wCharList;
end

local _bDoingWindowResize = false;
function resizeWindow()
	local w = CharacterListManager.getWindow();
	if not w then
		return;
	end

	if _bDoingWindowResize then
		return;
	end
	_bDoingWindowResize = true;
	local nListW = CharacterListManager.LEFT_MARGIN + CharacterListManager.RIGHT_MARGIN;
	local nListH = CharacterListManager.TOP_MARGIN + CharacterListManager.PORTRAIT_SIZE + CharacterListManager.BOTTOM_MARGIN;
	local nCount = CharacterListManager.getDisplayListCount();
	if nCount > 0 then
		nListW = nListW + (nCount * CharacterListManager.PORTRAIT_SIZE) + ((nCount - 1) * CharacterListManager.PORTRAIT_PADDING_W);
	end
	WindowManager.callOuterWindowFunction(w, "onContentSizeChanged", nListW, nListH);
	_bDoingWindowResize = false;
end

local _sCharEntryClass = "characterlist_entry"
function setEntryClass(sWindowClass)
	_sCharEntryClass = sWindowClass
end
function getEntryClass()
	return _sCharEntryClass;
end

local _tCharEntryDecorators = {};
function setDecorator(sName, fn)
	if (sName or "") == "" then
		return;
	end
	_tCharEntryDecorators[sName] = fn;
end
function getDecorators()
	return _tCharEntryDecorators;
end

local _tDisplayList = {};
function getDisplayList()
	return _tDisplayList;
end
function clearDisplayList()
	_tDisplayList = {};
end
function getDisplayListCount()
	return #(_tDisplayList);
end
function getDisplayControlByPath(sPath)
	if (sPath or "") == "" then
		return nil;
	end
	for _,c in ipairs(CharacterListManager.getDisplayList()) do
		local t = c.getData();
		if t and t.sPath and (t.sPath == sPath) then
			return c;
		end
	end
	return nil;
end
function getDisplayControlByUser(sUser)
	if (sUser or "") == "" then
		return nil;
	end
	-- NOTE: Only return user controls that do not have a path; those are handled separately
	for _,c in ipairs(CharacterListManager.getDisplayList()) do
		local t = c.getData();
		if t and not t.sPath and t.sUser and (t.sUser == sUser) then
			return c;
		end
	end
	return nil;
end

function refreshDisplayList()
	local w = CharacterListManager.getWindow();
	if not w then
		return;
	end

	-- Build current list of actors/users
	local tCurrDisplayPaths = {};
	local tCurrDisplayUsers = {};
	for _,v in ipairs(CharacterListManager.getDisplayList()) do
		local t = v.getData();
		if t then
			if ((t.sPath or "") ~= "") then
				tCurrDisplayPaths[t.sPath] = t;
			elseif ((t.sUser or "") ~= "") then
				tCurrDisplayUsers[t.sUser] = t;
			end
		end
	end

	-- Build new list of actors/users
	local tNewDisplayPaths = {};
	local tNewDisplayActiveUsers = {};
	for k,v in pairs(CharacterListManager.getActivatedIdentities()) do
		tNewDisplayPaths[k] = v;
		tNewDisplayActiveUsers[v.sUser] = true;
	end
	if OptionsManager.isOption("CLSH", "all") then
		for k,v in pairs(CharacterListManager.getPartyIdentities()) do
			if not tNewDisplayPaths[k] then
				tNewDisplayPaths[k] = v;
			end
		end
	end

	-- Adjust display list for actors
	for k,v in pairs(tNewDisplayPaths) do
		if not tCurrDisplayPaths[k] then
			CharacterListManager.createEntry(w, v);
		end
	end
	for k,_ in pairs(tCurrDisplayPaths) do
		local c = CharacterListManager.getDisplayControlByPath(k);
		if c then
			if not tNewDisplayPaths[k] then
				CharacterListManager.destroyEntry(w, c);
			else
				c.updateData(tNewDisplayPaths[k]);
			end
		end
	end

	-- Adjust display list for users without actors
	local tActiveUsers = CharacterListManager.getActiveUsers();
	for k,_ in pairs(tCurrDisplayUsers) do
		if not tActiveUsers[k] or tNewDisplayActiveUsers[k] then
			CharacterListManager.destroyEntry(w, CharacterListManager.getDisplayControlByUser(k));
		end
	end
	for k,v in pairs(tActiveUsers) do
		if not tCurrDisplayUsers[k] and not tNewDisplayActiveUsers[k] then
			CharacterListManager.createEntry(w, v);
		end
	end

	-- Sort and layout display list
	table.sort(CharacterListManager.getDisplayList(), CharacterListManager.defaultSortFunc);
	for _,v in ipairs(CharacterListManager.getDisplayList()) do
		v.sendToBack();
	end
	w.anchor.sendToBack();
	CharacterListManager.resizeWindow();
end
function createEntry(w, tData)
	local c = w.createControl(CharacterListManager.getEntryClass());
	table.insert(CharacterListManager.getDisplayList(), c);

	c.setAnchor("top", nil, "top", "absolute", CharacterListManager.TOP_MARGIN);
	c.setAnchor("left", "anchor", "right", "relative", CharacterListManager.PORTRAIT_PADDING_W);
	c.setAnchoredWidth(CharacterListManager.PORTRAIT_SIZE);
	c.setAnchoredHeight(CharacterListManager.PORTRAIT_SIZE);

	c.initData(tData);
end
function destroyEntry(_, c)
	if not c then
		return;
	end
	local tList = CharacterListManager.getDisplayList();
	for k,v in ipairs(tList) do
		if c == v then
			table.remove(tList, k);
			break;
		end
	end
	c.destroy();
end
function defaultSortFunc(c1, c2)
	local t1 = c1.getData();
	local t2 = c2.getData();

	if not t1.sPath or not t2.sPath then
		if t1.sPath then
			return false;
		elseif t2.sPath then
			return true;
		else
			return (t1.sUser or "") > (t2.sUser or "");
		end
	end

	local sName1 = t1.sName or "";
	local sName2 = t2.sName or "";
	if sName1 ~= sName2 then
		return sName1 > sName2;
	end

	return (t1.sPath or "") > (t2.sPath or "");
end

--
--	USER/IDENTITY DATA HANDLING
--

function addUserHandlers()
	User.addEventHandler("onLogin", CharacterListManager.onUserLogin);
	User.addEventHandler("onUserStateChange", CharacterListManager.onUserStateChange);
	User.addEventHandler("onIdentityActivation", CharacterListManager.onIdentityActivation);
	User.addEventHandler("onIdentityStateChange", CharacterListManager.onIdentityStateChange);

	if not Session.IsHost then
		CharacterListManager.setActiveUser(Session.UserName, true);
	end
end
function onUserLogin(sUser, bActivated)
	CharacterListManager.setActiveUser(sUser, bActivated);
end
function onUserStateChange(sUser, sState)
	CharacterListManager.setUserState(sUser, sState);
end
function onIdentityActivation(sIdentity, sUser, bActivated)
	CharacterListManager.setActivatedIdentity(sIdentity, sUser, bActivated);
end
function onIdentityStateChange(sIdentity, sUser, sState, vState)
	CharacterListManager.setActivatedIdentityData(sIdentity, sUser, sState, vState);
end

local _tActiveUsers = {};
function getActiveUsers()
	return _tActiveUsers;
end
function setActiveUser(sUser, bActivated)
	if (sUser or "") == "" then
		return;
	end

	if bActivated then
		_tActiveUsers[sUser] = _tActiveUsers[sUser] or { sUser = sUser };
		_tActiveUsers[sUser].sState = "active";
	else
		_tActiveUsers[sUser] = nil;
	end

	CharacterListManager.refreshDisplayList();
end
function setUserState(sUser, sState)
	if (sUser or "") == "" then
		return false;
	end

	local t = _tActiveUsers[sUser];
	if not t then
		CharacterListManager.setActiveUser(sUser, true);
		t = _tActiveUsers[sUser];
		if not t then
			return false;
		end
	end

	if (sState == "typing") or (sState == "active") then
		if (t.sState == "afk") and (sUser == Session.UserName) then
			t.sState = sState;
			CharacterListManager.messageAFK(sUser);
		else
			t.sState = sState;
		end
	else
		if t.sState ~= "afk" then
			t.sState = sState;
		end
	end

	local c = CharacterListManager.getDisplayControlByPath(CharacterListManager.convertIdentityToPath(User.getCurrentIdentity(sUser)));
	if c then
		c.setActiveState(t.sState);
	end
	return true;
end
function getUserState(sUser)
	if (sUser or "") == "" then
		return nil;
	end

	local t = _tActiveUsers[sUser];
	if not t then
		return nil;
	end
	return t.sState;
end

-- NOTE: Uses full database paths as key
local _tActivatedIdentities = {};
function getActivatedIdentities()
	return _tActivatedIdentities;
end
function getActivatedIdentity(sPath)
	if (sPath or "") == "" then
		return;
	end
	return _tActivatedIdentities[sPath];
end
function setActivatedIdentity(sIdentity, sUser, bActivated)
	if (sIdentity or "") == "" then
		return;
	end

	local sPath = CharacterListManager.convertIdentityToPath(sIdentity);
	if bActivated then
		_tActivatedIdentities[sPath] = { sUser = sUser, sPath = sPath };
	else
		_tActivatedIdentities[sPath] = nil;
	end

	CharacterListManager.refreshDisplayList();

	-- If player, show/hide character sheet depending on activation state
	if not Session.IsHost then
		if not bActivated then
			local w = Interface.findWindow("charsheet", sPath);
			if w then
				w.close();
			end
		end
	end
end
function setActivatedIdentityData(sIdentity, _, sState, vState)
	if (sIdentity or "") == "" then
		return;
	end

	local sPath = CharacterListManager.convertIdentityToPath(sIdentity);
	local t = CharacterListManager.getActivatedIdentity(sPath);
	if not t then
		return;
	end

	if sState == "current" then
		t.bCurrent = vState;
	elseif sState == "label" then
		t.sName = vState;
	elseif sState == "color" then
		t.sColor = User.getIdentityColor(sIdentity);
	end

	if sState == "label" then
		CharacterListManager.refreshDisplayList();
	else
		local c = CharacterListManager.getDisplayControlByPath(sPath);
		if c then
			c.updateData(t);
		end
	end
end

--
--	PARTY DATA HANDLING
--

function addPartyHandlers()
	DB.addHandler(PartyManager.PS_LIST, "onChildDeleted", CharacterListManager.refreshParty);
	DB.addHandler(PartyManager.PS_LIST .. ".*.link", "onUpdate", CharacterListManager.refreshParty);
	DB.addHandler(PartyManager.PS_LIST .. ".*.name", "onUpdate", CharacterListManager.refreshParty);
end

function refreshParty()
	CharacterListManager.rebuildPartyIdentities();
	CharacterListManager.refreshDisplayList();
end

local _tPartyIdentities = {};
function getPartyIdentities()
	return _tPartyIdentities;
end
function rebuildPartyIdentities()
	_tPartyIdentities = {};
	for _,v in ipairs(PartyManager.getPartyNodes()) do
		local _,sRecord = DB.getValue(v, "link", "", "");
		if (sRecord or "") ~= "" then
			_tPartyIdentities[sRecord] = { sPath = sRecord, sName = DB.getValue(v, "name", "") };
		end
	end
end

--
--	DROP HANDLING
--

local _tDropHandlers = {};
function registerDropHandler(sDropType, fHandler)
	_tDropHandlers[sDropType] = fHandler;
end
function unregisterDropHandler(sDropType)
	_tDropHandlers[sDropType] = nil;
end
function processDrop(tData, draginfo)
	local sDropType = draginfo.getType();
	if _tDropHandlers[sDropType] then
		return _tDropHandlers[sDropType](tData, draginfo);
	end
	if _tDropHandlers[""] then
		return _tDropHandlers[""](tData, draginfo);
	end
	return nil;
end

function onNumberDrop(tData, draginfo)
	if tData and (tData.sUser or "") ~= "" then
		local msg = {};
		msg.text = draginfo.getDescription();
		msg.font = "systemfont";
		msg.icon = "";
		msg.dice = {};
		msg.diemodifier = draginfo.getNumberData();
		msg.secret = false;

		Comm.deliverChatMessage(msg, tData.sUser);
		return true
	end
end
function onStringDrop(tData, draginfo)
	ChatManager.processWhisperHelper(tData.sName or tData.sUser, draginfo.getStringData());
	return true;
end
function onShortcutDrop(tData, draginfo)
	if Session.IsHost then
		if Input.isAltPressed() then
			if CharacterListManager.processShortcutDrop(tData, draginfo) then
				return true;
			end
		end
		if tData and ((tData.sUser or "") ~= "") then
			local w = Interface.openWindow(draginfo.getShortcutData());
			if w then
				w.share(tData.sUser);
			end
		end
		return true;
	end
	return CharacterListManager.processShortcutDrop(tData, draginfo);
end
function processShortcutDrop(tData, draginfo)
	if tData and ((tData.sPath or "") ~= "") then
		return ItemManager.handleAnyDrop(tData.sPath, draginfo);
	end
end
function onDefaultDrop(tData, draginfo)
	if tData and ((tData.sPath or "") ~= "") then
		return CombatDropManager.handleAnyDrop(draginfo, tData.sPath);
	end
end

--
--	STANDARD FEATURES
--

function processAFK()
	CharacterListManager.toggleAFK();
end
function toggleAFK()
	local sUser = Session.UserName;
	if CharacterListManager.getUserState(sUser) == "afk" then
		CharacterListManager.setUserState(sUser, "active");
	else
		CharacterListManager.setUserState(sUser, "afk");
	end

	local msgOOB = {};
	msgOOB.type = CharacterListManager.OOB_MSGTYPE_SETAFK;
	msgOOB.user = sUser;
	if CharacterListManager.getUserState(sUser) == "afk" then
		msgOOB.nState = 1;
	else
		msgOOB.nState = 0;
	end

	Comm.deliverOOBMessage(msgOOB);
end
function handleAFK(msgOOB)
	local sStateName;
	if msgOOB.nState == "0" then
		sStateName = "active";
	else
		sStateName = "afk";
	end
	if CharacterListManager.setUserState(msgOOB.user, sStateName) then
		CharacterListManager.messageAFK(msgOOB.user);
	end
end
function messageAFK(sUser)
	local msg = { font = "systemfont" };
	if CharacterListManager.getUserState(sUser) == "afk" then
		msg.text = Interface.getString("charlist_message_afkon") .. " (" .. sUser .. ")";
	else
		msg.text = Interface.getString("charlist_message_afkoff") .. " (" .. sUser .. ")";
	end
	Comm.addChatMessage(msg);
end

-- DEPRECATED (2025-03) (Short Release) -->
function releaseIdentity(sPath)
	UserManager.releaseIdentityPath(sPath);
end
