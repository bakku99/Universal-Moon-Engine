--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	UI DISPLAY
--

function refreshDisplay()
	local tItem = self.getItemDataByValue(self.getValue());
	setIcon(tItem and tItem.sIcon or "");
	setTooltipText(tItem and tItem.sTooltip or "");
end

--
--	UI BEHAVIORS
--

function onClickDown()
	return true;
end
function onClickRelease()
	if not isReadOnly() then
		self.cycleValue(Input.isControlPressed());
	end
	return true;
end

--
--	BACKWARD COMPATIBILITY
--

function addState(sIcon, sValue, sTooltip)
	self.addItem({ sValue = sValue, sIcon = sIcon, sTooltip = sTooltip, });
end

function getStringValue()
	return self.getValue();
end
function setStringValue(s)
	self.setValue(s);
end

function cycleIcon(bBackward)
	self.cycleValue(bBackward);
end
