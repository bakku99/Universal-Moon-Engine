--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	PARAMETERS
--

local _sTarget = "";
function setTarget(sTarget)
	_sTarget = sTarget or "";
end
function getTarget()
	return _sTarget;
end

local _sFont = "";
local _sSelectedFont = "";
local _sFrame = "";
local _sSelectedFrame = "";
function getFonts()
	return _sFont, _sSelectedFont;
end
function setFonts(sNormal, sSelection)
	_sFont = sNormal or "";
	_sSelectedFont = sSelection or "";
	for _,w in ipairs(getWindows()) do
		w.setFonts(_sFont, _sSelectedFont);
	end
end
function getFrames()
	return _sFrame, _sSelectedFrame;
end
function setFrames(sNormal, sSelection)
	_sFrame = sNormal or "";
	_sSelectedFrame = sSelection or "";

	for _,w in ipairs(getWindows()) do
		w.setFrames(_sFrame, _sSelectedFrame);
	end
end

local _nDisplayRows = 0;
local _nMaxRows = 0;
local _nRowHeight = 20;
function getDisplayRows()
	return _nDisplayRows;
end
function setDisplayRows(n)
	_nDisplayRows = n or 0;
	setAnchoredHeight(_nDisplayRows * _nRowHeight);
end
function getMaxRows()
	return _nMaxRows;
end
function setMaxRows(nNewMaxRows)
	_nMaxRows = nNewMaxRows;
	self.adjustHeight();
end
function adjustHeight()
	local nNewDisplayRows = getWindowCount();
	local nMaxRows = self.getMaxRows();
	if nMaxRows > 0 then
		nNewDisplayRows = math.min(nMaxRows, nNewDisplayRows);
	end
	local nCurrDisplayRows = self.getDisplayRows();
	if nNewDisplayRows ~= nCurrDisplayRows then
		self.setDisplayRows(nNewDisplayRows);
	end
end

--
--	DATA
--

function clear()
	closeAll();
end
function addItem(tItem)
	if not tItem then
		return;
	end

	local w = createWindow();
	w.setFonts(self.getFonts());
	w.setFrames(self.getFrames());
	w.Text.setValue(tItem.sText or "");
	w.Value.setValue(tItem.sValue or "");
	w.Order.setValue(getWindowCount() + 1);
	if tItem.bAllowDelete then
		w.idelete.setVisible(true);
	end
	self.adjustHeight();
end

function setSelectionValue(sValue)
	for _,w in ipairs(getWindows()) do
		if w.Value.getValue() == sValue then
			w.setSelected(true);
		else
			w.setSelected(false);
		end
	end
	self.scrollToSelected();
end

--
--	UI
--

function scrollToSelected()
	for _,w in ipairs(getWindows()) do
		if w.isSelected() then
			scrollToWindow(w);
			break;
		end
	end
end

--
--	UI EVENTS
--

function onLoseFocus()
	for _,w in ipairs(getWindows()) do
		for _,c in ipairs(w.getControls()) do
			if c.hasFocus() then
				setFocus(true);
				return;
			end
		end
	end
	window[self.getTarget()].hideList();
end
function onVisibilityChanged()
	if not isVisible() then
		for _,w in ipairs(getWindows()) do
			w.idelete.setValue(0);
		end
	end
end

function onOptionClicked(opt)
	window[self.getTarget()].onOptionClicked(opt);
end
function onOptionDelete(opt)
	window[self.getTarget()].onOptionDelete(opt);
end
