--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals name_emptyres nonid_name_emptyres

function onInit()
	self.initRecordTypeControls();
	self.onStateChanged();
end

function initRecordTypeControls()
	if link then
		link.setValue(WindowManager.getTopWindow(self).getClass());
	end

	local sRecordType = WindowManager.getRecordType(self);

	if not nonid_name and RecordDataManager.getIDMode(sRecordType) then
		if sRecordType == "image" then
			createControl("string_record_header_name_nonid_image", "nonid_name");
		else
			createControl("string_record_header_name_nonid", "nonid_name");
		end
		if Session.IsHost then
			createControl("sub_record_header_nonid_edit", "sub_nonid_edit");
		end
	end
	if RecordDataManager.getCustomDieMode(sRecordType) then
		if not customdie then
			createControl("icon_record_header_customdie", "customdie");
		end
	end
	if not picture and RecordDataManager.getPictureMode(sRecordType) then
		createControl("icon_record_header_picture", "picture");
	end
	if not token and RecordDataManager.getTokenMode(sRecordType) then
		createControl("icon_record_header_token", "token");
	end

	if name then
		if sRecordType ~= "" then
			name.setEmptyText(RecordDataManager.getRecordTypeDisplayTextEmpty(sRecordType));
		elseif name_emptyres then
			name.setEmptyText(Interface.getString(name_emptyres[1]));
		end
	end
	if nonid_name then
		if sRecordType ~= "" then
			nonid_name.setEmptyText(RecordDataManager.getRecordTypeDisplayTextEmptyUnidentified(sRecordType));
		elseif nonid_name_emptyres then
			nonid_name.setEmptyText(Interface.getString(nonid_name_emptyres[1]));
		end
	end
	if nonid_name_edit then
		if sRecordType ~= "" then
			nonid_name_edit.setEmptyText(RecordDataManager.getRecordTypeDisplayTextEmptyUnidentified(sRecordType));
		elseif nonid_name_emptyres then
			nonid_name_edit.setEmptyText(Interface.getString(nonid_name_emptyres[1]));
		end
	end
end

function onLockModeChanged()
	self.onStateChanged();
end
function onIDModeChanged()
	self.onStateChanged();
end
function onCustomDieChanged()
	if customdie then
		local bShowCustomDie = (DB.getValue(getDatabaseNode(), "customdie", "") ~= "");
		customdie.setVisible(bShowCustomDie);
	end
end

function onStateChanged()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = RecordDataManager.getIDState(WindowManager.getRecordType(self), nodeRecord);

	WindowManager.callSafeControlsSetLockMode(self, { "name", "nonid_name", "picture", "token", }, bReadOnly);
	if nonid_name then
		name.setVisible(bID);
		nonid_name.setVisible(not bID);
	end
	if picture then
		picture.setVisible(not bReadOnly or (DB.getValue(nodeRecord, "picture", "") ~= ""));
	end
	if token then
		token.setVisible(not bReadOnly or (DB.getValue(nodeRecord, "token", "") ~= ""));
	end
	if Session.IsHost then
		local bShowEdit = not bReadOnly or (DB.getValue(nodeRecord, "nonid_name", "") ~= "");
		WindowManager.callSafeControlsSetVisible(self, { "sub_nonid_edit", }, bShowEdit);
	end
end

function onDrop(_, _, draginfo)
	if not draginfo.isType("diceskin") then
		return false;
	end
	if WindowManager.getReadOnlyState(getDatabaseNode()) then
		return false;
	end
	local sRecordType = WindowManager.getRecordType(self);
	if not RecordDataManager.getCustomDieMode(sRecordType) then
		return false;
	end

	DB.setValue(getDatabaseNode(), "customdie", "string", draginfo.getStringData());
	return true;
end

-- DEPRECATED (2025-03)
function update()
end
