--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals nohighlight

function onNavigateDown()
	local sName = getName();
	local winNext = window.windowlist.getNextWindow(window);
	if winNext and winNext[sName] then
		winNext[sName].setFocus();
		winNext[sName].setCursorPosition(1);
		winNext[sName].setSelectionPosition(1);
	end
	return winNext;
end
function onNavigateUp()
	local sName = getName();
	local winPrev = window.windowlist.getPrevWindow(window);
	if winPrev and winPrev[sName] then
		winPrev[sName].setFocus();
		winPrev[sName].setCursorPosition(#winPrev[sName].getValue()+1);
		winPrev[sName].setSelectionPosition(#winPrev[sName].getValue()+1);
	end
	return winPrev;
end

function onGainFocus()
	if nohighlight then
		return;
	end
	window.setFrame("rowshade");
end
function onLoseFocus()
	if nohighlight then
		return;
	end
	window.setFrame(nil);
end
