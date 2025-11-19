--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onPostInitialize(_, tCustom)
	if tCustom then
		value.setMinValue(tCustom.min);
		value.setMaxValue(tCustom.max);
	end
end

function setReadOnly(bValue)
	super.setReadOnly(bValue);

	value.setReadOnly(bValue);
end

function getDisplayValue()
	return self.getOptionValue();
end
function getOptionValue()
	return tostring(value.getValue());
end
function onSetOptionValue(s)
	value.setValue(tonumber(s) or 0);
end
