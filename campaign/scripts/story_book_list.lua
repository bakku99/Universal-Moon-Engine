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

local _tRecords = {};
function getAllRecords()
	return _tRecords;
end
function clearRecords()
	_tRecords = {};
end

function addHandlers()
	Module.addEventHandler("onModuleLoad", self.onModuleLoad);
	Module.addEventHandler("onModuleUnload", self.onModuleUnload);
end
function removeHandlers()
	Module.removeEventHandler("onModuleLoad", self.onModuleLoad);
	Module.removeEventHandler("onModuleUnload", self.onModuleUnload);
end
function onModuleLoad()
	self.rebuildList();
end
function onModuleUnload()
	self.rebuildList();
end

function rebuildList()
	self.clearRecords();
	for _,node in ipairs(StoryIndexManager.getAllBookIndexNodes()) do
		self.addListRecord(node);
	end

	ListManager.setDisplayOffset(self, 0, true);
	ListManager.refreshDisplayList(self);
end
function addListRecord(node)
	local rRecord = {};
	rRecord.node = node;
	local sModule = DB.getModule(node);
	if (sModule or "") == "" then
		rRecord.sDisplayName = string.format("(%s)", Interface.getString("campaign"));
	else
		local tModuleInfo = Module.getModuleInfo(sModule);
		if tModuleInfo then
			rRecord.sDisplayName = tModuleInfo.displayname;
		else
			rRecord.sDisplayName = sModule;
		end
	end
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();

	self.getAllRecords()[node] = rRecord;
end
function addDisplayListItem(v)
	local wItem = list.createWindow();
	wItem.setData(v);
end
function getItemDisplayName(node)
	local t = self.getAllRecords()[node];
	return (t and t.sDisplayName) or "";
end

function onFilterChanged()
	ListManager.onFilterChanged(self, filter.getValue());
end
