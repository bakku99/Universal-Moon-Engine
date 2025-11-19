--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals recordtype

local _sRecordType = "";

function onInit()
	if recordtype then
		self.setRecordType(recordtype[1]);
	end
end

function setRecordType(sRecordType)
	_sRecordType = sRecordType;
end

function onButtonPress()
	if window.clearFilterValues then
		window.clearFilterValues();
	end
	window.list_iedit.setValue(0);

	RecordManager.addRecordByType(_sRecordType, window.getDatabaseNode());
end
