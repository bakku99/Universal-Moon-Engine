--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_TOGGLETARGET = "toggletarget";
OOB_MSGTYPE_ADDTARGET = "addtarget";
OOB_MSGTYPE_REMOVETARGET = "removetarget";
OOB_MSGTYPE_CLEARTARGETS = "cleartargets";

function onInit()
	OOBManager.registerOOBMsgHandler(TargetingManager.OOB_MSGTYPE_TOGGLETARGET, TargetingManager.handleToggleTarget);
	OOBManager.registerOOBMsgHandler(TargetingManager.OOB_MSGTYPE_ADDTARGET, TargetingManager.handleAddTarget);
	OOBManager.registerOOBMsgHandler(TargetingManager.OOB_MSGTYPE_REMOVETARGET, TargetingManager.handleRemoveTarget);
	OOBManager.registerOOBMsgHandler(TargetingManager.OOB_MSGTYPE_CLEARTARGETS, TargetingManager.handleClearTargets);
	CombatManager.setCustomDeleteCombatantHandler(TargetingManager.onCTEntryDeleted);
end
function onCTEntryDeleted(nodeEntry)
	local sEntry = DB.getPath(nodeEntry);

	local sTrackerKey = CombatManager.getTrackerKeyFromCT(nodeEntry);

	for _,nodeCT in pairs(CombatManager.getCombatantNodes(sTrackerKey)) do
		for _,vTarget in ipairs(DB.getChildList(nodeCT, "targets")) do
			if DB.getValue(vTarget, "noderef", "") == sEntry then
				DB.deleteNode(vTarget);
			end
		end
		for _,vEffect in ipairs(DB.getChildList(nodeCT, "effects")) do
			if DB.getChildCount(vEffect, "targets") > 0 then
				for _,vEffectTarget in ipairs(DB.getChildList(vEffect, "targets")) do
					if DB.getValue(vEffectTarget, "noderef", "") == sEntry then
						DB.deleteNode(vEffectTarget);
					end
				end
				if DB.getChildCount(vEffect, "targets") == 0 then
					DB.deleteNode(vEffect);
				end
			end
		end
	end
end

function getFullTargets(rActor)
	local aTargets = {};

	if rActor then
		local nodeCT = ActorManager.getCTNode(rActor);
		if nodeCT then
			for _,vTarget in ipairs(DB.getChildList(nodeCT, "targets")) do
				local rTarget = ActorManager.resolveActor(DB.getValue(vTarget, "noderef", ""));
				table.insert(aTargets, rTarget);
			end
		end
	end

	return aTargets;
end
function getActiveToken(vImage)
	local nodeCurrentCT = CombatManager.getCurrentUserCT();
	if nodeCurrentCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCurrentCT);
		if tokenCT then
			local nodeContainer = tokenCT.getContainerNode();
			if nodeContainer then
				if DB.getPath(nodeContainer) == DB.getPath(vImage.getDatabaseNode()) then
					return tokenCT;
				end
			end
		end
	end

	return nil;
end
function getSelectionHelper(vImage)
	local aSelected = vImage.getSelectedTokens();
	if #aSelected > 0 then
		return aSelected;
	end

	local tokenCT = TargetingManager.getActiveToken(vImage);
	if tokenCT then
		return { tokenCT };
	end

	return {};
end

function clearTargets(vImage)
	local aSelected = TargetingManager.getSelectionHelper(vImage);

	for _,vToken in ipairs(aSelected) do
		local nodeCT = CombatManager.getCTFromToken(vToken);
		if nodeCT then
			TargetingManager.clearCTTargets(nodeCT);
		else
			vToken.clearTargets();
		end
	end
end
function setFactionTargets(vImage, bNegated)
	-- Get selection or active CT
	local aSelected = TargetingManager.getSelectionHelper(vImage);

	-- Clear previous targets
	for _,vToken in ipairs(aSelected) do
		local nodeCT = CombatManager.getCTFromToken(vToken);
		if nodeCT then
			TargetingManager.clearCTTargets(nodeCT);
		else
			vToken.clearTargets();
		end
	end

	-- Determine faction of selection
	local sFaction = "friend";
	local sSelectedFaction = nil;
	for _,vToken in ipairs(aSelected) do
		local nodeCT = CombatManager.getCTFromToken(vToken);
		if not nodeCT then
			sSelectedFaction = nil;
			break;
		end

		local sCTFaction = CombatManager.getFactionFromCT(nodeCT);
		if sSelectedFaction then
			if sSelectedFaction ~= sCTFaction then
				sSelectedFaction = nil;
				break;
			end
		else
			sSelectedFaction = sCTFaction;
		end
	end
	if sSelectedFaction then
		sFaction = sSelectedFaction;
	end

	-- Iterate through tracker to target correct faction
	local bHost = Session.IsHost;
	local sContainer = DB.getPath(vImage.getDatabaseNode());
	for _,nodeCT in pairs(CombatManager.getAllCombatantNodes()) do
		if DB.getValue(nodeCT, "tokenrefnode", "") == sContainer and (bHost or not CombatManager.isCTHidden(nodeCT)) then
			local bAdd;
			if bNegated then
				bAdd = (CombatManager.getFactionFromCT(nodeCT) ~= sFaction);
			else
				bAdd = (CombatManager.getFactionFromCT(nodeCT) == sFaction);
			end
			if bAdd then
				for _,vToken in ipairs(aSelected) do
					local bTokenAdd = true;
					local nodeTokenCT = CombatManager.getCTFromToken(vToken);
					if nodeTokenCT then
						if CombatManager.getTrackerKeyFromCT(nodeTokenCT) ~= CombatManager.getTrackerKeyFromCT(nodeCT) then
							bTokenAdd = false;
						end
					end
					if bTokenAdd then
						vToken.setTarget(true, DB.getValue(nodeCT, "tokenrefid", 0));
					end
				end
			end
		end
	end
end
function removeTarget(sSourceNode, sTargetNode)
	local tokenSource = CombatManager.getTokenFromCT(sSourceNode);
	local tokenTarget = CombatManager.getTokenFromCT(sTargetNode);

	if tokenSource and tokenTarget then
		if tokenSource.getContainerNode() == tokenTarget.getContainerNode() then
			tokenSource.setTarget(false, tokenTarget.getId());
			return;
		end
	end

	local nodeSourceCT = CombatManager.getCTFromNode(sSourceNode);
	local nodeTargetCT = CombatManager.getCTFromNode(sTargetNode);
	if nodeSourceCT and nodeTargetCT then
		TargetingManager.notifyRemoveTarget(nodeSourceCT, nodeTargetCT);
	end
end

function notifyToggleTarget(nodeSourceCT, nodeTargetCT)
	if not nodeSourceCT or not nodeTargetCT then
		return;
	end

	-- Build OOB message to pass toggle request to host
	local msgOOB = {};
	msgOOB.type = TargetingManager.OOB_MSGTYPE_TOGGLETARGET;
	msgOOB.sSourceNode = DB.getPath(nodeSourceCT);
	msgOOB.sTargetNode = DB.getPath(nodeTargetCT);

	Comm.deliverOOBMessage(msgOOB, "");
end
function notifyAddTarget(nodeSourceCT, nodeTargetCT)
	if not nodeSourceCT or not nodeTargetCT then
		return;
	end

	-- Build OOB message to pass toggle request to host
	local msgOOB = {};
	msgOOB.type = TargetingManager.OOB_MSGTYPE_ADDTARGET;
	msgOOB.sSourceNode = DB.getPath(nodeSourceCT);
	msgOOB.sTargetNode = DB.getPath(nodeTargetCT);

	Comm.deliverOOBMessage(msgOOB, "");
end
function notifyRemoveTarget(nodeSourceCT, nodeTargetCT)
	if not nodeSourceCT or not nodeTargetCT then
		return;
	end

	-- Build OOB message to pass toggle request to host
	local msgOOB = {};
	msgOOB.type = TargetingManager.OOB_MSGTYPE_REMOVETARGET;
	msgOOB.sSourceNode = DB.getPath(nodeSourceCT);
	msgOOB.sTargetNode = DB.getPath(nodeTargetCT);

	Comm.deliverOOBMessage(msgOOB, "");
end
function notifyClearTargets(nodeSourceCT)
	if not nodeSourceCT then
		return;
	end

	-- Build OOB message to pass toggle request to host
	local msgOOB = {};
	msgOOB.type = TargetingManager.OOB_MSGTYPE_CLEARTARGETS;
	msgOOB.sSourceNode = DB.getPath(nodeSourceCT);

	Comm.deliverOOBMessage(msgOOB, "");
end
function handleToggleTarget(msgOOB)
	local nodeSourceCT = DB.findNode(msgOOB.sSourceNode);
	local nodeTargetCT = DB.findNode(msgOOB.sTargetNode);
	TargetingManager.toggleCTTarget(nodeSourceCT, nodeTargetCT);
end
function handleAddTarget(msgOOB)
	local nodeSourceCT = DB.findNode(msgOOB.sSourceNode);
	local nodeTargetCT = DB.findNode(msgOOB.sTargetNode);
	TargetingManager.addCTTarget(nodeSourceCT, nodeTargetCT);
end
function handleRemoveTarget(msgOOB)
	local nodeSourceCT = DB.findNode(msgOOB.sSourceNode);
	local nodeTargetCT = DB.findNode(msgOOB.sTargetNode);
	TargetingManager.removeCTTarget(nodeSourceCT, nodeTargetCT);
end
function handleClearTargets(msgOOB)
	local nodeSourceCT = DB.findNode(msgOOB.sSourceNode);
	TargetingManager.clearCTTargets(nodeSourceCT);
end
function toggleCTTarget(nodeSourceCT, nodeTargetCT)
	if not nodeSourceCT or not nodeTargetCT then
		return;
	end

	-- Determine whether CT
	local vTargetEntry = nil;
	local sNodeTargetCT = DB.getPath(nodeTargetCT);
	for _,vTarget in ipairs(DB.getChildList(nodeSourceCT, "targets")) do
		if DB.getValue(vTarget, "noderef", "") == sNodeTargetCT then
			vTargetEntry = vTarget;
			break;
		end
	end

	if vTargetEntry then
		TargetingManager.removeCTTargetEntry(nodeSourceCT, vTargetEntry);
	else
		TargetingManager.addCTTarget(nodeSourceCT, nodeTargetCT);
	end
end
function addCTTarget(nodeSourceCT, nodeTargetCT)
	if not nodeSourceCT or not nodeTargetCT then
		return;
	end
	if CombatManager.getTrackerKeyFromCT(nodeSourceCT) ~= CombatManager.getTrackerKeyFromCT(nodeTargetCT) then
		return;
	end

	-- Get linked tokens (if any) and targets for source CT entry
	local tokenSource = CombatManager.getTokenFromCT(nodeSourceCT);
	local tokenTarget = CombatManager.getTokenFromCT(nodeTargetCT);

	-- Check for duplicates
	local sNodeTargetCT = DB.getPath(nodeTargetCT);
	for _,vTarget in ipairs(DB.getChildList(nodeSourceCT, "targets")) do
		if DB.getValue(vTarget, "noderef", "") == sNodeTargetCT then
			return;
		end
	end

	-- Create new target entry
	local vNew = DB.createChild(DB.createChild(nodeSourceCT, "targets"));
	DB.setValue(vNew, "noderef", "string", sNodeTargetCT);

	-- If source linked token is actually targeting target linked token, then remove targeting on map
	if tokenSource and tokenTarget and (DB.getPath(tokenSource.getContainerNode()) == DB.getPath(tokenTarget.getContainerNode())) then
		tokenSource.setTarget(true, tokenTarget);
	end
end
function removeCTTarget(nodeSourceCT, nodeTargetCT)
	if not nodeSourceCT or not nodeTargetCT then
		return;
	end

	-- Determine whether CT
	local vTargetEntry = nil;
	local sNodeTargetCT = DB.getPath(nodeTargetCT);
	for _,vTarget in ipairs(DB.getChildList(nodeSourceCT, "targets")) do
		if DB.getValue(vTarget, "noderef", "") == sNodeTargetCT then
			vTargetEntry = vTarget;
			break;
		end
	end

	if vTargetEntry then
		TargetingManager.removeCTTargetEntry(nodeSourceCT, vTargetEntry);
	end
end
function removeCTTargetEntry(nodeSourceCT, nodeSourceCTTarget)
	-- Get linked tokens (if any)
	local tokenSource = CombatManager.getTokenFromCT(nodeSourceCT);
	local tokenTarget = CombatManager.getTokenFromCT(DB.getValue(nodeSourceCTTarget, "noderef", ""));

	-- Delete CT target record
	DB.deleteNode(nodeSourceCTTarget);

	-- If source linked token is actually targeting target linked token, then remove targeting on map
	if tokenSource and tokenTarget and (DB.getPath(tokenSource.getContainerNode()) == DB.getPath(tokenTarget.getContainerNode())) then
		tokenSource.setTarget(false, tokenTarget);
	end
end
function clearCTTargets(nodeSourceCT)
	if not nodeSourceCT then
		return;
	end

	TargetingManager.lockTargetUpdate();

	-- Delete CT target records
	DB.deleteChildren(nodeSourceCT, "targets");

	-- If linked token, then clear targets on map
	local tokenCT = CombatManager.getTokenFromCT(nodeSourceCT);
	if tokenCT then
		tokenCT.clearTargets();
	end

	TargetingManager.unlockTargetUpdate();
end

function toggleClientCTTarget(nodeTargetCT)
	if not nodeTargetCT then
		return;
	end

	local nodeSourceCT = CombatManager.getCurrentUserCT();
	if not nodeSourceCT then
		ChatManager.SystemMessage(Interface.getString("ct_error_targetingpcmissingfromct"));
		return;
	end

	TargetingManager.notifyToggleTarget(nodeSourceCT, nodeTargetCT);
end
function removeCTTargeted(nodeTarget)
	if not nodeTarget then
		return;
	end

	local sTargetCT = DB.getPath(nodeTarget);

	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		for _,vTarget in ipairs(DB.getChildList(nodeCT, "targets")) do
			if DB.getValue(vTarget, "noderef", "") == sTargetCT then
				TargetingManager.removeCTTargetEntry(nodeCT, vTarget);
				break;
			end
		end
	end
end

function setCTFactionTargets(nodeSourceCT, bNegated)
	-- Clear current targets
	TargetingManager.clearCTTargets(nodeSourceCT);

	-- Lock updates from token objects to reduce overhead
	TargetingManager.lockTargetUpdate();

	-- Get the faction and targets for this CT entry
	local sFaction = CombatManager.getFactionFromCT(nodeSourceCT);

	-- Get the linked token for this CT entry (if any)
	local tokenSource = CombatManager.getTokenFromCT(nodeSourceCT);
	local sContainer = "";
	if tokenSource then
		sContainer = DB.getPath(tokenSource.getContainerNode());
	end

	-- Check each actor in combat tracker for faction match
	local nodeTargets = DB.createChild(nodeSourceCT, "targets");
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		local bAdd = false;
		if bNegated then
			if CombatManager.getFactionFromCT(nodeCT) ~= sFaction then
				bAdd = true;
			end
		else
			if CombatManager.getFactionFromCT(nodeCT) == sFaction then
				bAdd = true;
			end
		end

		-- If faction match, then add CT target (and token target if target has a linked token on the same map)
		if bAdd then
			local vNew = DB.createChild(nodeTargets);
			DB.setValue(vNew, "noderef", "string", DB.getPath(nodeCT));

			if (sContainer ~= "") and (DB.getValue(nodeCT, "tokenrefnode", "") == sContainer) then
				tokenSource.setTarget(true, DB.getValue(nodeCT, "tokenrefid", 0));
			end
		end
	end

	-- Restore updates from token objects
	TargetingManager.unlockTargetUpdate();
end
function updateTargetsFromCT(nodeSourceCT, newTokenInstance)
	if not nodeSourceCT or not newTokenInstance then
		return;
	end

	local sTrackerKey = CombatManager.getTrackerKeyFromCT(nodeSourceCT);

	-- Lock updates from token objects to reduce overhead
	TargetingManager.lockTargetUpdate();

	-- Look up all tokens in CT
	local aTokens = {};
	for _,nodeCT in pairs(CombatManager.getCombatantNodes(sTrackerKey)) do
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			aTokens[DB.getPath(nodeCT)] = tokenCT;
		end
	end

	-- Check if any CT targets for the new token are on the same map, and set the target lines
	local sContainer = DB.getPath(newTokenInstance.getContainerNode());
	for _,vTarget in ipairs(DB.getChildList(nodeSourceCT, "targets")) do
		local tokenCT = aTokens[DB.getValue(vTarget, "noderef", "")];
		if tokenCT and (sContainer == DB.getPath(tokenCT.getContainerNode())) then
			newTokenInstance.setTarget(true, tokenCT);
		end
	end

	-- Check if the new token should be targeted by any tokens on the map already
	local sNodeSourceCT = DB.getPath(nodeSourceCT);
	for _,nodeCT in pairs(CombatManager.getCombatantNodes(sTrackerKey)) do
		for _,vTarget in ipairs(DB.getChildList(nodeCT, "targets")) do
			if DB.getValue(vTarget, "noderef", "") == sNodeSourceCT then
				local tokenCT = aTokens[DB.getPath(nodeCT)];
				if tokenCT and (sContainer == DB.getPath(tokenCT.getContainerNode())) then
					tokenCT.setTarget(true, newTokenInstance);
				end
			end
		end
	end

	-- Restore updates from token objects
	TargetingManager.unlockTargetUpdate();
end

local bTargetUpdateLock = false;
function lockTargetUpdate()
	bTargetUpdateLock = true;
end
function unlockTargetUpdate()
	bTargetUpdateLock = false;
end
function onTargetUpdate(tokenMap)
	if bTargetUpdateLock then
		return;
	end

	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if not nodeCT then
		return;
	end

	local nodeTargets = DB.createChild(nodeCT, "targets");

	local sTokenContainer = DB.getPath(tokenMap.getContainerNode());
	local aTargets = tokenMap.getTargets();

	-- Figure out which targets in the CT are on the same map
	local aCTMapTargets = {};
	for _,vTarget in ipairs(DB.getChildList(nodeTargets)) do
		local sTargetCT = DB.getValue(vTarget, "noderef", "");
		if sTargetCT ~= "" then
			local nodeTargetCT = DB.findNode(sTargetCT);
			if DB.getValue(nodeTargetCT, "tokenrefnode", "") == sTokenContainer then
				aCTMapTargets[DB.getValue(nodeTargetCT, "tokenrefid", 0)] = vTarget;
			end
		end
	end

	-- Remove CT targets which are not part of current token target set
	for k,v in pairs(aCTMapTargets) do
		if not StringManager.contains(aTargets, k) then
			DB.deleteNode(v);
		end
	end

	-- Add CT targets for any token targets not already accounted for
	for _,v in ipairs(aTargets) do
		if not aCTMapTargets[v] then
			local nodeTargetCT = CombatManager.getCTFromToken(Token.getToken(sTokenContainer, v));
			if nodeTargetCT then
				local nodeNewTarget = DB.createChild(nodeTargets);
				DB.setValue(nodeNewTarget, "noderef", "string", DB.getPath(nodeTargetCT));
			end
		end
	end
end
