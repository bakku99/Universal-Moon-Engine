--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals hideonempty nodrag

function onInit()
	if hideonempty then
		self.onValueChanged();
	end
end

function onValueChanged()
	if hideonempty then
		setVisible(not isEmpty());
	end
end

function onDragStart(_, _, _, draginfo)
	if nodrag then
		return;
	end

	local sClass, sRecord = getValue();

	draginfo.setType("shortcut");
	draginfo.setIcon(Interface.getLinkIcon(sClass));
	draginfo.setShortcutData(sClass, sRecord);

	local sDesc = RecordDataManager.getRecordDisplayName(window.getDatabaseNode(), sClass, true);
	if sDesc == "" and window.name then
		sDesc = window.name.getValue();
	end
	draginfo.setDescription(sDesc);
	return true;
end
