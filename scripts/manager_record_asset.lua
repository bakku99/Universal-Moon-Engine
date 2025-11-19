--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	GENERAL RECORD HANDLING
--

function handlePicturePressed(nodeRecord, w)
	local wTop = WindowManager.getTopWindow(w);
	if wTop and wTop.tabs then
		local nTabIndex = wTop.tabs.getTabIndexByName("pictures");
		if nTabIndex > 0 then
			wTop.tabs.activateTab(nTabIndex);
			return;
		end
	end

	Interface.openWindow("pictures", nodeRecord);
	return true;
end
function handlePictureDragStart(vRecord, draginfo)
	if not vRecord then
		return false;
	end
	local nodeRecord;
	if type(vRecord) == "databasenode" then
		nodeRecord = vRecord;
	else
		nodeRecord = DB.findNode(vRecord);
	end
	if not nodeRecord then
		return false;
	end

	local sRecord = DB.getPath(nodeRecord);
	local sRecordType = RecordDataManager.getRecordTypeFromRecordPath(sRecord);
	if sRecordType == "" then
		local rActor = ActorManager.resolveActor(nodeRecord);
		if not rActor then
			return false;
		end
		sRecordType = ActorManager.getRecordType(rActor);
		sRecord = ActorManager.getCreatureNodeName(rActor);
	end

	local sClass = RecordDataManager.getRecordTypeDisplayClass(sRecordType);
	local sToken = DB.getValue(nodeRecord, "token", "");
	if sToken == "" then
		if sRecordType == "charsheet" then
			sToken = "portrait_" .. DB.getName(nodeRecord) .. "_token";
		end
		if sToken == "" then
			return false;
		end
	end
	local sName;
	if RecordDataManager.getIDState(sRecordType, nodeRecord) then
		sName = DB.getValue(nodeRecord, "name", "");
	else
		sName = DB.getValue(nodeRecord, "nonid_name", "");
	end
	if sName == "" then
		sName = RecordDataManager.getRecordTypeDisplayTextEmpty(sRecordType);
	end

	if sToken ~= "" then
		draginfo.setType("shortcut");
		draginfo.setShortcutData(sClass, sRecord);
		draginfo.setDescription(sName);
		draginfo.setTokenData(sToken);

		local base = draginfo.createBaseData();
		base.setType("token");
		base.setShortcutData(sClass, sRecord);
		base.setTokenData(sToken);
	else
		draginfo.setType("shortcut");
		draginfo.setIcon(Interface.getLinkIcon(sClass));
		draginfo.setShortcutData(sClass, sRecord);
		draginfo.setDescription(sName);
	end
	return true;
end
function handlePictureDrop(nodeRecord, draginfo, sField)
	if not nodeRecord then
		return false;
	end

	local sAsset = draginfo.getTokenData();
	if (sAsset or "") == "" then
		return false;
	end

	local sRecordType = RecordDataManager.getRecordTypeFromRecordPath(DB.getPath(nodeRecord));
	if sField == "token" then
		DB.setValue(nodeRecord, "token", "token", sAsset);
	elseif sField == "picture" then
		DB.setValue(nodeRecord, "picture", "token", sAsset);
	else
		local sDragType = draginfo.getType();
		if sDragType == "portrait" then
			if sRecordType == "charsheet" then
				RecordAssetManager.setCharPortrait(nodeRecord, sAsset);
			else
				DB.setValue(nodeRecord, "token", "token", sAsset);
			end
		elseif sDragType == "token" then
			DB.setValue(nodeRecord, "token", "token", sAsset);
		elseif sDragType == "image" then
			if sRecordType == "charsheet" then
				RecordAssetManager.setCharPortrait(nodeRecord, sAsset);
			else
				DB.setValue(nodeRecord, "picture", "token", sAsset);
			end
		end
	end
	return true;
end

--
--	CHARACTER SPECIFIC HANDLING
--

function handleCharPortraitDrop(nodeRecord, draginfo)
	if not nodeRecord then
		return false;
	end
	if not StringManager.contains({ "image", "portrait", "token" }, draginfo.getType()) then
		return false;
	end

	RecordAssetManager.setCharPortrait(nodeRecord, draginfo.getTokenData());
	return true;
end
function setCharPortrait(nodeChar, sAsset)
	if not nodeChar or not sAsset then
		return;
	end

	User.setPortrait(nodeChar, sAsset);
	DB.setValue(nodeChar, "portrait", "token", sAsset);

	local sToken = DB.getValue(nodeChar, "token", "");
	if nodeChar and ((sToken == "") or (sToken:sub(1,9) == "portrait_")) then
		DB.setValue(nodeChar, "token", "token", "portrait_" .. DB.getName(nodeChar) .. "_token");
	end

	local w = Interface.findWindow("charselect_client", "");
	if w then
		for _,wChild in pairs(w.list.getWindows()) do
			if wChild.portrait and wChild.localdatabasenode and (wChild.localdatabasenode == nodeChar) then
				wChild.portrait.setFile(sAsset);
			end
		end
	end
end
