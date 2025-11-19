--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals parameters source sourceless

function onInit()
	self.performDisplayParamInit();
	self.performOptionDataInit();
	self.performSourceInit();
	self.performDefaultIndexInit();
	self.performUIInit();
end
function onClose()
	self.performUICleanup();
	self.performSourceCleanup();
end

--
--	STANDARD CONTROL FUNCTIONS
--

local _sValue = "";
function getValue()
	return _sValue;
end
function setValue(sValue)
	if not self.hasValue(sValue) then
		sValue = "";
	end
	if _sValue == sValue then
		return;
	end
	_sValue = sValue;
	self.saveSourceData();
end
function isEmpty()
	return (_sValue == "");
end

function getDatabaseNode()
	local sPath = self.getSourcePath();
	if sPath ~= "" then
		return DB.findNode(sPath);
	end
	return nil;
end
--
--	METADATA
--

local _tMetadata = {};
function getMetadata(sKey)
	if _tMetadata[sKey] ~= nil then
		return _tMetadata[sKey];
	end
	return (self._tMetadataDefaults and self._tMetadataDefaults[sKey]);
end
function setMetadata(sKey, v)
	_tMetadata[sKey] = v;
end

--
--	INDEX FUNCTIONS
--

function performDefaultIndexInit()
	if parameters then
		local nDefault;
		if parameters[1].defaultindex then
			nDefault = tonumber(parameters[1].defaultindex[1]);
		elseif parameters[1].nodefault then
			nDefault = 1;
		end
		if nDefault then
			local tValues = self.getValuesData();
			if tValues[nDefault] then
				self.setDefaultIndex(nDefault);
				local sSource = self.getSourcePath();
				if sSource == "" then
					self.setValue(tValues[nDefault]);
				elseif not DB.findNode(sSource) then
					local node = window.getDatabaseNode();
					if node and DB.isOwner(node) then
						self.setValue(tValues[nDefault]);
					end
				end
			end
		end
	end
end

function cycleValue(bBackward)
	local nIndex = self.getIndex();
	if bBackward then
		if nIndex > 1 then
			nIndex = nIndex - 1;
		else
			nIndex = self.getValueCount();
		end
	else
		if nIndex < self.getValueCount() then
			nIndex = nIndex + 1;
		else
			nIndex = 1;
		end
	end

	self.setIndex(nIndex);
end

function getIndex()
	local s = self.getValue();
	for k,sValue in ipairs(self.getValuesData()) do
		if s == sValue then
			return k;
		end
	end
	return self.getDefaultIndex();
end
function setIndex(n)
	self.setValue(self.getValuesData()[n or self.getDefaultIndex()]);
end
local _nDefaultIndex = 1;
function getDefaultIndex()
	return _nDefaultIndex;
end
function setDefaultIndex(n)
	_nDefaultIndex = math.max((n or 1), 1);
end


--
--	DISPLAY PARAMETERS
--

function performDisplayParamInit()
	-- NOTE: Custom for each derived control; must override
end

--
--	DATA OPTIONS
--

function performOptionDataInit()
	if self.hasValues() then
		return;
	end

	local tData = self.getOptionData();
	local tItems = self.getOptionItems(tData);
	self.addItems(tItems);
end
function getOptionData()
	local tData = {};
	if parameters then
		if parameters[1].nodefault then
			tData.bNoDefault = true;
		end

		if parameters[1].values then
			tData.sValues = parameters[1].values[1];
		end

		if parameters[1].labelsres then
			tData.sLabels = UtilityManager.resolvePipedStringRes(parameters[1].labelsres[1]);
		elseif parameters[1].labels then
			tData.sLabels = parameters[1].labels[1];
		end
		if parameters[1].defaultlabelres then
			tData.sDefaultLabel = Interface.getString(parameters[1].defaultlabelres[1]);
		elseif parameters[1].defaultlabel then
			tData.sDefaultLabel = parameters[1].defaultlabel[1];
		end

		if parameters[1].icons then
			tData.sIcons = parameters[1].icons[1];
		end
		if parameters[1].defaulticon then
			tData.sDefaultIcon = parameters[1].defaulticon[1];
		end

		if parameters[1].tooltipsres then
			tData.sTooltips = UtilityManager.resolvePipedStringRes(parameters[1].tooltipsres[1]);
		elseif parameters[1].tooltips then
			tData.sTooltips = parameters[1].tooltips[1];
		end
		if parameters[1].defaulttooltipres then
			tData.sDefaultTooltip = Interface.getString(parameters[1].defaulttooltipres[1]);
		elseif parameters[1].defaulttooltip then
			tData.sDefaultTooltip = parameters[1].defaulttooltip[1];
		end
	end
	return tData;
end
function getOptionItems(tData)
	if not tData then
		return {};
	end
	local tValues = StringManager.split(tData.sValues or "", "|", true);
	if (#tValues == 0) and ((tData.sDefaultLabel or "") == "") and ((tData.sDefaultIcon or "") == "") then
		return {};
	end

	local tLabels = StringManager.split(tData.sLabels or "", "|", true);
	local tIcons = StringManager.split(tData.sIcons or "", "|", true);
	local tTooltips = StringManager.split(tData.sTooltips or "", "|", true);

	local tItems = {};
	if not tData.bNoDefault then
		table.insert(tItems, { sValue = "", sText = tData.sDefaultLabel, sIcon = tData.sDefaultIcon, sTooltip = tData.sDefaultTooltip, });
	end
	for i = 1, #tValues do
		table.insert(tItems, { sValue = tValues[i], sText = tLabels[i], sIcon = tIcons[i], sTooltip = tTooltips[i], });
	end
	return tItems;
end
function resolveOptionItemData(v)
	if not v then
		return nil;
	end

	local tItem;
	if type(v) ~= "table" then
		tItem = { sValue = tostring(v) or "", sText = tostring(v) or "", };
	else
		tItem = v;
		if not tItem.sValue then
			tItem.sValue = tItem.sText or "";
		end
	end
	return tItem;
end

--
--	DATA SOURCE
--

function performSourceInit()
	if sourceless then
		self.setSourcePath("");
	else
		local sField;
		local sType;
		if source and source[1] and source[1].name and ((source[1].name[1] or "") ~= "") then
			sField = source[1].name[1];
		end
		if source and source[1] and source[1].type and ((source[1].type[1] or "") == "number") then
			sType = "number";
		end
		self.setSourceField(sField or getName(), sType);
	end
end
function performSourceCleanup()
	self.setSourcePath("");
end

local _sSourcePath = "";
local _sSourceType = "string";
function getSourcePath()
	return _sSourcePath, _sSourceType;
end
function setSourceField(sField, sType)
	local node = window.getDatabaseNode();
	if node and ((sField or "") ~= "") then
		self.setSourcePath(DB.getPath(node, sField), sType);
	else
		self.setSourcePath("");
	end
end
function setSourcePath(sPath, sType)
	if _sSourcePath == (sPath or "") then
		self.refreshSourceDisplay();
		return;
	end

	if (_sSourcePath or "") ~= "" then
		DB.removeHandler(_sSourcePath, "onAdd", self.onSourceUpdate);
		DB.removeHandler(_sSourcePath, "onUpdate", self.onSourceUpdate);
	end

	_sSourcePath = sPath or "";
	_sSourceType = ((sType or "") == "number") and "number" or "string";

	if (sPath or "") ~= "" then
		DB.addHandler(sPath, "onAdd", self.onSourceUpdate);
		DB.addHandler(sPath, "onUpdate", self.onSourceUpdate);

		local node = window.getDatabaseNode();
		if node and DB.isReadOnly(node) then
			setReadOnly(true);
		end
	end

	self.refreshSourceDisplay();
end

local _bUpdatingSource = false;
function onSourceUpdate()
	self.refreshSourceDisplay();
	if self.onValueChanged then
		self.onValueChanged();
	end
end
function loadSourceData()
	if _bUpdatingSource then
		return;
	end
	_bUpdatingSource = true;
	local sSource, sSourceType = self.getSourcePath();
	if (sSourceType or "") == "number" then
		if sSource ~= "" then
			self.setIndex(DB.getValue(sSource, 0) + 1);
		else
			setValue("");
		end
	else
		if sSource ~= "" then
			setValue(DB.getValue(sSource, ""));
		else
			setValue("");
		end
	end
	_bUpdatingSource = false;
end
function saveSourceData()
	if _bUpdatingSource then
		return;
	end
	_bUpdatingSource = true;
	local sSource, sSourceType = self.getSourcePath();
	if sSource ~= "" then
		if (sSourceType or "") == "number" then
			DB.setValue(sSource, "number", self.getIndex() - 1);
		else
			DB.setValue(sSource, "string", self.getValue());
		end
	else
		self.onSourceUpdate();
	end
	_bUpdatingSource = false;
end
function refreshSourceData()
	if _bUpdatingSource then
		return;
	end
	local sSource = self.getSourcePath();
	if sSource ~= "" then
		self.loadSourceData();
	end
end

--
--	DATA MANAGEMENT
--
--	Format: { sValue = "", [sText = "",] [sIcon = "",] [sTooltip = "",] [bAllowDelete = bool,] }
--		Optional options may or may not be used in each derived control
--

local _tItems = {};
local _tOrderedValues = {};
function getItemsData()
	return _tItems;
end
function getValuesData()
	return _tOrderedValues;
end
function getValues()
	return UtilityManager.copyDeep(_tOrderedValues);
end
function hasValue(sValue)
	return (self.getItemDataByValue(sValue) ~= nil);
end
function hasValues()
	return (#self.getValuesData() > 0);
end
function getValueCount()
	return #self.getValuesData();
end
function clearItemsData()
	local tItems = self.getItemsData();
	for k in pairs(tItems) do
		tItems[k] = nil
	end
	local tValues = self.getValuesData();
	for k in pairs(tValues) do
		tValues[k] = nil
	end
end
function addItemData(tItem)
	tItem = self.resolveOptionItemData(tItem);
	if not tItem then
		return false;
	end
	if self.getItemDataByValue(tItem.sValue) then
		return false;
	end
	self.getItemsData()[tItem.sValue or ""] = tItem;
	table.insert(self.getValuesData(), tItem.sValue or "");
	return true;
end
function setItemData(tItem)
	tItem = self.resolveOptionItemData(tItem);
	if not tItem then
		return false;
	end
	self.getItemsData()[tItem.sValue or ""] = tItem;
	if not StringManager.contains(self.getValuesData(), tItem.sValue or "") then
		table.insert(self.getValuesData(), tItem.sValue or "");
	end
	return true;
end
function removeItemData(sValue)
	if not self.getItemsData()[sValue or ""] then
		return false;
	end
	self.getItemsData()[sValue or ""] = nil;
	for k,s in ipairs(self.getValuesData()) do
		if s == sValue then
			table.remove(self.getValuesData(), k);
			break;
		end
	end
	return true;
end
function getItemDataByValue(sValue)
	return self.getItemsData()[sValue or ""];
end

function setItems(tList)
	self.clear(true);
	self.addItems(tList, true);
	self.refreshSourceDisplay();
end
function addItem(tItem, bSkipRefresh)
	local bResult = self.addItemData(tItem);
	if bResult and not bSkipRefresh then
		self.refreshSourceDisplay();
	end
	return bResult;
end
function addItems(tList, bSkipRefresh)
	local bResult = false;
	for _,v in ipairs(tList or {}) do
		if self.addItem(v, true) then
			bResult = true;
		end
	end
	if bResult and not bSkipRefresh then
		self.refreshSourceDisplay();
	end
	return bResult;
end
function replaceItem(tItem, bSkipRefresh)
	local bResult = self.setItemData(tItem);
	if bResult and not bSkipRefresh then
		self.refreshSourceDisplay();
	end
	return bResult;
end
function removeItem(sValue, bSkipRefresh)
	local bResult = self.removeItemData(sValue);
	if self.getValue() == (sValue or "") then
		self.setValue("");
	end
	if bResult and not bSkipRefresh then
		self.refreshSourceDisplay();
	end
	return bResult;
end
function clear(bSkipRefresh)
	self.clearItemsData();
	if self.onClear then
		self.onClear();
	end
	if not bSkipRefresh then
		self.refreshSourceDisplay();
	end
end

--
--	UI
--

function performUIInit()
	-- NOTE: Custom for each derived control; must override
end
function performUICleanup()
	-- NOTE: Custom for each derived control; must override
end

function refreshSourceDisplay()
	self.refreshSourceData();
	self.refreshDisplay();
end
function refreshDisplay()
	-- NOTE: Custom for each derived control; must override
end

--
--	BACKWARD COMPATIBILITY
--

function getStringValue()
	return self.getValue();
end
function setStringValue(s)
	self.setValue(s);
end

function updateDisplay()
	self.refreshDisplay();
end
