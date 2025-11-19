--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

local _bInitialized = false;
local _bColorDialogShown = false;

function onClose()
	self.closeColorDialog();
end

function closeColorDialog()
	if _bColorDialogShown then
		Interface.dialogColorClose();
	end
end

local _sKey;
function getKey()
	return _sKey;
end
function setData(sKey)
	if not sKey then
		return;
	end
	_sKey = sKey;
	name.setValue(_sKey);

	self.updateDisplay();

	_bInitialized = true;
end

function updateDisplay()
	DiceSkinManager.setupCustomControl(custom, DiceRollManager.getActorCustomSkin(self.getKey()));
end

function delete()
	DiceRollManager.setActorCustom(self.getKey(), nil);
	close();
end

function onClickDown()
	return true;
end
function onClickRelease(_, x, y)
	local tDiceSkin = DiceRollManager.getActorCustomSkin(self.getKey());
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
	local tDiceSkin = DiceRollManager.getActorCustomSkin(self.getKey());
	if DiceSkinManager.isDiceSkinTintable(tDiceSkin) then
		tDiceSkin.dicebodycolor = sColor;
		DiceRollManager.setActorCustomSkin(self.getKey(), tDiceSkin);
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
	local tDiceSkin = DiceRollManager.getActorCustomSkin(self.getKey());
	if DiceSkinManager.isDiceSkinTintable(tDiceSkin) then
		tDiceSkin.dicetextcolor = sColor;
		DiceRollManager.setActorCustomSkin(self.getKey(), tDiceSkin);
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
	DiceRollManager.setActorCustomSkin(self.getKey(), tDiceSkin);
	self.updateDisplay();
	return true;
end
