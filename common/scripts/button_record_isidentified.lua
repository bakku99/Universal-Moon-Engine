--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _nodeSrc = nil;
local _nDefault = 1;

function onInit()
	_nodeSrc = window.getDatabaseNode();

	if _nodeSrc then
		self.onUpdate();

		DB.addHandler(_nodeSrc, "onChildDeleted", self.onDelete);
		local sPath = DB.getPath(_nodeSrc, "isidentified");
		DB.addHandler(sPath, "onAdd", self.onUpdate);
		DB.addHandler(sPath, "onUpdate", self.onUpdate);
	end

	self.notify();
end
function onClose()
	if _nodeSrc then
		DB.removeHandler(_nodeSrc, "onChildDeleted", self.onDelete);
		local sPath = DB.getPath(_nodeSrc, "isidentified");
		DB.removeHandler(sPath, "onAdd", self.onUpdate);
		DB.removeHandler(sPath, "onUpdate", self.onUpdate);
	end
end

local _bUpdating = false;
function onDelete(_, sChild)
	if sChild == "isidentified" then
		self.onUpdate();
		self.notify();

		-- Re-add specific handlers, since specific handlers get cleared on specific node deletion
		local sPath = DB.getPath(_nodeSrc, "isidentified");
		DB.addHandler(sPath, "onAdd", self.onUpdate);
		DB.addHandler(sPath, "onUpdate", self.onUpdate);
	end
end
function onUpdate()
	if _bUpdating then
		return;
	end

	_bUpdating = true;
	local nValue = DB.getValue(_nodeSrc, "isidentified", _nDefault);
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
			local nValue = getValue();
			-- Workaround to force field update on client;
			-- Client does not pass network update to other clients if setValue creates value node with default value
			if not DB.getChild(_nodeSrc, "isidentified") and (nValue == 0) then
				DB.setValue(_nodeSrc, "isidentified", "number", 1);
			end
			DB.setValue(_nodeSrc, "isidentified", "number", nValue);
		end
		_bUpdating = false;
	end

	self.notify();
end

function notify()
	if window.onIDChanged then
		window.onIDChanged();
	end
	if window.parentcontrol and window.parentcontrol.window.onIDChanged then
		window.parentcontrol.window.onIDChanged();
	end
end
