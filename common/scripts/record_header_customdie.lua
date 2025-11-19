--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("clear"), "erase", 4);
	DB.addHandler(DB.getPath(window.getDatabaseNode(), "customdie"), "onUpdate", self.onValueChanged);
	self.onValueChanged();
end
function onClose()
	DB.removeHandler(DB.getPath(window.getDatabaseNode(), "customdie"), "onUpdate", self.onValueChanged);
end

function onMenuSelection(selection)
	if selection == 4 then
		DB.setValue(window.getDatabaseNode(), "customdie", "string", "");
	end
end

function onValueChanged()
	local sDiceSkin = DB.getValue(window.getDatabaseNode(), "customdie", "");
	local tDiceSkin = DiceSkinManager.convertStringToTable(sDiceSkin);
	DiceSkinManager.setupCustomControl(self, tDiceSkin);

	if window.onCustomDieChanged then
		window.onCustomDieChanged();
	elseif window.update then
		window.update();
	end
end
