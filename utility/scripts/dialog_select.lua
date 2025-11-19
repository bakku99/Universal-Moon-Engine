--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _tQueue = {};
function getSelectionQueue()
	return _tQueue;
end

local _bUpdatingSelections = false;
function isUpdatingSelection()
	return _bUpdatingSelections;
end
function setUpdatingSelection(v)
	_bUpdatingSelections = v;
end

local _bFinalizingSelection = false;
function isFinalizingSelection()
	return _bFinalizingSelection;
end
function setFinalizingSelection(v)
	_bFinalizingSelection = v;
end

local _nMinSelections;
function getMinSelections()
	return _nMinSelections or 1;
end
function setMinSelections(v)
	_nMinSelections = v;
end

local _nMaxSelections;
function getMaxSelections()
	return _nMaxSelections or 0;
end
function setMaxSelections(v)
	_nMaxSelections = v;
end

function requestSelection(sTitle, sMsg, aSelections, fnCallback, vCustom, nMinimum, nMaximum, bFront)
	local tData = {
		title = sTitle,
		msg = sMsg,
		options = aSelections,
		min = nMinimum,
		max = nMaximum,
		callback = fnCallback,
		custom = vCustom,
	};
	self.requestSelectionByData(tData, bFront);
end
function requestSelectionByData(tData, bFront)
	if not tData then
		return;
	end
	local tQueue = self.getSelectionQueue();
	local nCurrentStack = #tQueue;

	if bFront then
		if self.isFinalizingSelection() or (#tQueue == 0) then
			table.insert(tQueue, 1, tData);
		else
			table.insert(tQueue, 2, tData);
		end
	else
		table.insert(tQueue, tData);
	end

	if nCurrentStack == 0 then
		self.activateNextSelection();
	end
end
function activateNextSelection()
	local tQueue = self.getSelectionQueue();
	if #tQueue <= 0 then
		close();
		return;
	end

	self.setUpdatingSelection(false);

	title.setValue(tQueue[1].title);
	text.setValue(tQueue[1].msg);

	list.closeAll();
	for _,v in ipairs(tQueue[1].options or {}) do
		if type(v) == "string" then
			self.createEntryFromText(tQueue[1], v);
		elseif type(v) == "table" then
			self.createEntryFromTable(tQueue[1], v);
		end
	end

	self.setMinSelections(tQueue[1].min);
	self.setMaxSelections(tQueue[1].max);

	self.setUpdatingSelection(true);
	self.onSelectionChanged();
end

function createEntryFromText(_, s)
	local w = list.createWindow();
	w.text.setValue(s);
end
function createEntryFromTable(tSelect, tData)
	local w = list.createWindow();
	w.text.setValue(tData.text);
	if tData.linkclass and tData.linkrecord then
		w.shortcut.setValue(tData.linkclass, tData.linkrecord);
		w.shortcut.setVisible(true);

		if tSelect.showmodule then
			local sLinkModule = StringManager.split(tData.linkrecord, "@")[2] or "";
			local sModule;
			if sLinkModule ~= "" then
				local tModuleInfo = Module.getModuleInfo(sLinkModule);
				sModule = tModuleInfo and tModuleInfo.displayname or Interface.getString("unknown");
			else
				sModule = Interface.getString("campaign");
			end
			w.module.setValue(sModule);

			w.module.setVisible(true);
		end
	end
	if tData.selected then
		w.selected.setValue(1);
	end
end

local _bSelectionProcessing = false;
function onSelectionChanged(wSelect)
	if not self.isUpdatingSelection() or _bSelectionProcessing then
		return;
	end
	_bSelectionProcessing = true;

	local nMin = self.getMinSelections();
	local nMax = self.getMaxSelections();

	local bClearOtherSelections = false;
	if wSelect and (nMin == 1) and (nMax <= 1) then
		bClearOtherSelections = true;
	end

	local nSelections = 0;
	for _,w in pairs(list.getWindows()) do
		if bClearOtherSelections and (w ~= wSelect) then
			w.selected.setValue(0);
		else
			if w.selected.getValue() == 1 then
				nSelections = nSelections + 1;
			end
		end
	end

	local nMin = self.getMinSelections();
	local nMax = self.getMaxSelections();
	if ((nMax <= 0) and (nSelections == nMin)) or ((nMax > 0) and (nSelections >= nMin) and (nSelections <= nMax)) then
		sub_buttons.subwindow.button_ok.setVisible(true);
	else
		sub_buttons.subwindow.button_ok.setVisible(false);
	end

	_bSelectionProcessing = false;
end

function processOK()
	local tQueue = self.getSelectionQueue();
	if #tQueue > 0 then
		self.setFinalizingSelection(true);

		local rSelect = tQueue[1];
		table.remove(tQueue, 1);

		if rSelect.callback then
			local aSelections = {};
			local aSelectionLinks = {};
			for _,w in pairs(list.getWindows()) do
				if w.selected.getValue() == 1 then
					table.insert(aSelections, w.text.getValue());
					local tLink = {};
					tLink.linkclass, tLink.linkrecord = w.shortcut.getValue();
					table.insert(aSelectionLinks, tLink);
				end
			end

			rSelect.callback(aSelections, rSelect.custom, aSelectionLinks);
		end

		self.setFinalizingSelection(false);
	end

	self.activateNextSelection();
end
function processCancel()
	close();
end
