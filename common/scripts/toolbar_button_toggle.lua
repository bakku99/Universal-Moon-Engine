--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals initbyname

local _bInit = false;

function onInit()
	if initbyname then
		ToolbarManager.initButton(self, getName());
	end
end

function init()
	self.setValue(ToolbarManager.onButtonGetDefault(self));
	_bInit = true;
end
function reinit()
	if _bInit then
		self.setValueNoEvent(ToolbarManager.onButtonGetDefault(self));
	end
end
function setValueNoEvent(n)
	_bInit = false;
	setValue(n);
	_bInit = true;
end

function onValueChanged()
	if _bInit then
		ToolbarManager.onButtonValueChanged(self);
	end
end
