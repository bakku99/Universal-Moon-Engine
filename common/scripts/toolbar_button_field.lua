--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals initbyname

local _nodeSrc;

function onInit()
	if initbyname then
		ToolbarManager.initButton(self, getName());
	end
end
function onClose()
	if _nodeSrc then
		DB.removeHandler(_nodeSrc, "onChildDeleted", self.onDelete);
		local sPath = DB.getPath(_nodeSrc, getName());
		DB.removeHandler(sPath, "onAdd", self.onUpdate);
		DB.removeHandler(sPath, "onUpdate", self.onUpdate);
	end
end

function init()
	self.setDefault(ToolbarManager.onButtonGetDefault(self));

	_nodeSrc = window.getDatabaseNode();
	if _nodeSrc then
		self.onUpdate();

		DB.addHandler(_nodeSrc, "onChildDeleted", self.onDelete);
		local sPath = DB.getPath(_nodeSrc, getName());
		DB.addHandler(sPath, "onAdd", self.onUpdate);
		DB.addHandler(sPath, "onUpdate", self.onUpdate);
	end

	self.onUpdate();
	self.setInitialized(true);
end

function onDelete(_, sChild)
	if getName() == sChild then
		self.onUpdate();
		self.notify();

		-- Re-add specific handlers, since specific handlers get cleared on specific node deletion
		local sPath = DB.getPath(_nodeSrc, getName());
		DB.addHandler(sPath, "onAdd", self.onUpdate);
		DB.addHandler(sPath, "onUpdate", self.onUpdate);
	end
end

local _bUpdating = false;
function onUpdate()
	if _bUpdating then
		return;
	end

	_bUpdating = true;
	local nValue = DB.getValue(_nodeSrc, getName(), self.getDefault());
	if nValue == 0 then
		setValue(0);
	else
		setValue(1);
	end
	_bUpdating = false;
end
function onValueChanged()
	if not _bUpdating then
		_bUpdating = true;
		if _nodeSrc then
			DB.setValue(_nodeSrc, getName(), "number", getValue());
		end
		_bUpdating = false;
	end

	self.notify();
end
function notify()
	if self.isInitialized() then
		ToolbarManager.onButtonValueChanged(self);
	end
end

local _bInit = false;
function setInitialized(bValue)
	_bInit = bValue;
end
function isInitialized()
	return _bInit;
end

local _nDefault = 0;
function setDefault(n)
	_nDefault = n;
end
function getDefault()
	return _nDefault;
end

function setValueNoEvent(n)
	local bValue = self.isInitialized();
	self.setInitialized(false);
	setValue(n);
	self.setInitialized(bValue);
end
