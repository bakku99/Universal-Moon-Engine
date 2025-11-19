--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals source sources hasSources

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	self.initSourceTags();
	if self.hasSource() then
		self.sourceUpdate();
	end
end
function onClose()
	self.cleanupSources();
end

function initSourceTags()
	if source and type(source[1]) == "table" then
		for _,v in ipairs(source) do
			if v.name and type(v.name) == "table" then
				if v.string then
					self.addSource(v.name[1], "string");
				elseif v.op then
					self.addSourceWithOp(v.name[1], v.op[1]);
				else
					self.addSource(v.name[1], "number");
				end
			end
		end
	end
end
function cleanupSources()
	for _,node in pairs(self.getSources()) do
		DB.removeHandler(node, "onUpdate", self.sourceUpdate);
	end
end

hasSources = false;
sources = {};
local _tOps = {};
function hasSource()
	return hasSources;
end
function getSources()
	return sources;
end
function getSource(sName)
	if not sName then
		return nil;
	end
	return sources[sName];
end
function getSourceValue(sName)
	local node = self.getSource(sName);
	if not node then
		return nil;
	end
	return DB.getValue(node);
end
function addSource(sName, sType)
	if not sName then
		return false;
	end
	if not sType then
		sType = "number";
	end

	local node = DB.createChild(window.getDatabaseNode(), sName, sType);
	if not node then
		return false;
	end

	sources[sName] = node;
	DB.addHandler(node, "onUpdate", self.sourceUpdate);
	hasSources = true;
	return true;
end
function addSourceWithOp(sName, sOpValue)
	if self.addSource(sName, "number") then
		_tOps[sName] = sOpValue;
	end
end
function getOps()
	return _tOps;
end

function sourceUpdate(nodeUpdated)
	if self.onSourceValueUpdate then
		for k,v in pairs(self.getSources()) do
			if v == nodeUpdated then
				self.onSourceValueUpdate(k, v);
				break;
			end
		end
	end
	if self.onSourceUpdate then
		self.onSourceUpdate();
	end
end
function onSourceUpdate()
	setValue(self.calculateSources());
end
function calculateSources()
	local n = 0;

	for sName, sOp in pairs(self.getOps()) do
		local nodeSource = self.getSource(sName);
		if nodeSource then
			if sOp == "+" then
				n = n + self.onSourceValue(nodeSource, sName);
			elseif sOp == "-" then
				n = n - self.onSourceValue(nodeSource, sName);
			elseif sOp == "*" then
				n = n * self.onSourceValue(nodeSource, sName);
			elseif sOp == "/" then
				n = n / self.onSourceValue(nodeSource, sName);
			elseif sOp == "neg+" then
				local nSourceValue = self.onSourceValue(nodeSource, sName);
				if nSourceValue < 0 then
					n = n + nSourceValue;
				end
			end
		end
	end

	return n;
end
function onSourceValue(nodeSource)
	return DB.getValue(nodeSource);
end
