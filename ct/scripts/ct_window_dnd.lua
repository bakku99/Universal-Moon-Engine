--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("WNDC", self.onHealthChanged);
	self.onHealthChanged();
end
function onClose()
	OptionsManager.unregisterCallback("WNDC", self.onHealthChanged);
end

function onHealthChanged()
	for _,w in pairs(list.getWindows()) do
		w.onHealthChanged();
	end
end
