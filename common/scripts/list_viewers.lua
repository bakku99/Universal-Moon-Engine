--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals portraitset portraitspacing

local widgets = {};

function onInit()
	if Session.IsHost then
		window.onViewersChanged = self.updateDisplay;
		self.updateDisplay();
	else
		setVisible(false);
	end
end

function updateDisplay()
	for _,v in ipairs(widgets) do
		v.destroy();
	end
	widgets = {};

	local holders = window.getViewers();
	local p = 1;

	local nPortraitSize = tonumber(portraitspacing[1]) or 22;
	setAnchoredWidth(#holders * nPortraitSize);
	setAnchoredHeight(nPortraitSize);

	for i = 1, #holders do
		local identity = User.getCurrentIdentity(holders[i]);

		if identity then
			local sIcon = "portrait_" .. identity .. "_" .. portraitset[1];
			widgets[i] = addBitmapWidget({ icon = sIcon, position="left", x = nPortraitSize * (p-0.5), w = nPortraitSize, h = nPortraitSize });

			p = p + 1;
		end
	end
end
