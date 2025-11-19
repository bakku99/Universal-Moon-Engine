--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals textres tooltip

local _sKey = nil;

function onClose()
	self.clearData();
end

function getData()
	return _sKey;
end
function setData(sKey)
	self.clearData();

	if not text and not textres then
		setStateText(0, Interface.getString("modifier_label_" .. sKey));
	end
	if not tooltip then
		local sTooltip = Interface.getString("modifier_tooltip_" .. sKey);
		if (sTooltip or "") ~= "" then
			setStateTooltipText(0, sTooltip);
		end
	end
	if ModifierManager.getRawKey(sKey) then
		setValue(1);
	end
	_sKey = sKey;

	self.addCallback();
end
function clearData()
	if _sKey then
		self.removeCallback();
		_sKey = nil;
	end
end

function addCallback()
	if _sKey then
		ModifierManager.registerKeyCallback(_sKey, self.onPresetChanged);
	end
end
function removeCallback()
	if _sKey then
		ModifierManager.unregisterKeyCallback(_sKey, self.onPresetChanged);
	end
end

local _bCallbackChangeLock = false;
function onPresetChanged()
	if _bCallbackChangeLock then
		return;
	end
	_bCallbackChangeLock = true;
	if ModifierManager.getRawKey(_sKey) then
		setValue(1);
	else
		setValue(0);
	end
	_bCallbackChangeLock = false;
end

function onButtonPress()
	if _bCallbackChangeLock then
		return;
	end
	_bCallbackChangeLock = true;
	if _sKey then
		if getValue() > 0 then
			ModifierManager.setKey(_sKey, true);
		else
			ModifierManager.setKey(_sKey, false);
		end
	end
	_bCallbackChangeLock = false;
end
function onDragStart(_, _, _, draginfo)
	if _sKey then
		local sDesc = string.format("%s [%s]", Interface.getString("modifier_label_" .. _sKey), Interface.getString("modifierkey_label_toggle"));
		draginfo.setType(ModifierManager.DRAGTYPE_MODIFIERKEY);
		draginfo.setDescription(sDesc);
		draginfo.setMetaData("sKey", _sKey);
		return true;
	end
end
