--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.populate();
	WindowManager.updateTooltip(self);
	self.onStateChanged();
end

function populate()
	if header then
		local sHeaderClass = header.getValue();
		if sHeaderClass == "" or sHeaderClass == "record_header" then
			local sDefaultClass = string.format("%s_header", getClass());
			if Interface.isWindowClass(sDefaultClass) then
				header.setValue(sDefaultClass, getDatabaseNode());
			end
		end
	end
	if content then
		local sContentClass = content.getValue();
		if sContentClass == "" then
			local sDefaultClass = string.format("%s_main", getClass());
			if Interface.isWindowClass(sDefaultClass) then
				content.setValue(sDefaultClass, getDatabaseNode());
			end
		end
	end
end

function onLockModeChanged()
	self.onLockChanged();
end
function onIDModeChanged()
	self.onIDChanged();
end
function onNameUpdated()
	WindowManager.updateTooltip(self);
end

function onLockChanged()
	self.onStateChanged();
end
function onIDChanged()
	WindowManager.updateTooltip(self);
	self.onStateChanged();
end

function onStateChanged()
	if header and header.subwindow and header.subwindow.update then
		header.subwindow.update();
	end
	if content and content.subwindow and content.subwindow.update then
		content.subwindow.update();
	elseif main and main.subwindow and main.subwindow.update then
		main.subwindow.update();
	end

	if text then
		WindowManager.callSafeControlsSetLockMode(self, { "text", }, WindowManager.getReadOnlyState(getDatabaseNode()));
	elseif notes then
		WindowManager.callSafeControlsSetLockMode(self, { "notes", }, WindowManager.getReadOnlyState(getDatabaseNode()));
	elseif description then
		WindowManager.callSafeControlsSetLockMode(self, { "description", }, WindowManager.getReadOnlyState(getDatabaseNode()));
	end
end
