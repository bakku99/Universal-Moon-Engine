--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

slots = {};

local _cStack = nil;
local _bFreeAdj = 0;
local _bAdjEdit = false;
local _nHoverSlot = nil;

function onTabletopInit()
	Interface.addKeyedEventHandler("onHotkeyActivated", "number", ModifierStack.onHotkeyModifier);
end
function onHotkeyModifier(draginfo)
	ModifierStack.addSlot(draginfo.getDescription(), draginfo.getNumberData());
	return true;
end

function registerControl(c)
	_cStack = c;
end
function updateControl()
	if _cStack then
		if _bAdjEdit then
			if _cStack.label then
				_cStack.label.setValue(Interface.getString("modstack_label_adjusting"));
			end
		else
			if _cStack.label then
				_cStack.label.setValue(Interface.getString("modstack_label_modifier"));
				if _bFreeAdj > 0 then
					_cStack.label.setValue("(+" .. _bFreeAdj .. ")");
				elseif _bFreeAdj < 0 then
					_cStack.label.setValue("(" .. _bFreeAdj .. ")");
				end
			end

			if _cStack.modifier then
				_cStack.modifier.setValue(ModifierStack.getSum());
			end

			if _cStack.base then
				if _cStack.base.resetCounters and _cStack.base.addCounter then
					_cStack.base.resetCounters();
					for _ = 1, #ModifierStack.slots do
						_cStack.base.addCounter();
					end
				end
			end

			if _cStack.label then
				if ((_nHoverSlot or 0) ~= 0) and ModifierStack.slots[_nHoverSlot] then
					_cStack.label.setValue(ModifierStack.slots[_nHoverSlot].description);
				end
			end
		end

		if _cStack.modifier then
			if math.abs(_cStack.modifier.getValue()) > 999 then
				_cStack.modifier.setFont("modcollectorlabel");
			else
				_cStack.modifier.setFont("modcollector");
			end
		end
	end
end

function isEmpty()
	if (_bFreeAdj == 0) and (#ModifierStack.slots == 0) then
		return true;
	end

	return false;
end

function getSum()
	ModifierStack.clearFocus();

	local total = _bFreeAdj;

	for i = 1, #ModifierStack.slots do
		total = total + ModifierStack.slots[i].number;
	end

	return total;
end

function getDescription(forcebonus)
	local s;

	if not forcebonus and #ModifierStack.slots == 1 and _bFreeAdj == 0 then
		s = ModifierStack.slots[1].description;
	else
		local aMods = {};

		for i = 1, #ModifierStack.slots do
			table.insert(aMods, string.format("%s %+d", ModifierStack.slots[i].description, ModifierStack.slots[i].number));
		end

		if _bFreeAdj ~= 0 then
			table.insert(aMods, string.format("%+d", _bFreeAdj));
		end

		s = table.concat(aMods, ", ");
	end

	return s;
end

function addSlot(description, number)
	if #ModifierStack.slots < 6 then
		table.insert(ModifierStack.slots, { ['description'] = description, ['number'] = number });
	end

	ModifierStack.updateControl();
end
function removeSlot(number)
	table.remove(ModifierStack.slots, number);
	ModifierStack.updateControl();
end
function adjustFreeAdjustment(amount)
	_bFreeAdj = _bFreeAdj + amount;
	ModifierStack.updateControl();
end
function setFreeAdjustment(amount)
	_bFreeAdj = amount;
	ModifierStack.updateControl();
end
function setAdjustmentEdit(state)
	if _cStack and _cStack.modifier then
		if state then
			_cStack.modifier.setValue(_bFreeAdj);
		else
			ModifierStack.setFreeAdjustment(_cStack.modifier.getValue());
		end
	end

	_bAdjEdit = state;
	ModifierStack.updateControl();
end
function reset()
	ModifierStack.clearFocus();

	_bFreeAdj = 0;
	ModifierStack.slots = {};
	ModifierStack.updateControl();
end
function clearFocus()
	if _cStack and _cStack.modifier and _cStack.modifier.hasFocus() then
		_cStack.modifier.setFocus(false);
	end
end

function hoverDisplay(n)
	_nHoverSlot = n;
	ModifierStack.updateControl();
end

function getStack(forcebonus)
	ModifierStack.clearFocus();

	local sDesc = "";
	local nMod = 0;

	if not ModifierStack.isEmpty() then
		sDesc = ModifierStack.getDescription(forcebonus);
		nMod = ModifierStack.getSum();
	end

	if not ModifierManager.isLocked() then
		ModifierStack.reset();
	end

	return sDesc, nMod;
end

function getTargeting()
	if _cStack and _cStack.targeting then
		return (_cStack.targeting.getValue() == 1);
	end
	return true;
end

--
--  Preset handling
--

function lock()
	ModifierManager.lock();
end
function unlock(bReset)
	ModifierManager.unlock(bReset);
end
function getModifierKey(sButton)
	return ModifierManager.getKey(sButton);
end
function setModifierKey(sButton, bState, bUpdateWnd)
	ModifierManager.setKey(sButton, bState, bUpdateWnd);
end
