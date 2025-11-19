--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onValueChanged()
	self.updateFrame();

	if WindowManager.hasOuterWindowFunction(window, "onFilterChanged") then
		WindowManager.callOuterWindowFunction(window, "onFilterChanged");
	elseif window.list then
		window.list.applyFilter();
	end
end

function updateFrame()
	if isEmpty() then
		setFrame("search", 22,5,5,5);
	else
		setFrame("search_active", 22,5,5,5);
	end
end

function onGainFocus()
	self.selectAll();
end
function onLoseFocus()
	self.clearSelection();
end
function onEnter()
	self.selectAll();
	return true;
end
function onClickDown(button)
	if button == 2 then
		return true;
	end
end
function onClickRelease(button)
	if button == 2 then
		setValue("");
		return true;
	end
end

function selectAll()
	setCursorPosition(#getValue()+1);
	setSelectionPosition(1);
end
function clearSelection()
	setCursorPosition(1);
	setSelectionPosition(1);
end
