--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if module then
		local tModuleInfo = Module.getModuleInfo(DB.getModule(getDatabaseNode()));
		if tModuleInfo then
			module.setVisible(true);
			module.setTooltipText(tModuleInfo.displayname);
			if spacer_module then
				spacer_module.setVisible(false);
			end
		end
	end
end

function actionDrag(draginfo)
	if not label.isEmpty() then
		draginfo.setType("number");
		draginfo.setDescription(label.getValue());
		draginfo.setStringData(label.getValue());
		draginfo.setNumberData(bonus.getValue());
	end
	return true;
end
function action()
	ModifierStack.addSlot(label.getValue(), bonus.getValue());
	return true;
end

function onDrop(x, y, draginfo)
	return windowlist.onDrop(x, y, draginfo);
end
