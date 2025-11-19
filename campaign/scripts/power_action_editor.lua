--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onTypeChanged();
end

function onTypeChanged()
	local cMain = content or main;
	local sType = type.getValue();
	if sType ~= "" then
		local node = getDatabaseNode();

		title.setValue(Interface.getString("power_title_" .. sType));
		cMain.setValue("power_action_editor_" .. sType, node);

		if cMain.subwindow and cMain.subwindow.name then
			cMain.subwindow.name.setValue(DB.getValue(node, "...name", ""));
		end
	else
		title.setValue("");
		cMain.setValue("", "");
	end
	cMain.setVisible(true);
end

function getWindowMenuHelpLink()
	local sType = type.getValue();
	local sHelpURL = Interface.getString("help_action_" .. sType);
	if (sHelpURL or "") ~= "" then
		return sHelpURL;
	end
end
