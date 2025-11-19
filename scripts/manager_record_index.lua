--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function getItemDisplayClass(sRecordType)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return "";
	end
	return tRecordType.sListDisplayClass or "";
end

function getButtons(sRecordType)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return {};
	end
	if Session.IsHost then
		tRecordType.aGMListButtons = tRecordType.aGMListButtons or {};
		return tRecordType.aGMListButtons;
	end
	tRecordType.aPlayerListButtons = tRecordType.aPlayerListButtons or {};
	return tRecordType.aPlayerListButtons;
end
function addButton(sRecordType, sTemplate)
	if (sTemplate or "") == "" then
		return;
	end
	local tButtons = RecordIndexManager.getButtons(sRecordType);
	if StringManager.contains(tButtons, sTemplate) then
		return;
	end
	table.insert(tButtons, sTemplate);
end
function removeButton(sRecordType, sTemplate)
	if (sTemplate or "") == "" then
		return;
	end
	local tButtons = RecordIndexManager.getButtons(sRecordType);
	for k, s in ipairs(tButtons) do
		if s == sTemplate then
			table.remove(tButtons, k);
			return;
		end
	end
end

function getEditButtons(sRecordType)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return {};
	end
	if Session.IsHost then
		tRecordType.aGMEditButtons = tRecordType.aGMEditButtons or {};
		return tRecordType.aGMEditButtons;
	end
	tRecordType.aPlayerEditButtons = tRecordType.aPlayerEditButtons or {};
	return tRecordType.aPlayerEditButtons;
end

function getCustomFilters(sRecordType)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return {};
	end
	return tRecordType.aCustomFilters or {};
end

function getCategoryMode(sRecordType)
	return not RecordDataManager.getRecordTypeOption(sRecordType, "bNoCategories");
end
function getEditMode(sRecordType)
	local tRecordType = RecordDataManager.getRecordTypeData(sRecordType);
	if not tRecordType then
		return false;
	end

	local sEditMode = tRecordType.sEditMode or "";
	if sEditMode == "play" then
		return true;
	elseif sEditMode == "none" then
		return false;
	end

	-- Default behavior (host only editing, no local or player)
	return Session.IsHost;
end
