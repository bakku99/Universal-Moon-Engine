--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals inverted maxslotperrow sourcefields spacing stateicons values

local _tDataDefaults = {
	["maximum"] = 1,
};
_tMetadataDefaults = {
	["color_disabled"] = "90FFFFFF",
	["color_full"] = "FFFFFFFF",
	["icon_off"] = "button_checkoff",
	["icon_on"] = "button_checkon",
	["maxslotperrow"] = 10,
	["minh"] = 0,
	["spacing"] = 10,
};

function onInit()
	self.performDisplayParamInit();
	self.performDataInit();
	self.setInitialized(true);
end
function onClose()
	self.setInitialized(false);
	self.performDataCleanup();
end

--
--	METADATA
--

local _bInit = false;
function isInitialized()
	return _bInit;
end
function setInitialized(bValue)
	_bInit = bValue;
	if bValue then
		self.refreshDisplay();
	end
end

local _tMetadata = {};
function getMetadata(sKey)
	if _tMetadata[sKey] ~= nil then
		return _tMetadata[sKey];
	end
	return (self._tMetadataDefaults and self._tMetadataDefaults[sKey]);
end
function setMetadata(sKey, v)
	_tMetadata[sKey] = v;
	self.refreshDisplay();
end

--
--	DISPLAY PARAMETERS
--

function performDisplayParamInit()
	self.setMetadata("minh", getAnchoredHeight());

	if stateicons then
		for k,v in pairs(stateicons[1]) do
			if (v[1] or "") ~= "" then
				self.setMetadata("icon_" .. k, v[1]);
			end
		end
	end

	if maxslotperrow then
		self.setMetadata("maxslotperrow", tonumber(maxslotperrow[1]));
	end
	if spacing then
		self.setMetadata("spacing", tonumber(spacing[1]));
	end
	if inverted then
		self.setMetadata("inverted", true);
	end
end

--
--	DATA
--

function performDataInit()
	if values then
		for k,v in pairs(values[1]) do
			if (v[1] or "") ~= "" then
				self.setVarNumberLocal(k, tonumber(v[1]));
			end
		end
	end
	if sourcefields then
		for k,v in pairs(sourcefields[1]) do
			self.setVarNumberField(k, v[1]);
		end
	end
	-- NOTE: Only affects database value of "current" value
	if negative then
		self.setMetadata("negative", true);
	end

	self.checkBounds();
end
function performDataCleanup()
	self.cleanupNumberVars();
end

function getCurrentValue()
	return self.getVarNumber("current");
end
function setCurrentValue(n)
	self.setVarNumber("current", n);
end
function getMaxValue()
	return self.getVarNumber("maximum");
end
function setMaxValue(n)
	self.setVarNumber("maximum", n);
end

local _tVars = {};
function cleanupNumberVars()
	for _,v in pairs(_tVars) do
		if (v.sPath or "") ~= "" then
			DB.removeHandler(v.sPath, "onUpdate", self.updateData);
		end
	end
end
function getVarNumber(sKey)
	local sPath = self.getVarNumberPath(sKey);
	if sPath ~= "" then
		if (sKey == "current") and self.getMetadata("negative") then
			return -DB.getValue(sPath, 0);
		else
			return DB.getValue(sPath, 0);
		end
	end
	return self.getVarNumberLocal(sKey);
end
function setVarNumber(sKey, n)
	local sPath = self.getVarNumberPath(sKey);
	if sPath ~= "" then
		-- TODO - Fix to add owner check
			-- Can't use window.getDatabaseNode, since window without a source are negatively affected (5E spell slots)
			-- Can't use sPath, because it might not exist yet.
		-- if not DB.isOwner(window.getDatabaseNode()) then
		-- 	return;
		-- end
		if (sKey == "current") and self.getMetadata("negative") then
			DB.setValue(sPath, "number", -n);
		else
			DB.setValue(sPath, "number", n);
		end
	else
		self.setVarNumberLocal(sKey, n);
	end
end
function getVarNumberPath(sKey)
	if (sKey or "") == "" then
		return "";
	end
	if not _tVars[sKey] then
		return "";
	end
	return _tVars[sKey].sPath or "";
end
function setVarNumberPath(sKey, sPath)
	if (sKey or "") == "" then
		return;
	end
	local sOldPath = self.getVarNumberPath(sKey);
	if sOldPath == (sPath or "") then
		return;
	end

	if sOldPath ~= "" then
		DB.removeHandler(sOldPath, "onUpdate", self.updateData);
	end
	_tVars[sKey] = _tVars[sKey] or {};
	_tVars[sKey].sPath = sPath or "";
	if (sPath or "") ~= "" then
		DB.addHandler(sPath, "onUpdate", self.updateData);
	end

	if _tDataDefaults[sKey] then
		-- TODO - Fix to add owner check similar to setVarNumber, but only if does not exist
		if ((sPath or "") ~= "") and not DB.getValue(sPath) then
			DB.setValue(sPath, "number", _tDataDefaults[sKey]);
		end
	end

	self.refreshDisplay();
end
function setVarNumberField(sKey, sField)
	if ((sKey or "") == "") then
		return;
	end
	local nodeWin = window.getDatabaseNode();
	if not nodeWin then
		return;
	end
	if (sField or "") == "" then
		sField = sKey;
	end

	self.setVarNumberPath(sKey, DB.getPath(nodeWin, sField));
end
function getVarNumberLocal(sKey)
	if (sKey or "") == "" then
		return 0;
	end
	if not _tVars[sKey] then
		return 0;
	end
	return _tVars[sKey].nLocal or (self._tDataDefaults and self._tDataDefaults[sKey]) or 0;
end
function setVarNumberLocal(sKey, n)
	if (sKey or "") == "" then
		return;
	end
	_tVars[sKey] = _tVars[sKey] or {};
	_tVars[sKey].nLocal = n or 0;
	self.refreshDisplay();
end

function adjustCounter(nAdj)
	local nMax = self.getMaxValue();
	local nVal = self.getCurrentValue() + nAdj;
	self.setCurrentValue(math.max(math.min(nVal, nMax), 0));
end
function checkBounds()
	self.adjustCounter(0);
end
function updateData()
	self.refreshDisplay();
	if self.onValueChanged then
		self.onValueChanged();
	end
end

--
--	DISPLAY
--

local _tDisplaySlots = {};
function refreshDisplay()
	if not self.isInitialized() then
		return;
	end

	local nSlots = self.getSlotCount();

	if #_tDisplaySlots ~= nSlots then
		local nSpacing = self.getMetadata("spacing");
		local nMaxSlotsPerRow = self.getMetadata("maxslotperrow");

		for _,v in ipairs(_tDisplaySlots) do
			v.destroy();
		end
		_tDisplaySlots = {};

		local nMinHeight = self.getMetadata("minh");
		local nDataHeight = (math.floor((nSlots - 1) / nMaxSlotsPerRow) + 1) * nSpacing;
		local nCenterOffset = (nMinHeight > nDataHeight) and math.floor((nMinHeight - nDataHeight) / 2) or 0;

		for i = 1, nSlots do
			local sIcon = self.getSlotIcon(i);
			local sColor = self.getSlotColor(i);

			local nX = (((i - 1) % nMaxSlotsPerRow) * nSpacing) + math.floor(nSpacing / 2);
			local nY = (math.floor((i - 1) / nMaxSlotsPerRow) * nSpacing) + math.floor(nSpacing / 2) + nCenterOffset;

			_tDisplaySlots[i] = addBitmapWidget({
				icon = sIcon,
				color = sColor,
				position = "topleft", x = nX, y = nY,
				w = nSpacing, h = nSpacing,
			});
		end

		setAnchoredWidth(math.min(nSlots, nMaxSlotsPerRow) * nSpacing);
		setAnchoredHeight(math.max(nMinHeight, nDataHeight));
	else
		for i = 1, nSlots do
			local wgt = _tDisplaySlots[i];
			if wgt then
				wgt.setBitmap(self.getSlotIcon(i));
				wgt.setColor(self.getSlotColor(i));
			end
		end
	end
end
function getSlotCount()
	return self.getMaxValue();
end
function getSlotIcon(n)
	if self.getMetadata("inverted") then
		return (n <= (self.getMaxValue() - self.getCurrentValue())) and self.getMetadata("icon_off") or self.getMetadata("icon_on");
	end
	return (n > self.getCurrentValue()) and self.getMetadata("icon_off") or self.getMetadata("icon_on");
end
function getSlotColor(_)
	return self.getMetadata("color_full");
end

function updateSlots()
	self.refreshDisplay();
end

--
--	USER EVENT
--

function onWheel(n)
	if isReadOnly() then
		return;
	end
	if not Input.isControlPressed() then
		return false;
	end

	self.adjustCounter(n);
	return true;
end
function onClickDown()
	if isReadOnly() then
		return;
	end
	return true;
end
function onClickRelease(_, x, y)
	if isReadOnly() then
		return;
	end

	if self.calcClickValue(x, y) > self.getCurrentValue() then
		self.adjustCounter(1);
	else
		self.adjustCounter(-1);
	end
	return true;
end

function calcClickValue(x, y)
	local nSpacing = self.getMetadata("spacing");
	local nMaxSlotsPerRow = self.getMetadata("maxslotperrow");

	local nClickH = math.floor(x / nSpacing) + 1;
	if self.getMetadata("inverted") then
		nClickH = self.getMaxValue() - nClickH + 1;
	end
	local nClickV;
	if self.getMaxValue() > nMaxSlotsPerRow then
		nClickV	= math.floor(y / nSpacing);
	else
		nClickV = 0;
	end
	local nClick = (nClickV * nMaxSlotsPerRow) + nClickH;
	return nClick;
end

--
--	LEGACY
--

function setCurrNode(sPath)
	self.setVarNumberPath("current", sPath);
end
function setMaxNode(sPath)
	self.setVarNumberPath("maximum", sPath);
end
