--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onValueChanged();
end

function onVisibilityChanged()
	WindowManager.onColumnControlVisibilityChanged(self);
end
function onValueChanged()
	setVisible(not isEmpty());
end

function update(...)
	if subwindow and subwindow.update then
		subwindow.update(...);
	end
end
