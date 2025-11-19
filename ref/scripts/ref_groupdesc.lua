--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals target

local aLinkedControls = {};

function onInit()
	if target then
		for sWord in string.gmatch(target[1], "(%w+)") do
			table.insert(aLinkedControls, sWord);
		end
	else
		table.insert(aLinkedControls, "list");
	end
end

function onClickDown()
	return true;
end
function onClickRelease()
	for _,v in ipairs(aLinkedControls) do
		window[v].setVisible(not window[v].isVisible());
	end
	return true;
end
