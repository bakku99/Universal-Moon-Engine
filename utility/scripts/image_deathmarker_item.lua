--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

function onInit()
	name.setValue(StringManager.capitalizeAll(id.getValue()));
	self.updateSetOptions();
end

function updateSetOptions(bCheckValue)
	local tSetNames = ImageDeathMarkerManager.getSetNames();

	if bCheckValue then
		local sOption = set.getValue();
		if (sOption ~= "") and not StringManager.contains(tSetNames, sOption) then
			set.setValue("");
		end
	end

	set.clear();
	set.addItems(tSetNames);
end
