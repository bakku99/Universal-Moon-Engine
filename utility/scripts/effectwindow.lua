--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local bDelayedChildrenChanged = false;
local bDelayedRebuild = false;

local sFilter = "";

function onInit()
	ListManager.initCustomList(self);

	self.rebuildList();
	self.addHandlers();

	Module.addEventHandler("onModuleLoad", self.onModuleLoadAndUnload);
	Module.addEventHandler("onModuleUnload", self.onModuleLoadAndUnload);
end
function onClose()
	ListManager.onCloseWindow(self);

	self.removeHandlers();
end

function getListWindow()
	return sub_content.subwindow;
end

local _sRecordType = "effect";
function getRecordType()
	return _sRecordType;
end

local _tRecords = {};
function getAllRecords()
	return _tRecords;
end
function clearRecords()
	_tRecords = {};
end

function onSortCompare(w1, w2)
	local tRecords = self.getAllRecords();
	return not ListManager.defaultSortFunc(tRecords[w1.getDatabaseNode()], tRecords[w2.getDatabaseNode()]);
end

function onModuleLoadAndUnload(sModule)
	local nodeRoot = DB.getRoot(sModule);
	if nodeRoot then
		local vNodes = RecordDataManager.getDataPaths(self.getRecordType());
		for i = 1, #vNodes do
			if DB.getChild(nodeRoot, vNodes[i]) then
				bDelayedRebuild = true;
				self.onListRecordsChanged(true);
				break;
			end
		end
	end
end
function addHandlers()
	local vNodes = RecordDataManager.getDataPaths(self.getRecordType());
	for i = 1, #vNodes do
		self.addHandlerHelper(vNodes[i]);
	end
end
function addHandlerHelper(vNode)
	local sPath = DB.getPath(vNode);
	local sChildPath = sPath .. ".*@*";
	DB.addHandler(sChildPath, "onAdd", self.onChildAdded);
	DB.addHandler(sChildPath, "onDelete", self.onChildDeleted);
	DB.addHandler(DB.getPath(sChildPath, "label"), "onUpdate", self.onChildNameChange);
	DB.addHandler(DB.getPath(sChildPath, "isgmonly"), "onUpdate", self.onChildGMOnlyChange);
end
function removeHandlers()
	local vNodes = RecordDataManager.getDataPaths(self.getRecordType());
	for i = 1, #vNodes do
		self.removeHandlerHelper(vNodes[i]);
	end
end
function removeHandlerHelper(vNode)
	local sPath = DB.getPath(vNode);
	local sChildPath = sPath .. ".*@*";
	DB.removeHandler(sChildPath, "onAdd", self.onChildAdded);
	DB.removeHandler(sChildPath, "onDelete", self.onChildDeleted);
	DB.removeHandler(DB.getPath(sChildPath, "label"), "onUpdate", self.onChildNameChange);
	DB.removeHandler(DB.getPath(sChildPath, "isgmonly"), "onUpdate", self.onChildGMOnlyChange);
end

function onChildAdded(vNode)
	self.addListRecord(vNode);
	self.onListRecordsChanged(true);
end
function onChildDeleted(vNode)
	local tRecords = self.getAllRecords();
	if tRecords[vNode] then
		tRecords[vNode] = nil;
		self.onListRecordsChanged(true);
	end
end
function onListChanged()
	if bDelayedChildrenChanged then
		self.onListRecordsChanged(false);
	end
end
function addListRecord(vNode)
	local rRecord = {};
	rRecord.vNode = vNode;
	rRecord.sDisplayName = DB.getValue(vNode, "label", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
	rRecord.nGMOnly = DB.getValue(vNode, "isgmonly", 0);

	self.getAllRecords()[vNode] = rRecord;
end
function onListRecordsChanged(bAllowDelay)
	if bAllowDelay then
		ListManager.helperSaveScrollPosition(self);
		bDelayedChildrenChanged = true;
		self.getListWindow().list.setDatabaseNode(nil);
	else
		bDelayedChildrenChanged = false;
		if bDelayedRebuild then
			bDelayedRebuild = false;
			self.rebuildList(true);
		end
		ListManager.refreshDisplayList(self);
	end
end
function rebuildList(bSkipRefresh)
	self.clearRecords();
	RecordManager.callForEachRecord(self.getRecordType(), self.addListRecord);

	ListManager.setDisplayOffset(self, 0, true);
	if not bSkipRefresh then
		self.onListRecordsChanged();
	end
end

function onFilterChanged()
	sFilter = Utility.convertStringToLower(WindowManager.getInnerControlValue(self, "filter"));
	ListManager.refreshDisplayList(self, true);
end
function onChildNameChange(vNameNode)
	local vNode = DB.getParent(vNameNode);
	local rRecord = self.getAllRecords()[vNode];
	rRecord.sDisplayName = DB.getValue(vNode, "label", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
	ListManager.refreshDisplayList(self);
end
function onChildGMOnlyChange(vNameNode)
	local vNode = DB.getParent(vNameNode);
	local rRecord = self.getAllRecords()[vNode];
	rRecord.nGMOnly = DB.getValue(vNode, "isgmonly", 0);
	ListManager.refreshDisplayList(self);
end

function isFilteredRecord(v)
	if sFilter ~= "" then
		if not string.find(v.sDisplayNameLower, sFilter, 0, true) then
			return false;
		end
	end
	if v.nGMOnly == 1 and not Session.IsHost then
		return false;
	end
	return true;
end
