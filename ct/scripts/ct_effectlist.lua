--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("ct_menu_effectadd"), "pointer", 2);
end

function onMenuSelection(selection)
	if selection == 2 then
		createWindow(nil, true);
	end
end
function onEnter()
	createWindow(nil, true);
	return true;
end

function deleteChild(wChild)
	WindowManager.safeDelete(wChild);
end

function reset()
	for _,v in pairs(getWindows()) do
		WindowManager.safeDelete(v);
	end
end
