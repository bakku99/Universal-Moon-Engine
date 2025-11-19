--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

function onInit()
	self.refresh();
end

function refresh()
	filter.setValue("");
end

function setFilterNameControl(s)
	self.refresh();
	filter.setValue(s);
end

function onFilterChanged()
	local tValuesLower = {};
	tValuesLower[""] = filter.getValue():lower();

	SoundManagerFile.onSettingsFilterChanged(tValuesLower);
end
