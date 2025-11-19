--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onClose()
	local sKey = self.getKey();
	if sKey then
		OptionsManager.unregisterCallback(sKey, self.onOptionChanged);
	end
end

function initialize(sKey, tCustom)
	self.setKey(sKey);

	if sKey then
		if self.onPreInitialize then
			self.onPreInitialize(sKey, tCustom);
		end
		self.setOptionValue(OptionsManager.getOption(sKey));
		OptionsManager.registerCallback(sKey, self.onOptionChanged);
		if self.onPostInitialize then
			self.onPostInitialize(sKey, tCustom);
		end
	end
end

function onOptionChanged()
	local sKey = self.getKey();
	if sKey then
		self.setOptionValue(OptionsManager.getOption(sKey));
	end
end

local _sKey = nil;
function getKey()
	return _sKey;
end
function setKey(s)
	_sKey = s;
end

function getLabel()
	return label.getValue();
end
function setLabel(sLabel)
	label.setValue(sLabel);
end

local _bReadOnly = false;
function isReadOnly()
	return _bReadOnly;
end
function setReadOnly(bReadOnly)
	_bReadOnly = bReadOnly;
	icon.setVisible(not bReadOnly);
end

function onHover(bOnWindow)
	if bOnWindow then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end

local _bUpdating = false;
function isUpdating()
	return _bUpdating;
end
function setUpdating(bState)
	_bUpdating = bState;
end

function getDisplayValue()
	return "";
end
function getOptionValue()
	return "";
end
function setOptionValue(v)
	if self.isUpdating() then
		return;
	end
	self.setUpdating(true);

	if self.onSetOptionValue then
		self.onSetOptionValue(v);
	end

	self.setUpdating(false);
end
function onValueChanged()
	if self.isUpdating() then
		return;
	end
	local sKey = self.getKey();
	if sKey then
		OptionsManager.setOption(sKey, self.getOptionValue());
	end
end

function onDragStart(draginfo)
	if self.isReadOnly() then
		return false;
	end

	local sKey = self.getKey();
	if sKey then
		draginfo.setType("string");
		draginfo.setIcon("action_option");
		draginfo.setDescription(string.format("%s = %s", self.getLabel(), self.getDisplayValue()));
		draginfo.setStringData(string.format("/option %s %s", sKey, self.getOptionValue()));
		return true;
	end
end
