--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals DEFAULT_COLOR

DEFAULT_COLOR = "FFFFFFFF";
local _sCurrentColor = "";
local _bDialogShown = false;

function onInit()
	_sCurrentColor = DB.getValue(window.getDatabaseNode(), "color", DEFAULT_COLOR);
	self.onColorUpdate();
end
function onClose()
	if _bDialogShown then
		Interface.dialogColorClose();
	end
end

function onClickDown()
	return true;
end
function onClickRelease()
	if not _bDialogShown then
		_bDialogShown = Interface.dialogColor(self.colorDialogCallback, _sCurrentColor);
	end
end

function colorDialogCallback(sResult, sColor)
	if sResult == "ok" or sResult == "cancel" then
		_bDialogShown = false;
	end
	_sCurrentColor = sColor;
	if sResult == "ok" then
		DB.setValue(window.getDatabaseNode(), "color", "string", sColor);
	end
	self.onColorUpdate();
end
function onColorUpdate()
	setBackColor(_sCurrentColor);
end
