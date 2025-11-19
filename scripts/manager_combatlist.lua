--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

EOR_SIZE = 30;

PORTRAIT_SIZE = 100;
PORTRAIT_PADDING_W = 15;
LEFT_MARGIN = 15;
RIGHT_MARGIN = 15;
TOP_MARGIN = 10;
BOTTOM_MARGIN = 10;

HEALTHDOT_HOFFSET = -5;
HEALTHDOT_VOFFSET = -5;

function onTabletopInit()
	if CombatListManager.isEnabled() then
		CombatListManager.setupCombatIntegration();
		CombatListManager.setupOptionsIntegration();
	end
end

--
--	REGISTRATIONS
--

local _bEnabled = false;
function isEnabled()
	return _bEnabled;
end
function setEnabled(bValue)
	_bEnabled = bValue;
end

local _fnCustomBuild = nil;
function getCustomDisplayBuild()
	return _fnCustomBuild;
end
function setCustomDisplayBuild(fn)
	_fnCustomBuild = fn;
end

function registerStandardInitSupport()
	CombatListManager.setEnabled(true);

	ActorDisplayManager.setDisplayCallback("faction", "combatlist", CombatListManager.addActorDisplayFaction);
	CombatManager.addAllCombatantFieldChangeHandler("friendfoe", "onUpdate", CombatListManager.onFactionUpdate);

	ActorDisplayManager.setDisplayCallback("initresult", "combatlist", CombatListManager.addActorDisplayDefaultInitResult);
	CombatManager.addAllCombatantFieldChangeHandler("initresult", "onUpdate", CombatListManager.onInitResultUpdate);
end
function onFactionUpdate(nodeField)
	local nodeActor = DB.getParent(nodeField);
	ActorDisplayManager.updateActorDisplayControls("faction", ActorManager.resolveActor(nodeActor));
end
function addActorDisplayFaction(cDisplay, rActor)
	if not cDisplay or not rActor then
		return;
	end

	local nodeCT = ActorManager.getCTNode(rActor);
	local sFaction = DB.getValue(nodeCT, "friendfoe", "");

	local sAsset = nil;
	if sFaction == "friend" then
		sAsset = "ct_faction_friend";
	elseif sFaction == "neutral" then
		sAsset = "ct_faction_neutral";
	elseif sFaction == "foe" then
		sAsset = "ct_faction_foe";
	end

	if (sAsset or "") ~= "" then
		local wgt = cDisplay.findWidget("faction");
		if not wgt then
			wgt = cDisplay.addBitmapWidget({
				name = "faction",
				position = "topleft",
				x = 3, y = 1,
				w = 16, h = 16,
			});
		end
		wgt.setBitmap(sAsset);
	else
		local wgt = cDisplay.findWidget("faction");
		if wgt then
			wgt.destroy();
		end
	end
end
function onInitResultUpdate(nodeField)
	local nodeActor = DB.getParent(nodeField);
	ActorDisplayManager.updateActorDisplayControls("initresult", ActorManager.resolveActor(nodeActor));
	CombatListManager.refreshDisplayList();
end
function addActorDisplayDefaultInitResult(cDisplay, rActor)
	if not cDisplay or not rActor then
		return;
	end

	local nodeCT = ActorManager.getCTNode(rActor);
	local sFaction = DB.getValue(nodeCT, "friendfoe", "");
	local sOptCTSI = OptionsManager.getOption("CTSI");
	local bShowInit = Session.IsHost or (((sOptCTSI == "friend") and (sFaction == "friend")) or (sOptCTSI == "on"));
	if bShowInit then
		local wgt = cDisplay.findWidget("initresult");
		if not wgt then
			local sFrame, sFrameOffset = TokenManager.getTokenFrameOrdinal();
			local sFont = TokenManager.getTokenFontOrdinal();
			wgt = cDisplay.addTextWidget({
				name = "initresult",
				font = sFont, text = "",
				frame = sFrame, frameoffset = sFrameOffset,
				position = "bottom",
				minw = 16,
			});
		end

		local nInitResult = DB.getValue(nodeCT, "initresult", 0);
		wgt.setText(nInitResult);
	else
		local wgt = cDisplay.findWidget("initresult");
		if wgt then
			wgt.destroy();
		end
	end
end

function registerSWSupport()
	CombatListManager.setEnabled(true);

	ActorDisplayManager.setDisplayCallback("faction", "combatlist", CombatListManager.addActorDisplayFaction);
	CombatManager.addAllCombatantFieldChangeHandler("friendfoe", "onUpdate", CombatListManager.onFactionUpdate);

	ActorDisplayManager.setDisplayCallback("initcardicon", "combatlist", self.addActorDisplaySWADEInitResult);
	DB.addHandler(DB.getPath(CombatManager.CT_LIST, "*.initcardicon"), "onUpdate", self.onSWADEInitResultUpdate);
	DB.addHandler(DB.getPath(CombatManager.CT_LIST, "*.deal"), "onUpdate", self.onSWADEInitResultUpdate);
end
function onSWADEInitResultUpdate(nodeField)
	local nodeActorGroup = DB.getParent(nodeField);
	for _,vActor in ipairs(DB.getChildList(nodeActorGroup, "combatants")) do
		ActorDisplayManager.updateActorDisplayControls("initcardicon", ActorManager.resolveActor(vActor));
	end
	CombatListManager.refreshDisplayList();
end
function addActorDisplaySWADEInitResult(cDisplay, rActor)
	if not cDisplay or not rActor then
		return;
	end

	local nodeCT = ActorManager.getCTNode(rActor);
	local bOnHold = DB.getValue(DB.getChild(nodeCT, "..."), "deal", 1) == 0;
	local sCard = DB.getValue(DB.getChild(nodeCT, "..."), "initcardicon", "CardBack");
	local wgt = cDisplay.findWidget("actioncard");
	if not wgt then
		local sFrame = TokenManager.getTokenFrameOrdinal();
		wgt = cDisplay.addBitmapWidget({
			name = "actioncard",
			frame = sFrame, frameoffset = "2,2,2,2",
			position = "bottom",
			x = 0, y = -12,
			w = 40, h = 40,
		});
	end

	if bOnHold then
		wgt.setBitmap("indicator_act");
	else
		wgt.setBitmap(sCard);
	end
end

function register2D20Support()
	CombatListManager.registerStandardInitSupport();

	-- CombatListManager.setEnabled(true);

	-- ActorDisplayManager.setDisplayCallback("faction", "", CombatListManager.addActorDisplayFaction);
	-- CombatManager.addAllCombatantFieldChangeHandler("faction", "onUpdate", CombatListManager.onFactionUpdate);

	-- CombatListManager.setCustomDisplayBuild(CombatListManager.custom2D20Build);
	-- DB.addHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH, "turntaken"), "onUpdate", CombatListManager.refreshDisplayList);
end
function custom2D20Build(tData)
	if #tData.tSortedCT <= 0 then
		return;
	end

	local nActive = nil;
	local tTurnTaken = {};
	local nodeActive = CombatManager.getActiveCT();
	for k,v in ipairs(tData.tSortedCT) do
		if v == nodeActive then
			nActive = k;
		end
		local nTurnTaken = DB.getValue(v, "turntaken", 0);
		if nTurnTaken ~= 0 then
			tTurnTaken[v] = true;
		end
	end

	local tSortedTurnNotTaken = {};
	local tSortedTurnTaken = {};
	for i = nActive or 1, #tData.tSortedCT do
		local nodeCT = tData.tSortedCT[i];
		if Session.IsHost or not CombatManager.isCTHidden(nodeCT) then
			if tTurnTaken[nodeCT] then
				table.insert(tSortedTurnTaken, nodeCT);
			else
				table.insert(tSortedTurnNotTaken, nodeCT);
			end
		end
	end

	local bEORAdded = false;
	local nIndexTurnNotTaken = 0;
	local nIndexTurnTaken = 0;
	local nIndex = 1;
	while nIndex < tData.nOptDESKTOPCTSIZE do
		if nIndexTurnNotTaken < #tSortedTurnNotTaken then
			nIndexTurnNotTaken = nIndexTurnNotTaken + 1;
			table.insert(tData.tSortedDisplayPaths, DB.getPath(tSortedTurnNotTaken[nIndexTurnNotTaken]));
			nIndex = nIndex + 1;
		elseif not bEORAdded then
			bEORAdded = true;
			table.insert(tData.tSortedDisplayPaths, "");
		elseif nIndexTurnTaken < #tSortedTurnTaken then
			nIndexTurnTaken = nIndexTurnTaken + 1;
			table.insert(tData.tSortedDisplayPaths, DB.getPath(tSortedTurnTaken[nIndexTurnTaken]));
			nIndex = nIndex + 1;
		else
			break;
		end
	end
end

--
--	COMBAT TRACKER
--

function setupCombatIntegration()
	ActorDisplayManager.setDisplayCallback("tokenvis", "combatlist", CombatListManager.addActorDisplayTokenVis);

	CombatManager.addAllCombatantFieldChangeHandler("tokenvis", "onUpdate", CombatListManager.onTokenVisUpdate);
	CombatManager.addAllCombatantFieldChangeHandler("active", "onUpdate", CombatListManager.refreshDisplayList);
	CombatManager.addAllCombatantFieldChangeHandler("link", "onUpdate", CombatListManager.refreshDisplayList);
	CombatManager.setCustomPostDeleteCombatantHandler(CombatListManager.refreshDisplayList);

	DB.addHandler(CombatManager.CT_ROUND, "onUpdate", CombatListManager.refreshDisplayList);
end
function addActorDisplayTokenVis(cDisplay, rActor)
	if not cDisplay or not rActor or ActorManager.isPC(rActor) then
		return;
	end

	local nodeCT = ActorManager.getCTNode(rActor);
	local nTokenVis = DB.getValue(nodeCT, "tokenvis", 0);
	local sColor;
	if nTokenVis == 0 then
		sColor = "80FFFFFF";
	end

	cDisplay.setColor(sColor);
end
function onTokenVisUpdate(nodeField)
	local nodeActor = DB.getParent(nodeField);
	ActorDisplayManager.updateActorDisplayControls("tokenvis", ActorManager.resolveActor(nodeActor));
	CombatListManager.refreshDisplayList();
end

--
--	OPTIONS
--

function setupOptionsIntegration()
	OptionsManager.registerOptionData({
		sKey = "DESKTOPCTSIZE", bLocal = true,
		tCustom = { labelsres = "option_val_8|option_val_10|option_val_12", values = "8|10|12", baselabelres = "option_val_6", baseval = "6", default = "6", },
	});

	OptionsManager.registerCallback("DESKTOPCTSIZE", CombatListManager.onOptionUpdate);
	OptionsManager.registerCallback("CTSI", CombatListManager.onOptionUpdate);
	OptionsManager.registerCallback("HRIR", CombatListManager.onOptionUpdate);
end
function onOptionUpdate()
	CombatListManager.refreshDisplayList();
end

--
--	DISPLAY MANAGEMENT
--

local _wCombatList = nil;
function registerWindow(w)
	_wCombatList = w;
	if w then
		w.anchor.setStaticBounds(CombatListManager.LEFT_MARGIN - CombatListManager.PORTRAIT_PADDING_W, CombatListManager.TOP_MARGIN, 0, 0);
		if w.button_nextactor then
			w.button_nextactor.setAnchor("left", "anchor", "right", "relative", CombatListManager.PORTRAIT_PADDING_W);
		end
		CombatListManager.refreshDisplayList();
	else
		CombatListManager.clearDisplayList();
	end
end
function getWindow()
	return _wCombatList;
end

function resizeWindow()
	local w = CombatListManager.getWindow();
	if not w then
		return;
	end

	local nListW = CombatListManager.LEFT_MARGIN + CombatListManager.RIGHT_MARGIN;
	local nListH = CombatListManager.TOP_MARGIN + CombatListManager.PORTRAIT_SIZE + CombatListManager.BOTTOM_MARGIN;

	for _,c in ipairs(CombatListManager.getDisplayList()) do
		nListW = nListW + c.getAnchoredWidth() + CombatListManager.PORTRAIT_PADDING_W;
	end
	nListW = nListW + (w.button_nextactor.getAnchoredWidth() + CombatListManager.PORTRAIT_PADDING_W);

	WindowManager.callOuterWindowFunction(w, "onContentSizeChanged", nListW, nListH);
end

local _sCombatEntryClass = "tabletop_combatlist_entry";
function setEntryClass(s)
	_sCombatEntryClass = s;
end
function getEntryClass()
	return _sCombatEntryClass;
end

local _tDisplayList = {};
function getDisplayList()
	return _tDisplayList;
end
function clearDisplayList()
	_tDisplayList = {};
end
function getDisplayControlByPath(sPath)
	if (sPath or "") == "" then
		return nil;
	end
	for _,c in ipairs(CombatListManager.getDisplayList()) do
		if c.getRecordPath() == sPath then
			return c;
		end
	end
	return nil;
end

function createEORControl(w, tData)
	local nRound = DB.getValue(CombatManager.CT_ROUND, 0);
	for k,v in ipairs(tData.tSortedDisplayPaths) do
		if v == "" then
			if k > 1 then
				nRound = nRound + 1;
			end
			local c = CombatListManager.createEndOfRound(w, { nRound = nRound });
			tData.ctrlEOR = c;
			break;
		end
	end
end
function destroyEORControl()
	local tDestroy = {};
	for _,c in ipairs(CombatListManager.getDisplayList()) do
		if c.getRecordPath() == "" then
			table.insert(tDestroy, c);
		end
	end
	for _,c in ipairs(tDestroy) do
		CombatListManager.destroyEntry(c);
	end
end

function refreshDisplayList()
	local w = CombatListManager.getWindow();
	if not w then
		return;
	end

	local tData = CombatListManager.initDisplayRefresh();
	CombatListManager.buildDisplayData(tData);
	CombatListManager.synchDisplayEntries(w, tData);
	CombatListManager.updateDisplayList(w);
end
function initDisplayRefresh()
	local tData = {
		nOptDESKTOPCTSIZE = tonumber(OptionsManager.getOption("DESKTOPCTSIZE")),
		tCurrDisplayPaths = {},
		tSortedCT = CombatManager.getSortedCombatantList(),
		tSortedDisplayPaths = {},
	};

	CombatListManager.destroyEORControl();

	for _,c in ipairs(CombatListManager.getDisplayList()) do
		local s = c.getRecordPath();
		if s ~= "" then
			tData.tCurrDisplayPaths[s] = true;
		end
	end
	return tData;
end
function buildDisplayData(tData)
	local fnBuild = CombatListManager.getCustomDisplayBuild() or CombatListManager.defaultDisplayBuild;
	fnBuild(tData);
end
function defaultDisplayBuild(tData)
	if #tData.tSortedCT <= 0 then
		return;
	end

	local nodeActive = CombatManager.getActiveCT();
	local nActive = 0;
	for k,v in ipairs(tData.tSortedCT) do
		if v == nodeActive then
			nActive = k;
			break;
		end
	end

	local bEORAdded = false;
	if nActive == 0 then
		bEORAdded = true;
		table.insert(tData.tSortedDisplayPaths, "");
		nActive = 1;
	end

	local nSortedCTIndex = nActive;
	local nCount = 0;
	while nCount < tData.nOptDESKTOPCTSIZE do
		if nSortedCTIndex <= #tData.tSortedCT then
			if Session.IsHost or not CombatManager.isCTHidden(tData.tSortedCT[nSortedCTIndex]) then
				table.insert(tData.tSortedDisplayPaths, DB.getPath(tData.tSortedCT[nSortedCTIndex]));
				nCount = nCount + 1;
			end
			nSortedCTIndex = nSortedCTIndex + 1;
		else
			if bEORAdded then
				break;
			end
			bEORAdded = true;
			table.insert(tData.tSortedDisplayPaths, "");
			nSortedCTIndex = 1;
		end

		if nSortedCTIndex == nActive then
			break;
		end
	end
	if not bEORAdded then
		table.insert(tData.tSortedDisplayPaths, 1, "");
	end
end
function synchDisplayEntries(w, tData)
	local tNewDisplayPaths = {};
	for _,v in ipairs(tData.tSortedDisplayPaths) do
		if v ~= "" then
			tNewDisplayPaths[v] = { sPath = v; };
		end
	end
	for k,v in pairs(tNewDisplayPaths) do
		if not tData.tCurrDisplayPaths[k] then
			CombatListManager.createEntry(w, v);
		end
	end
	for k,_ in pairs(tData.tCurrDisplayPaths) do
		local c = CombatListManager.getDisplayControlByPath(k);
		if not tNewDisplayPaths[k] then
			CombatListManager.destroyEntry(c);
		end
	end

	CombatListManager.createEORControl(w, tData);

	local tNewDisplayList = {};
	for _,v in ipairs(tData.tSortedDisplayPaths) do
		local c;
		if v == "" then
			c = tData.ctrlEOR;
			tData.ctrlEOR = nil;
		else
			c = CombatListManager.getDisplayControlByPath(v);
		end
		if c then
			table.insert(tNewDisplayList, c);
		end
	end
	CombatListManager.clearDisplayList();
	local tList = CombatListManager.getDisplayList();
	for _,c in ipairs(tNewDisplayList) do
		table.insert(tList, c);
	end
end
function updateDisplayList(w)
	w.button_nextactor.sendToBack();
	local tList = CombatListManager.getDisplayList();
	for i = #tList, 1, -1 do
		tList[i].sendToBack();
	end
	w.anchor.sendToBack();
	CombatListManager.resizeWindow();
end

function createEntry(w, tData)
	local c = w.createControl(CombatListManager.getEntryClass());
	table.insert(CombatListManager.getDisplayList(), c);

	c.setAnchor("left", "anchor", "right", "relative", CombatListManager.PORTRAIT_PADDING_W);
	c.setAnchoredWidth(CombatListManager.PORTRAIT_SIZE);
	c.setAnchoredHeight(CombatListManager.PORTRAIT_SIZE);

	ActorDisplayManager.addDisplayControl(c, "combatlist", ActorManager.resolveActor(tData.sPath));
	c.initData(tData);
	return c;
end
function createEndOfRound(w, tData)
	local c = w.createControl("tabletop_combatlist_eor");
	table.insert(CombatListManager.getDisplayList(), c);

	c.setAnchor("left", "anchor", "right", "relative", CombatListManager.PORTRAIT_PADDING_W);
	c.setAnchoredHeight(CombatListManager.PORTRAIT_SIZE);

	c.initData(tData);
	return c;
end
function destroyEntry(c)
	if not c then
		return;
	end
	local tList = CombatListManager.getDisplayList();
	for k,v in ipairs(tList) do
		if c == v then
			table.remove(tList, k);
			break;
		end
	end
	c.destroy();
end
