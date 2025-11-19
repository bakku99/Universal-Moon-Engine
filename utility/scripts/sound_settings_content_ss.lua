--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

function onInit()
	SoundManagerSyrinscape.loadData();
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
	return SoundManagerSyrinscape.getSoundData();
end
function addDisplayListItem(v)
	local wItem = list.createWindow();
	if wItem then
		local tSound = SoundManagerSyrinscape.getSoundDataRecord(v, true);

		wItem.soundid.setValue(tSound.sSoundID);
		wItem.type.setValue(tSound.sDisplayType);
		wItem.name.setValue(tSound.sName);
		wItem.name.setTooltipText(string.format("ID: %s", tSound.sID));
		wItem.product.setValue(tSound.sProductPack);
	end
end

function getSortFunction()
	return SoundManagerSyrinscape.sortfuncSettingsContent;
end
function isFilteredRecord(v)
	return SoundManagerSyrinscape.isSettingsContentFilteredRecord(v);
end

function onDrop(_, _, draginfo)
	return SoundManagerSyrinscape.handleSettingsContentDrop(draginfo);
end
