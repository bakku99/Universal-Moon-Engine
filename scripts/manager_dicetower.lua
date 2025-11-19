--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_DICETOWER = "dicetower";

function onTabletopInit()
	if Session.IsHost then
		OOBManager.registerOOBMsgHandler(DiceTowerManager.OOB_MSGTYPE_DICETOWER, DiceTowerManager.handleDiceTower);
	end
end

local _control = nil;
function registerControl(c)
	_control = c;
	DiceTowerManager.activate();
end

function activate()
	OptionsManager.registerCallback("TBOX", DiceTowerManager.update);
	OptionsManager.registerCallback("REVL", DiceTowerManager.update);

	DiceTowerManager.update();
end

function update()
	if _control then
		local bShow = false;
		if OptionsManager.isOption("TBOX", "on") then
			bShow = not Session.IsHost or not OptionsManager.isOption("REVL", "off");
		end
		_control.setVisible(bShow);
		if _control.window.setEnabled then
			_control.window.setEnabled(bShow);
		end

		if not Session.IsHost then
			_control.resetMenuItems();
			if bShow then
				_control.registerMenuItem(Interface.getString("dicetower_menu_whisper"), "broadcast", 7);
			end
		end
	end
end

function onMenuSelection(selection)
	if Session.IsHost then return; end

	if selection == 7 then
		ChatManager.sendWhisperToGM();
	end
end

function encodeOOBFromDrag(draginfo, i, rSource)
	local rRoll = ActionsManager.decodeRollFromDrag(draginfo, i);
	return DiceTowerManager.encodeOOBFromRoll(rRoll, rSource);
end

function encodeOOBFromRoll(rRoll, rSource)
	rRoll.type = DiceTowerManager.OOB_MSGTYPE_DICETOWER;
	rRoll.sender = ActorManager.getCreatureNodeName(rSource);
	rRoll.sUser = Session.UserName;

	if rRoll.aDice and rRoll.aDice.expr then
		if (rRoll.nMod or 0) ~= 0 then
			rRoll.sDice = string.format("%s%+d", rRoll.aDice.expr, rRoll.nMod);
		else
			rRoll.sDice = rRoll.aDice.expr;
		end
	else
		rRoll.sDice = DiceManager.convertDiceToString(rRoll.aDice, rRoll.nMod);
	end

	UtilityManager.simplifyEncode(rRoll, "aDice");
	return rRoll;
end

function decodeRollFromOOB(msgOOB)
	msgOOB.type = nil;
	msgOOB.sender = nil;
	msgOOB.bTower = true;
	msgOOB.bSecret = true;

	msgOOB.nMod = tonumber(msgOOB.nMod) or 0;
	UtilityManager.simplifyDecode(msgOOB, "aDice");

	return msgOOB;
end

function onHover(bOnControl)
	if _control then
		local bShowHover = false;
		if bOnControl then
			local draginfo = Input.getDragData();
			if draginfo then
				local sDragType = draginfo.getType();
				if GameSystem.actions[sDragType] then
					bShowHover = true;
				end
			end
		end
		if bShowHover then
			_control.setIcon("dicetower_drop");
		else
			_control.setIcon("dicetower_normal");
		end
	end
end

function onDrop(draginfo)
	DiceTowerManager.onHover(false);
	if _control then
		if OptionsManager.isOption("TBOX", "on") then
			local sDragType = draginfo.getType();
			if GameSystem.actions[sDragType] then
				local rSource = ActionsManager.actionDropHelper(draginfo, false);
				for i = 1, draginfo.getSlotCount() do
					local rRoll = ActionsManager.decodeRollFromDrag(draginfo, i);
					DiceTowerManager.sendRoll(rRoll, rSource);
				end
			elseif sDragType == "string" then
				ChatManager.processWhisperHelper("GM", draginfo.getStringData());
			end
		end
	end

	return true;
end

function sendRoll(rRoll, rSource)
	local msgOOB = DiceTowerManager.encodeOOBFromRoll(rRoll, rSource);

	if not Session.IsHost then
		local msg = {
			font = "chatfont",
			assets = {
				ChatIdentityManager.getActorAsset(rSource),
				ChatIdentityManager.getDiceTowerAsset(),
			},
		};
		if rSource then
			msg.sender = ActorManager.getDisplayName(rSource);
		end
		msg.text = string.format("%s [%s]", msgOOB.sDesc or "", msgOOB.sDice);

		Comm.addChatMessage(msg);
	end

	msgOOB.sDice = nil;
	Comm.deliverOOBMessage(msgOOB, "");
end

function handleDiceTower(msgOOB)
	local rActor = nil;
	if msgOOB.sender and msgOOB.sender ~= "" then
		rActor = ActorManager.resolveActor(msgOOB.sender);
	end

	local rRoll = DiceTowerManager.decodeRollFromOOB(msgOOB);
	rRoll.sDesc = string.format("[%s] %s", Interface.getString("dicetower_tag"), (rRoll.sDesc or ""));

	ActionsManager.roll(rActor, nil, rRoll);
end
