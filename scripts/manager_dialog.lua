--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function openDialog(sDialogClass, tData)
	if not DialogManager.isDialogClass(sDialogClass) then
		DialogManager.addDialogClass(sDialogClass);
	end
	DialogManager.helperAddPendingDialog(sDialogClass, tData);
	DialogManager.helperOpenPendingDialog(sDialogClass);
end
function onDialogClose(sResult, tData)
	if tData and tData.fnCallback then
		tData.fnCallback(sResult, tData);
	end
end
function onWindowClosed(sClass)
	DialogManager.helperOpenPendingDialog(sClass);
end

local _tDialogClasses = {};
function isDialogClass(s)
	return _tDialogClasses[s];
end
function addDialogClass(s)
	if DialogManager.isDialogClass(s) then
		return;
	end
	_tDialogClasses[s] = true;
	Interface.addKeyedEventHandler("onWindowClosed", s, DialogManager.onWindowClosed);
end

local _tPending = {};
function helperAddPendingDialog(sDialogClass, tData)
	_tPending[sDialogClass] = _tPending[sDialogClass] or {};
	table.insert(_tPending[sDialogClass], tData);
end
function helperOpenPendingDialog(sDialogClass)
	local w = Interface.findWindow(sDialogClass, "");
	if w then
		w.bringToFront();
	else
		local tData = DialogManager.helperGetPendingDialog(sDialogClass);
		if tData then
			w = Interface.openWindow(sDialogClass, "");
			w.setData(tData);
		end
	end
end
function helperGetPendingDialog(sDialogClass)
	if not _tPending[sDialogClass] then
		return nil;
	end
	if #(_tPending[sDialogClass]) == 0 then
		return nil;
	end
	local t = _tPending[sDialogClass][1];
	table.remove(_tPending[sDialogClass], 1);
	return t;
end

function requestSelectionDialog(tData, bFront)
	if not tData then
		return;
	end
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData, bFront);
end
