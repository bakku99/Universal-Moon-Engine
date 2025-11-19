--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _nodeSrc = nil;
local _nDefault = 0;

function onInit()
	Debug.console("button_record_locked - DEPRECATED - 2024-03-05");
	if super and super.onInit then
		super.onInit();
	end

	_nodeSrc = window.getDatabaseNode();
	if (DB.getModule(_nodeSrc) or "") ~= "" then
		_nDefault = 1;
	end

	if _nodeSrc and not DB.isReadOnly(_nodeSrc) then
		self.onUpdate();
		DB.addHandler(_nodeSrc, "onChildDeleted", self.onDelete);
		local sPath = DB.getPath(_nodeSrc, "locked");
		DB.addHandler(sPath, "onAdd", self.onUpdate);
		DB.addHandler(sPath, "onUpdate", self.onUpdate);
	else
		_nodeSrc = nil;
		setVisible(false);
	end

	self.notify();
end
function onClose()
	if _nodeSrc then
		DB.removeHandler(_nodeSrc, "onChildDeleted", self.onDelete);
		local sPath = DB.getPath(_nodeSrc, "locked");
		DB.removeHandler(sPath, "onAdd", self.onUpdate);
		DB.removeHandler(sPath, "onUpdate", self.onUpdate);
	end
end

local _bUpdating = false;
function onDelete(_, sChild)
	if sChild == "locked" then
		self.onUpdate();
		self.notify();

		-- Re-add specific handlers, since specific handlers get cleared on specific node deletion
		local sPath = DB.getPath(_nodeSrc, "locked");
		DB.addHandler(sPath, "onAdd", self.onUpdate);
		DB.addHandler(sPath, "onUpdate", self.onUpdate);
	end
end
function onUpdate()
	if _bUpdating then
		return;
	end

	_bUpdating = true;
	local nValue = DB.getValue(_nodeSrc, "locked", _nDefault);
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
			DB.setValue(_nodeSrc, "locked", "number", getValue());
		end
		_bUpdating = false;
	end

	self.notify();
end

function notify()
	if window.onLockChanged then
		window.onLockChanged();
	elseif window.parentcontrol and window.parentcontrol.window.onLockChanged then
		window.parentcontrol.window.onLockChanged();
	end
end
