--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

local _bInitialized = false;
local _bColorDialogShown = false;
local _sKey;
local _tDefaultSkin = nil;

function onClose()
	self.closeColorDialog();
end

function closeColorDialog()
	if _bColorDialogShown then
		Interface.dialogColorClose();
	end
end

function setData(sKey, tData)
	if not sKey or not tData then
		return;
	end
	_sKey = sKey;
	_tDefaultSkin = DiceRollManager.resolveActionDefault(_sKey);
	local sName = Interface.getString("drc_label_type_" .. _sKey);
	if (sName or "") == "" then
		local sTypeRef, sSubtypeRef = _sKey:match("^(%w+)%-type%-(.+)$");
		if sTypeRef and sSubtypeRef then
			local sType = Interface.getString("drc_label_type_" .. sTypeRef);
			local sSubtype = Interface.getString("drc_label_subtype_" .. sSubtypeRef);
			if (sSubtype or "") == "" then
				sSubtype = StringManager.capitalize(sSubtypeRef);
			end
			sName = string.format("%s: %s", sType, sSubtype);
		end
	end
	if (sName or "") == "" then
		sName = _sKey;
	end
	name.setValue(sName);
	if DiceRollManager.getActionSkipDefault(_sKey) then
		button_usedefault.setValue(0);
	else
		button_usedefault.setValue(1);
	end
	self.updateDisplay();
	self.updateDefaultDisplay();
	self.updateModesDisplay();
	_bInitialized = true;
end

function updateDisplay()
	local tDiceSkin = DiceRollManager.getActionSkin(_sKey);
	DiceSkinManager.setupCustomControl(custom, tDiceSkin);
	local bShowClear = (tDiceSkin ~= nil);
	button_custom_clear.setVisible(bShowClear);
end
function updateDefaultDisplay()
	local bShowDefault = (_tDefaultSkin ~= nil);
	default.setVisible(bShowDefault);
	button_usedefault.setVisible(bShowDefault);
	DiceSkinManager.setupCustomControl(default, _tDefaultSkin, DiceRollManager.getActionSkipDefault(_sKey));
end
function updateModesDisplay()
	list_modes.closeAll();
	local tAllowedModes = DiceRollManager.getActionAllowedModes(_sKey);
	local bAvailable = (#(tAllowedModes or {}) > 0);
	button_modes_toggle.setVisible(bAvailable);
	local bShow = false;
	if bAvailable then
		bShow = (button_modes_toggle.getValue() == 1);
		if bShow then
			for _,sMode in ipairs(tAllowedModes) do
				local wMode = list_modes.createWindow();
				wMode.setData(_sKey, sMode);
			end
		end
	end
	list_modes.setVisible(bShow);
end

function onClickDown()
	return true;
end
function onClickRelease(_, x, y)
	local tCustomColor = DiceRollManager.getActionSkin(_sKey);
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
	local tCustomColor = DiceRollManager.getActionSkin(_sKey);
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
	local tCustomColor = DiceRollManager.getActionSkin(_sKey);
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
	DiceRollManager.setActionSkin(_sKey, tDiceSkin);
	self.updateDisplay();
	return true;
end

function onCustomClear()
	if not _bInitialized then
		return;
	end
	DiceRollManager.setActionSkin(_sKey, nil);
	self.updateDisplay();
end
function onUseDefaultChanged()
	if not _bInitialized then
		return;
	end
	DiceRollManager.setActionSkipDefault(_sKey, (button_usedefault.getValue() == 0));
	self.updateDisplay();
	self.updateDefaultDisplay();
end
