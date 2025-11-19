--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	RecordShareManager.setWindowClassCallback("advlogentry", RecordShareManagerCore.handleCalendarLogEntryShare);
end

function handleCalendarLogEntryShare(node, tOutput)
	table.insert(tOutput, string.format("%s - %s", Interface.getString("calendar_single_logentry"), DB.getText(node, "name", "")));
	table.insert(tOutput, "");
	table.insert(tOutput, DB.getText(node, "logentry", ""));
end
