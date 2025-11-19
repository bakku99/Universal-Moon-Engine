--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onListChanged()
	self.updateContainers();
end

function onChildWindowCreated(w)
	w.count.setValue(1);
end

function update()
	if RecordDataManager.getLockMode("charsheet") then
		return;
	end
	local bEditMode = (window.inventorylist_iedit.getValue() == 1);
	if window.idelete_header then
		window.idelete_header.setVisible(bEditMode);
	end
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisible(bEditMode);
	end
end

local _sortLocked = false;
function setSortLock(isLocked)
	_sortLocked = isLocked;
end

function onSortCompare(w1, w2)
	if _sortLocked then
		return false;
	end
	return ItemManager.onInventorySortCompare(w1, w2);
end

function updateContainers()
	ItemManager.onInventorySortUpdate(self);
end

function onDrop(_, _, draginfo)
	return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo);
end