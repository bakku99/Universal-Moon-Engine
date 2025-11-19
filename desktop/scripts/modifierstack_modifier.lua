--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onValueChanged()
	if hasFocus() and ModifierStack.adjustmentedit then
		ModifierStack.setFreeAdjustment(getValue());
	end
end
function onGainFocus()
	ModifierStack.setAdjustmentEdit(true);
end

function onLoseFocus()
	ModifierStack.setAdjustmentEdit(false);
end

function onWheel(notches)
	if not hasFocus() then
		ModifierStack.adjustFreeAdjustment(notches);
	end

	return true;
end
function onClickDown(button, _, _)
	if button == 2 then
		ModifierStack.reset();
		return true;
	end
end
function onDragStart(_, _, _, draginfo)
	draginfo.setType("number");
	draginfo.setDescription(ModifierStack.getDescription());
	draginfo.setNumberData(ModifierStack.getSum());
	return true;
end
function onDragEnd()
	ModifierStack.reset();
end
function onDrop(x, y, draginfo)
	return window.base.onDrop(x, y, draginfo);
end
