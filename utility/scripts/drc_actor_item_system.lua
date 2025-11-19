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

function setData(sKey)
	if not sKey then
		return;
	end
	_sKey = sKey;
	local v = DiceRollManager.getActorSystem(_sKey);
	data.setValue(v.sName);
	local tSplit = StringManager.splitByPattern(v.sName or "", "|", true);
	if #tSplit > 1 then
		name.setValue(tSplit[1] .. "*");
		name.setTooltipText(table.concat(tSplit, "\r"));
	else
		name.setValue(tSplit[1]);
	end
	_tDefaultSkin = DiceRollManager.getActorSystemDefaultSkin(_sKey);
	if DiceRollManager.getActorSystemSkipDefault(_sKey) then
		button_usedefault.setValue(0);
	else
		button_usedefault.setValue(1);
	end
	self.updateDisplay();
	self.updateDefaultDisplay();
	_bInitialized = true;
end

function updateDisplay()
	local tDiceSkin = DiceRollManager.getActorSystemSkin(_sKey);
	DiceSkinManager.setupCustomControl(custom, tDiceSkin);
	local bShowClear = (tDiceSkin ~= nil);
	button_custom_clear.setVisible(bShowClear);
end
function updateDefaultDisplay()
	local bShowDefault = (_tDefaultSkin ~= nil);
	default.setVisible(bShowDefault);
	button_usedefault.setVisible(bShowDefault);
	DiceSkinManager.setupCustomControl(default, _tDefaultSkin, DiceRollManager.getActorSystemSkipDefault(_sKey));
end

function onClickDown()
	return true;
end
function onClickRelease(_, x, y)
	local tDiceSkin = DiceRollManager.getActorSystemSkin(_sKey);
	if not DiceSkinManager.isDiceSkinTintable(tDiceSkin) then
		return;
	end
	local nWidgetSize = DiceSkinManager.WIDGET_SIZE;
	local nWidgetPadding = DiceSkinManager.WIDGET_PADDING;
	local nWidgetClick = nWidgetSize + nWidgetPadding;
	if x >= custom.getAnchoredWidth() - nWidgetClick then
		if y <= nWidgetClick then
			self.closeColorDialog();
			_bColorDialogShown = Interface.dialogColor(self.onBodyColorDialogCallback, tDiceSkin.dicebodycolor);
		elseif y <= (nWidgetClick + nWidgetSize) then
			self.closeColorDialog();
			_bColorDialogShown = Interface.dialogColor(self.onTextColorDialogCallback, tDiceSkin.dicetextcolor);
		end
	end
end
function onBodyColorDialogCallback(sResult, sColor)
	if #sColor > 6 then
		sColor = sColor:sub(-6);
	end
	local tDiceSkin = DiceRollManager.getActorSystemSkin(_sKey);
	if tDiceSkin then
		tDiceSkin.dicebodycolor = sColor;
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
	local tDiceSkin = DiceRollManager.getActorSystemSkin(_sKey);
	if tDiceSkin then
		tDiceSkin.dicetextcolor = sColor;
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
	DiceRollManager.setActorSystemSkin(_sKey, tDiceSkin);
	self.updateDisplay();
	return true;
end
function onCustomClear()
	if not _bInitialized then
		return;
	end
	DiceRollManager.setActorSystemSkin(_sKey, nil);
	self.updateDisplay();
end
function onUseDefaultChanged()
	if not _bInitialized then
		return;
	end
	DiceRollManager.setActorSystemSkipDefault(_sKey, (button_usedefault.getValue() == 0));
	self.updateDefaultDisplay();
end
