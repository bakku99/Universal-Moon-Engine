--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_PS_FORMATION_SET = "ps_formation_set";

FRAME_PADDING = 20;

SLOT_RANGE = 3;
SLOT_PADDING = 10;
SLOT_SIZE = 50;

PS_FORMATION_LIST = "partysheet.formation.list";
PS_FORMATION_FACING = "partysheet.formation.facing";

local _wFormation = nil;

--
--	INITIALIZATION
--

function onTabletopInit()
	OOBManager.registerOOBMsgHandler(PartyFormationManager.OOB_MSGTYPE_PS_FORMATION_SET, PartyFormationManager.handlePartyFormationSet);
	if Session.IsHost then
		for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
			PartyFormationManager.onFormationEntryLinkUpdateHelper(DB.getValue(v, "link", "", ""));
		end

		DB.addHandler(DB.getPath(PartyFormationManager.PS_FORMATION_LIST, "*", "link"), "onUpdate", PartyFormationManager.onFormationEntryLinkUpdate);
		DB.addHandler(DB.getPath(PartyFormationManager.PS_FORMATION_LIST, "*"), "onDelete", PartyFormationManager.onFormationEntryDeleted);
	end
end

--
--	FORMATION DATA TRACKING
--

function onFormationSourceDelete(nodeSource)
	if not Session.IsHost or not nodeSource then
		return;
	end

	local sSourcePath = DB.getPath(nodeSource);
	for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
		local _,sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sSourcePath then
			DB.deleteNode(v);
		end
	end
end
function onFormationSourceTokenChange(nodeToken)
	if not Session.IsHost or not nodeToken then
		return;
	end
	local nodeSource = DB.getParent(nodeToken);
	if not nodeSource then
		return;
	end

	local sSourcePath = DB.getPath(nodeSource);
	for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
		local _,sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sSourcePath then
			DB.setValue(v, "token", "token", UtilityManager.resolveActorToken(nodeSource));
		end
	end
end
function onFormationEntryLinkUpdate(nodeLink)
	PartyFormationManager.onFormationEntryLinkUpdateHelper(DB.getValue(nodeLink));
end
function onFormationEntryLinkUpdateHelper(_, sRecord)
	if (sRecord or "") ~= "" then
		DB.addHandler(DB.getPath(sRecord, "token"), "onUpdate", PartyFormationManager.onFormationSourceTokenChange);
		if not UtilityManager.isPathMatch(sRecord, "charsheet.*", true) then
			DB.addHandler(sRecord, "onDelete", PartyFormationManager.onFormationSourceDelete);
		end
	end
end
function onFormationEntryDeleted(nodeEntry)
	local _,sRecord = DB.getValue(nodeEntry, "link", "", "");
	if sRecord ~= "" then
		DB.removeHandler(DB.getPath(sRecord, "token"), "onUpdate", PartyFormationManager.onFormationSourceTokenChange);
		if not UtilityManager.isPathMatch(sRecord, "charsheet.*", true) then
			DB.removeHandler(sRecord, "onDelete", PartyFormationManager.onFormationSourceDelete);
		end
	end

	PartyFormationManager.onFormationDataChange();
end
function onFormationDataChange()
	PartyFormationManager.updateDisplay();
end

--
--	FORMATION WINDOW TRACKING
--

function registerPartyFormationWindow(wFormation)
	if not wFormation then
		PartyFormationManager.unregisterPartyFormationWindow();
		return;
	end

	if not _wFormation then
		DB.addHandler(PartyFormationManager.PS_FORMATION_FACING, "onUpdate", PartyFormationManager.onFormationDataChange);
		DB.addHandler(PartyFormationManager.PS_FORMATION_LIST, "onChildUpdate", PartyFormationManager.onFormationDataChange);
	end

	_wFormation = wFormation;
	PartyFormationManager.buildDisplay();
	PartyFormationManager.updateDisplay();
end
function unregisterPartyFormationWindow()
	if not _wFormation then
		return;
	end

	DB.removeHandler(PartyFormationManager.PS_FORMATION_FACING, "onUpdate", PartyFormationManager.onFormationDataChange);
	DB.removeHandler(PartyFormationManager.PS_FORMATION_LIST, "onChildUpdate", PartyFormationManager.onFormationDataChange);
	_wFormation = nil;
end

--
--	FORMATION SLOT INTERATION
--

function getSlotData(tSlotPos)
	local nodeSlot = nil;
	local sSlot = StringManager.convertPointToString(tSlotPos);
	for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
		if DB.getValue(v, "xy", "") == sSlot then
			nodeSlot = v;
			break;
		end
	end
	if not nodeSlot then
		return nil;
	end

	local sClass, sRecord = DB.getValue(nodeSlot, "link", "", "");
	if ((sClass or "") == "") or ((sRecord or "") == "") then
		return nil;
	end

	local sToken = DB.getValue(nodeSlot, "token", "");
	if (sToken or "") == "" then
		return nil;
	end

	return {
		x = tSlotPos.x,
		y = tSlotPos.y,
		sClass = sClass,
		sRecord = sRecord,
		sToken = sToken,
	};
end
function onSlotDragStart(tSlotPos, draginfo)
	local tSlotData = PartyFormationManager.getSlotData(tSlotPos);
	if not tSlotData then
		return;
	end
	if not Session.IsHost and not DB.isOwner(tSlotData.sRecord) then
		return;
	end

	draginfo.setType("shortcut");
	draginfo.setTokenData(tSlotData.sToken);
	draginfo.setShortcutData(tSlotData.sClass, tSlotData.sRecord);
	draginfo.setDescription(ActorManager.getDisplayName(tSlotData.sRecord));
	return true;
end
function onSlotDrop(tSlotPos, draginfo)
	-- Make sure we have a valid drag type
	local sDragType = draginfo.getType();
	if (sDragType ~= "shortcut") and (sDragType ~= "token") then
		return;
	end

	-- Make sure we have a valid owned data source
	local sClass, sRecord = draginfo.getShortcutData();
	if (sRecord or "") == "" then
		return;
	end
	if not Session.IsHost and not DB.isOwner(sRecord) then
		return;
	end

	-- Only allow PCs and friendly CT entries
	local bAdd = false;
	local rActor = ActorManager.resolveActor(sRecord);
	if ActorManager.isPC(rActor) then
		bAdd = true;
	else
		local nodeCT = ActorManager.getCTNode(rActor);
		if nodeCT then
			if CombatManager.getFactionFromCT(nodeCT) == "friend" then
				bAdd = true;
			end
		end
	end
	if not bAdd then
		ChatManager.SystemMessage("Only owned player characters (and friendly combat tracker entries) can be added to party formation.");
		return;
	end

	-- If player and existing slot entry is not owned, then exit
	if not Session.IsHost then
		local tSlotData = PartyFormationManager.getSlotData(tSlotPos);
		if tSlotData then
			if not DB.isOwner(tSlotData.sRecord) then
				return;
			end
		end
	end

	-- Perform set/swap
	PartyFormationManager.notifyPartyFormationSet(tSlotPos, sClass, sRecord);
end

function notifyPartyFormationSet(tSlotPos, sClass, sRecord)
	local msgOOB = {};
	msgOOB.type = PartyFormationManager.OOB_MSGTYPE_PS_FORMATION_SET;

	msgOOB.sClass = sClass;
	msgOOB.sRecord = sRecord;
	msgOOB.x = tSlotPos.x;
	msgOOB.y = tSlotPos.y;

	Comm.deliverOOBMessage(msgOOB, "");
end
function handlePartyFormationSet(msgOOB)
	local tSlotPos = { x = msgOOB.x, y = msgOOB.y };

	local tSlotData = PartyFormationManager.getSlotData(tSlotPos);
	if tSlotData then
		local tSwapSlotPos = nil;
		for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
			local _,sRecord = DB.getValue(v, "link", "", "");
			if sRecord == msgOOB.sRecord then
				tSwapSlotPos = StringManager.convertStringToPoint(DB.getValue(v, "xy", ""));
				break;
			end
		end
		if tSwapSlotPos then
			PartyFormationManager.setSlot(tSwapSlotPos, tSlotData.sClass, tSlotData.sRecord);
		end
	end

	PartyFormationManager.setSlot(tSlotPos, msgOOB.sClass, msgOOB.sRecord);
end

function setSlot(tSlotPos, sClassParam, sRecordParam)
	if not Session.IsHost then
		return;
	end

	if ((sClassParam or "") ~= "") and ((sRecordParam or "") ~= "") then
		PartyFormationManager.setSlotHelper(tSlotPos, sClassParam, sRecordParam);
	else
		PartyFormationManager.clearSlotHelper(tSlotPos);
	end
end
function setSlotHelper(tSlotPosParam, sClassParam, sRecordParam)
	local sSlot = StringManager.convertPointToString(tSlotPosParam);

	for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
		local _,sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sRecordParam then
			if DB.getValue(v, "xy", "") == sSlot then
				return;
			end
			PartyFormationManager.clearSlotHelper(tSlotPosParam);
			DB.setValue(v, "xy", "string", sSlot);
			return;
		end
	end

	PartyFormationManager.clearSlotHelper(tSlotPosParam);

	DB.createNode(PartyFormationManager.PS_FORMATION_LIST);
	local newEntry = DB.createChild(PartyFormationManager.PS_FORMATION_LIST);
	DB.setValue(newEntry, "link", "windowreference", sClassParam, sRecordParam);
	DB.setValue(newEntry, "token", "token", UtilityManager.resolveActorToken(sRecordParam));
	DB.setValue(newEntry, "xy", "string", sSlot);
end
function clearSlotHelper(tSlotPos)
	local sSlotClear = StringManager.convertPointToString(tSlotPos);
	for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
		if DB.getValue(v, "xy", "") == sSlotClear then
			DB.deleteNode(v);
		end
	end
end

--
--	FORMATION COMMANDS
--

function clearFormation()
	DB.deleteChildren(PartyFormationManager.PS_FORMATION_LIST);
end

function rotateFormationLeft()
	for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
		local tSlotPos = StringManager.convertStringToPoint(DB.getValue(v, "xy", ""));
		if tSlotPos then
			local sNewSlotPos = StringManager.convertPointToString({ x = -tSlotPos.y, y = tSlotPos.x });
			DB.setValue(v, "xy", "string", sNewSlotPos);
		end
	end

	local nFacing = PartyFormationManager.getFormationFacing();
	DB.setValue(PartyFormationManager.PS_FORMATION_FACING, "number", (nFacing - 1) % 4);
end
function rotateFormationRight()
	for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
		local tSlotPos = StringManager.convertStringToPoint(DB.getValue(v, "xy", ""));
		if tSlotPos then
			local sNewSlotPos = StringManager.convertPointToString({ x = tSlotPos.y, y = -tSlotPos.x });
			DB.setValue(v, "xy", "string", sNewSlotPos);
		end
	end

	local nFacing = PartyFormationManager.getFormationFacing();
	DB.setValue(PartyFormationManager.PS_FORMATION_FACING, "number", (nFacing + 1) % 4);
end

function fillFormation(sFillType)
	local tFactionData = CombatFormationManager.getFactionFormationRecords("friend");
	CombatFormationManager.fillFactionFormationSlots("friend", tFactionData, sFillType);
	PartyFormationManager.helperFillAssignSlots(tFactionData);
end
function helperFillAssignSlots(tFactionData)
	for _,v in ipairs(tFactionData) do
		if v.tSlotPos then
			PartyFormationManager.setSlotHelper(v.tSlotPos, v.sClass, v.sRecord);
		end
	end
end

--
--	FORMATION DISPLAY UPDATING
--

function buildDisplay()
	if not _wFormation then
		return;
	end

	local slotAdvance = (PartyFormationManager.SLOT_SIZE + PartyFormationManager.SLOT_PADDING);
	for x = -PartyFormationManager.SLOT_RANGE, PartyFormationManager.SLOT_RANGE do
		for y = PartyFormationManager.SLOT_RANGE, -PartyFormationManager.SLOT_RANGE, -1 do
			local sSlotName = string.format("slot_%d_%d", x, y);
			local cSlot = _wFormation.createControl("ps_formation_slot", sSlotName);
			cSlot.setAnchor("top", "", "top", "absolute", ((PartyFormationManager.SLOT_RANGE - y) * slotAdvance) + PartyFormationManager.FRAME_PADDING);
			cSlot.setAnchor("left", "", "left", "absolute", ((x + PartyFormationManager.SLOT_RANGE) * slotAdvance) + PartyFormationManager.FRAME_PADDING);
			cSlot.setAnchoredWidth(PartyFormationManager.SLOT_SIZE);
			cSlot.setAnchoredHeight(PartyFormationManager.SLOT_SIZE);
		end
	end

	local cSpacerRight = _wFormation.createControl("genericcontrol", "spacer_right");
	cSpacerRight.setAnchor("top", "", "top", "absolute", 0);
	cSpacerRight.setAnchor("left", "", "left", "absolute", PartyFormationManager.FRAME_PADDING + (PartyFormationManager.SLOT_RANGE * 2 * slotAdvance) + PartyFormationManager.SLOT_SIZE);
	cSpacerRight.setAnchor("bottom", "", "bottom", "absolute", 0);
	cSpacerRight.setAnchoredWidth(PartyFormationManager.FRAME_PADDING);

	local cSpacerBottom = _wFormation.createControl("genericcontrol", "spacer_bottom");
	cSpacerBottom.setAnchor("top", "", "top", "absolute", PartyFormationManager.FRAME_PADDING + (PartyFormationManager.SLOT_RANGE * 2 * slotAdvance) + PartyFormationManager.SLOT_SIZE);
	cSpacerBottom.setAnchor("left", "", "left", "absolute", 0);
	cSpacerBottom.setAnchor("right", "", "right", "absolute", 0);
	cSpacerBottom.setAnchoredHeight(PartyFormationManager.FRAME_PADDING);
end
function updateDisplay()
	if not _wFormation then
		return;
	end

	PartyFormationManager.updateDisplayControlHelper();
	PartyFormationManager.updateDisplayPartyHelper();
	PartyFormationManager.updateDisplayFacingHelper();
end
function updateDisplayControlHelper()
	for x = -PartyFormationManager.SLOT_RANGE, PartyFormationManager.SLOT_RANGE do
		for y = PartyFormationManager.SLOT_RANGE, -PartyFormationManager.SLOT_RANGE, -1 do
			PartyFormationManager.clearDisplaySlotHelper({ x = x, y = y });
		end
	end
end
function updateDisplayPartyHelper()
	for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
		local tSlotPos = StringManager.convertStringToPoint(DB.getValue(v, "xy", ""));
		if tSlotPos then
			PartyFormationManager.updateDisplaySlotHelper(tSlotPos, v);
		end
	end
end
function updateDisplaySlotHelper(tSlotPos, nodeEntry)
	if not _wFormation then
		return;
	end

	local sSlotName = string.format("slot_%d_%d", tSlotPos.x, tSlotPos.y);
	local cSlot = _wFormation[sSlotName];
	if not cSlot then
		return;
	end

	local sToken = DB.getValue(nodeEntry, "token", "");
	local bCanEdit;
	if (sToken or "") ~= "" then
		if Session.IsHost then
			bCanEdit = true;
		else
			local _, sRecord = DB.getValue(nodeEntry, "link", "", "");
			bCanEdit = DB.isOwner(sRecord);
		end
	end
	cSlot.setData(sToken, bCanEdit);
end
function clearDisplaySlotHelper(tSlotPos)
	if not _wFormation then
		return;
	end

	local sSlotName = string.format("slot_%d_%d", tSlotPos.x, tSlotPos.y);
	local cSlot = _wFormation[sSlotName];
	if not cSlot then
		return;
	end

	cSlot.setData("");
end
-- Clockwise: 0 = Up, 1 = Right, 2 = Down, 3 = Left
function updateDisplayFacingHelper()
	local nFillFacing = PartyFormationManager.getFormationFacing();
	local sFacingControlName = string.format("facing_%d", nFillFacing);
	local c = _wFormation[sFacingControlName];
	if c then
		return;
	end

	for i=0,3 do
		local sTemp = string.format("facing_%d", i);
		c = _wFormation[sTemp];
		if c then
			c.destroy();
		end
	end

	if nFillFacing == 1 then
		c = _wFormation.createControl("button_arrow_right", sFacingControlName);
		local sParentName = string.format("slot_%d_%d", PartyFormationManager.SLOT_RANGE, 0);
		c.setAnchor("top", sParentName, "center", "absolute", -12);
		c.setAnchor("left", sParentName, "right", "absolute", -2);
	elseif nFillFacing == 2 then
		c = _wFormation.createControl("button_arrow_down", sFacingControlName);
		local sParentName = string.format("slot_%d_%d", 0, -PartyFormationManager.SLOT_RANGE);
		c.setAnchor("top", sParentName, "bottom", "absolute", -2);
		c.setAnchor("left", sParentName, "center", "absolute", -12);
	elseif nFillFacing == 3 then
		c = _wFormation.createControl("button_arrow_left", sFacingControlName);
		local sParentName = string.format("slot_%d_%d", -PartyFormationManager.SLOT_RANGE, 0);
		c.setAnchor("top", sParentName, "center", "absolute", -12);
		c.setAnchor("right", sParentName, "left", "absolute", 2);
	else
		c = _wFormation.createControl("button_arrow_up", sFacingControlName);
		local sParentName = string.format("slot_%d_%d", 0, PartyFormationManager.SLOT_RANGE);
		c.setAnchor("bottom", sParentName, "top", "absolute", 2);
		c.setAnchor("left", sParentName, "center", "absolute", -12);
	end
end

--
--	FORMATION PLACEMENT
--

function getFormationFacing()
	return DB.getValue(PartyFormationManager.PS_FORMATION_FACING, 0);
end
function getFormation()
	local tResult = {};
	for _,v in ipairs(DB.getChildList(PartyFormationManager.PS_FORMATION_LIST)) do
		local tSlotPos = StringManager.convertStringToPoint(DB.getValue(v, "xy", ""));
		local _,sRecord = DB.getValue(v, "link", "", "");
		if tSlotPos and ((sRecord or "") ~= "") then
			tResult[sRecord] = tSlotPos;
		end
	end
	return tResult;
end
