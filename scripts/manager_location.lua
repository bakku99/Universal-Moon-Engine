--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	REGISTRATIONS
--

local _tLocationDefaultSub = "location_main_default";
function registerDefaultLocationSub(sSub)
	_tLocationDefaultSub = sSub;
end

local _tLocationTypes = {};
function registerLocationType(tData)
	if not tData or not tData.sKey then
		return;
	end
	_tLocationTypes[tData.sKey] = tData;
end
function getLocationTypeSub(sTypeKey)
	if not _tLocationTypes[sTypeKey or ""] then
		return _tLocationDefaultSub or "";
	end
	return _tLocationTypes[sTypeKey or ""].sSub or _tLocationDefaultSub or "";
end

--
--	WINDOW HANDLING
--

function addLinkToLocation(node, sClass, sRecord)
	local sRecordType = RecordDataManager.getRecordTypeFromDisplayClass(sClass);
	if sRecordType == "location" then
		local nodeSubLocations = DB.findNode(DB.getPath(node, "sublocations"));
		if nodeSubLocations then
			local nodeSource = DB.findNode(sRecord);
			local nodeTarget = DB.createChildAndCopy(nodeSubLocations, nodeSource);
			DB.setValue(nodeTarget, "locked", "number", 1);
			return true;
		end
	end

	return false;
end
