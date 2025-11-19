--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

function onInit()
	SoundManagerFile.loadData();
	SoundManager.refreshSettingsFilter(parentcontrol.window);
	ListManager.initCustomList(self);
	self.refresh();
end

function refresh()
	ListManager.setDisplayOffset(self, 0);
end
function refreshDisplayList()
	ListManager.refreshDisplayList(self);
end

function getAllRecords()
	return SoundManagerFile.getSoundData();
end
function addDisplayListItem(v)
	local wItem = list.createWindow();
	if wItem then
		wItem.soundid.setValue(v.sSoundID);
		wItem.name.setValue(v.sName);
		wItem.path.setValue(v.sPath);
	end
end

function getSortFunction()
	return SoundManagerFile.sortfuncSettingsContent;
end
function isFilteredRecord(v)
	return SoundManagerFile.isSettingsContentFilteredRecord(v);
end

function onDrop(_, _, draginfo)
	return SoundManagerFile.handleSettingsContentDrop(draginfo);
end
