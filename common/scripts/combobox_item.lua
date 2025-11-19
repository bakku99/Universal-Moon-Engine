--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.refreshDisplay();
end

local _sFont = "";
local _sSelectedFont = "";
local _sFrame = "";
local _sSelectedFrame = "";
function setFonts(sNormal, sSelection)
	_sFont = sNormal or "";
	_sSelectedFont = sSelection or "";
	self.refreshDisplay();
end
function setFrames(sNormal, sSelection)
	_sFrame = sNormal or "";
	_sSelectedFrame = sSelection or "";
	self.refreshDisplay();
end
function refreshDisplay()
	if self.isSelected() then
		setFrame(_sSelectedFrame);
		Text.setFont(_sSelectedFont);
	else
		setFrame(_sFrame);
		Text.setFont(_sFont);
	end
end

local _bSelected = false;
function isSelected()
	return _bSelected;
end
function setSelected(bState)
	if bState then
		_bSelected = true;
	else
		_bSelected = false;
	end
	self.refreshDisplay();
end

function onClicked()
	windowlist.onOptionClicked(self);
end
function delete()
	windowlist.onOptionDelete(self);
end
