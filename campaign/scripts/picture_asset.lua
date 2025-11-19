--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onValueChanged();
end

function setLockMode()
	self.onValueChanged();
end
function getLockMode()
	return isReadOnly();
end

function onValueChanged()
	local sName = getName();
	local cAdd = window[sName .. "_iadd"];
	local cDelete = window[sName .. "_idelete"];

	local sRecordType = RecordDataManager.getRecordTypeFromRecordPath(window.getDatabasePath());
	local bReadOnly = false;
	if RecordDataManager.getLockMode(sRecordType) then
		bReadOnly = WindowManager.getReadOnlyState(window.getDatabaseNode());
	end
	setReadOnly(bReadOnly);
	if bReadOnly then
		if cAdd then
			cAdd.setVisible(false);
		end
		if cDelete then
			cDelete.setVisible(false);
		end
	else
		local sValue = getValue();
		if cAdd then
			cAdd.setVisible(((sValue or "") == ""));
		end
		if cDelete then
			cDelete.setVisible(((sValue or "") ~= ""));
		end
	end
end

function onClickDown()
	return true;
end
function onClickRelease()
	local sName = getName();
	local sAsset = getValue() or "";
	if sAsset ~= "" then
		if sName == "portrait" then
			return false;
		end
		AssetManager.onAssetFieldPressed(sName, sAsset);
		return true;
	end
	if isReadOnly() then
		return false;
	end
	AssetManager.onAssetFieldAdd(sName);
	return true;
end
function onDragStart(_, _, _, draginfo)
	local sAsset = getValue() or "";
	if sAsset ~= "" then
		local sName = getName();
		if sName == "portrait" or sName == "token" or sName == "token3Dflat" then
			return RecordAssetManager.handlePictureDragStart(WindowManager.getTopWindow(window).getDatabaseNode(), draginfo);
		else
			return AssetManager.onAssetFieldDrag(getName(), sAsset, draginfo);
		end
	end
end
function onDrop(_, _, draginfo)
	if isReadOnly() then
		return;
	end
	local sDragType = draginfo.getType();
	if sDragType == "shortcut" then
		local sClass = draginfo.getShortcutData();
		if RecordDataManager.getRecordTypeFromDisplayClass(sClass) == "image" then
			local node = draginfo.getDatabaseNode();
			if node then
				local sAsset = DB.getText(node, "image", "");
				if sAsset ~= "" then
					setValue(sAsset);
				end
			end
		else
			local sAsset = draginfo.getTokenData();
			if (sAsset or "") ~= "" then
				setValue(sAsset);
			end
		end
		return true;
	end
end
