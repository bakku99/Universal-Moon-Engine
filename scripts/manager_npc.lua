--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	if Session.IsHost then
		CombatManager.addCombatantFieldChangeHandler("isidentified", "onUpdate", NPCManager.onCTEntryIDUpdate);
	end
end

local bProcessingCTEntryIDUpdate = false;
function onCTEntryIDUpdate(vNode)
	if bProcessingCTEntryIDUpdate then return; end
	bProcessingCTEntryIDUpdate = true;

	local nodeCT = DB.getParent(vNode);
	local nIsIdentified = DB.getValue(nodeCT, "isidentified", 1);
	local _,sCTEntrySourceRecord = DB.getValue(nodeCT, "sourcelink", "", "");
	if sCTEntrySourceRecord ~= "" then
		for _,v in pairs(CombatManager.getCombatantNodes()) do
			local _,sRecord = DB.getValue(v, "sourcelink", "", "");
			if (sRecord == sCTEntrySourceRecord) and (v ~= nodeCT) then
				DB.setValue(v, "isidentified", "number", nIsIdentified);
			end
		end
	end

	bProcessingCTEntryIDUpdate = false;
end

function addLinkToBattle(nodeBattle, sLinkClass, sLinkRecord, nMult)
	local sTargetNPCList = RecordDataManager.getCustomData("battle", "npclist", "npclist");

	if (sLinkClass == "battle") or (sLinkClass == "battlerandom") then
		local tDelete = {};
		local nodeTargetNPCList = DB.createChild(nodeBattle, sTargetNPCList);
		for _,nodeSrcNPC in ipairs(DB.getChildList(DB.getPath(sLinkRecord, sTargetNPCList))) do
			local nodeTargetNPC = DB.createChildAndCopy(nodeTargetNPCList, nodeSrcNPC);
			if sLinkClass == "battlerandom" then
				local nCount = CampaignDataManager.convertRndEncExprToEncCount(nodeTargetNPC);
				if nCount <= 0 then
					table.insert(tDelete, nodeTargetNPC);
				end
			end
			if nMult then
				DB.setValue(nodeTargetNPC, "count", "number", DB.getValue(nodeTargetNPC, "count", 1) * nMult);
			end
		end
		for _,nodeDelete in ipairs(tDelete) do
			DB.deleteNode(nodeDelete);
		end
	else
		local sSourceType = RecordDataManager.getRecordTypeFromRecordPath(sLinkRecord);
		local aCombatClasses = RecordDataManager.getCustomData("battle", "acceptdrop", { "npc" });
		if not StringManager.contains(aCombatClasses, sSourceType) then
			ChatManager.SystemMessage(Interface.getString("battle_message_wrong_source"));
			return false;
		end

		local sName = DB.getValue(DB.getPath(sLinkRecord, "name"), "");

		local nodeTargetNPCList = DB.createChild(nodeBattle, sTargetNPCList);
		local nodeTargetNPC = DB.createChild(nodeTargetNPCList);
		DB.setValue(nodeTargetNPC, "count", "number", nMult or 1);
		DB.setValue(nodeTargetNPC, "name", "string", sName);
		DB.setValue(nodeTargetNPC, "link", "windowreference", sLinkClass, sLinkRecord);

		local nodeID = DB.getChild(sLinkRecord, "isidentified");
		if nodeID then
			DB.setValue(nodeTargetNPC, "isidentified", "number", DB.getValue(nodeID));
		end

		local sToken = DB.getValue(DB.getPath(sLinkRecord, "token"), "");
		sToken = UtilityManager.resolveDisplayToken(sToken, sName);
		DB.setValue(nodeTargetNPC, "token", "token", sToken);
	end

	return true;
end
