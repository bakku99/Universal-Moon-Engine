--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

local _bInitialized = false;
local _bColorDialogShown = false;

local _sDiceSkinKey
local _sMode;

function onClose()
	self.closeColorDialog();
end

function closeColorDialog()
	if _bColorDialogShown then
		Interface.dialogColorClose();
	end
end

function setData(sKey, sMode)
	_sDiceSkinKey = sKey;
	_sMode = sMode;

	local sName = Interface.getString("drc_label_mode_" .. _sMode);
	if (sName or "") == "" then
		sName = _sMode;
	end
	name.setValue(sName);

	self.updateDisplay();

	_bInitialized = true;
end

function updateDisplay()
	local tDiceSkin = DiceRollManager.getActionModeSkin(_sDiceSkinKey, _sMode);
	DiceSkinManager.setupCustomControl(custom, tDiceSkin);

	local bShowClear = (tDiceSkin ~= nil);
	button_custom_clear.setVisible(bShowClear);
end

function onClickDown()
	return true;
end
function onClickRelease(_, x, y)
	local tCustomColor = DiceRollManager.getActionModeSkin(_sDiceSkinKey, _sMode);
	if not DiceSkinManager.isDiceSkinTintable(tCustomColor) then
		return;
	end

	local nWidgetSize = DiceSkinManager.WIDGET_SIZE;
	local nWidgetPadding = DiceSkinManager.WIDGET_PADDING;
	local nWidgetClick = nWidgetSize + nWidgetPadding;
	if x >= custom.getAnchoredWidth() - nWidgetClick then
		if y <= nWidgetClick then
			self.closeColorDialog();
			_bColorDialogShown = Interface.dialogColor(self.onBodyColorDialogCallback, tCustomColor.dicebodycolor);
		elseif y <= (nWidgetClick + nWidgetSize) then
			self.closeColorDialog();
			_bColorDialogShown = Interface.dialogColor(self.onTextColorDialogCallback, tCustomColor.dicetextcolor);
		end
	end
end
function onBodyColorDialogCallback(sResult, sColor)
	if #sColor > 6 then
		sColor = sColor:sub(-6);
	end
	local tCustomColor = DiceRollManager.getActionModeSkin(_sDiceSkinKey, _sMode);
	if tCustomColor then
		tCustomColor.dicebodycolor = sColor;
		self.updateDisplay();
	end
	if sResult == "ok" or sResult == "cancel" then
		_bColorDialogShown = false;
	end
end
function onTextColorDialogCallback(sResult, sColor)
	if #sColor > 6 then
		sColor = sColor:sub(-6);
	end
	local tCustomColor = DiceRollManager.getActionModeSkin(_sDiceSkinKey, _sMode);
	if tCustomColor then
		tCustomColor.dicetextcolor = sColor;
		self.updateDisplay();
	end
	if sResult == "ok" or sResult == "cancel" then
		_bColorDialogShown = false;
	end
end
function onDrop(_, _, draginfo)
	if not _bInitialized then
		return false;
	end
	if not draginfo.isType("diceskin") then
		return false;
	end

	local tDiceSkin = UserManager.convertDiceSkinStringToTable(draginfo.getStringData());
	DiceRollManager.setActionModeSkin(_sDiceSkinKey, _sMode, tDiceSkin);
	self.updateDisplay();
	return true;
end
function onCustomClear()
	if not _bInitialized then
		return;
	end

	DiceRollManager.setActionModeSkin(_sDiceSkinKey, _sMode, nil);
	self.updateDisplay();
end
