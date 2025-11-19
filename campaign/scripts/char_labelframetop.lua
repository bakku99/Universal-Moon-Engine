--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals icons

function onInit()
	if icons and icons[1] then
		self.setIcon(icons[1]);
	end
end

function setIcon(sIcon)
	local wgt = findWidget("icon");
	if wgt then
		wgt.destroy();
	end

	if sIcon then
		widget = addBitmapWidget({ name="icon", icon = sIcon, position="topleft", x = 2, y = 8 });
	end
end
