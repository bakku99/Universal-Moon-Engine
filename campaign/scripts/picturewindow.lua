--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ListManager.initCustomList(self);

	self.rebuildList();
	self.addHandlers();
end
function onClose()
	ListManager.onCloseWindow(self);

	self.removeHandlers();
end

function addHandlers()
	local sChildPath = "picture.*";
	DB.addHandler(sChildPath, "onAdd", self.onChildAdded);
	DB.addHandler(sChildPath, "onDelete", self.onChildDeleted);
	DB.addHandler(DB.getPath(sChildPath, "name"), "onUpdate", self.onChildNameChange);
end
function removeHandlers()
	local sChildPath = "picture.*";
	DB.removeHandler(sChildPath, "onAdd", self.onChildAdded);
	DB.removeHandler(sChildPath, "onDelete", self.onChildDeleted);
	DB.removeHandler(DB.getPath(sChildPath, "name"), "onUpdate", self.onChildNameChange);
end

local _tRecords = {};
function getAllRecords()
	return _tRecords;
end
function clearRecords()
	_tRecords = {};
end

local _bDelayedChildrenChanged = false;
function getDelayedRebuild()
	return _bDelayedChildrenChanged;
end
function setDelayedRebuild(v)
	_bDelayedChildrenChanged = v;
end

function onChildAdded(node)
	self.addListRecord(node);
	self.onListRecordsChanged(true);
end
function onChildDeleted(node)
	local tRecords = self.getAllRecords();
	if not tRecords[node] then
		return;
	end

	tRecords[node] = nil;
	self.onListRecordsChanged(true);
end
function onChildNameChange(nodeName)
	local node = DB.getParent(nodeName);
	local rRecord = self.getAllRecords()[node];
	if not rRecord then
		return;
	end

	rRecord.sDisplayName = DB.getValue(node, "name", "");
	rRecord.sDisplayNameLower = Utility.convertStringToLower(rRecord.sDisplayName);
	ListManager.refreshDisplayList(self);
end
function onListChanged()
	if self.getDelayedRebuild() then
		self.onListRecordsChanged(false);
	end
end

function addListRecord(node)
	local rRecord = {};
	rRecord.vNode = node;
	rRecord.sDisplayName = DB.getValue(node, "name", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();

	self.getAllRecords()[node] = rRecord;
end
function onListRecordsChanged(bAllowDelay)
	if bAllowDelay then
		ListManager.helperSaveScrollPosition(self);
		self.setDelayedRebuild(true);
		self.list.setDatabaseNode(nil);
	else
		self.setDelayedRebuild(false);
		ListManager.refreshDisplayList(self);
	end
end
function rebuildList(bSkipRefresh)
	self.clearRecords();
	for _,v in ipairs(DB.getChildList("picture")) do
		self.addListRecord(v);
	end

	ListManager.setDisplayOffset(self, 0, true);
	if not bSkipRefresh then
		self.onListRecordsChanged();
	end
end

local _sFilter = "";
function onFilterChanged()
	_sFilter = Utility.convertStringToLower(WindowManager.getInnerControlValue(self, "filter"));
	ListManager.refreshDisplayList(self, true);
end
function isFilteredRecord(v)
	if _sFilter ~= "" then
		if not string.find(v.sDisplayNameLower, _sFilter, 0, true) then
			return false;
		end
	end
	return true;
end
function clearFilter()
	filter.setValue("");
end

function onDrop(_, _, draginfo)
	if not Session.IsHost then
		return;
	end
	if StringManager.contains({ "image", "portrait", "token" }, draginfo.getType()) then
		PictureManager.createPictureItem(draginfo.getTokenData());
	end
end
