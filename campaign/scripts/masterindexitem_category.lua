--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onHover(bHover)
	setUnderline(bHover, -1);
end
function onClickDown()
	return true;
end
function onClickRelease()
	local sValue = getValue();
	if sValue ~= "" then
		WindowManager.callOuterWindowFunction(window, "handleCategorySelect", sValue);
	end
	return true;
end
