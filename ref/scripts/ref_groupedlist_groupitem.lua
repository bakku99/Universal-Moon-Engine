--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function setItemRecordType(sRecordType)
	local sDisplayClass = RecordDataManager.getRecordTypeDisplayClass(sRecordType, getDatabaseNode());
	self.setItemClass(sDisplayClass);
end

function setItemClass(sDisplayClass)
	local node = getDatabaseNode();
	if node and sDisplayClass ~= "" then
		link.setValue(sDisplayClass, DB.getPath(node));
	else
		link.setVisible(false);
		link.setEnabled(false);
	end
end

function setColumnInfo(tColumns)
	for nColumn,rColumn in ipairs(tColumns) do
		ListManager.createViewEntryControl(self, nColumn, rColumn);
	end
end
