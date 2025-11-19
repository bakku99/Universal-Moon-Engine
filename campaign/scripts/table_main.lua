--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _tColumnLabels = {};
local _nColumnLeftMargin = 70;
local _nColumnRightMargin = 30;
local _nLabelLeftMargin = 5;
local _nLabelRightMargin = 5;
local _bInitPhase = true;

function onInit()
	if Session.IsHost then
		OptionsManager.registerCallback("REVL", self.onOptionUpdate);

		if tablerows.getWindowCount() == 0 then
			self.addRow();
			self.addRow();
		end
	end

	self.onColumnsChanged();

	self.updateDieHeader();
	self.onOptionUpdate();
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));

	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "tablerows.*.fromrange"), "onUpdate", self.updateDieHeader);
	DB.addHandler(DB.getPath(node, "tablerows.*.torange"), "onUpdate", self.updateDieHeader);
	DB.addHandler(DB.getPath(node, "tablerows"), "onChildDeleted", self.updateDieHeader);
	DB.addHandler(DB.getPath(node, "dice"), "onUpdate", self.updateDieHeader);
	DB.addHandler(DB.getPath(node, "mod"), "onUpdate", self.updateDieHeader);
end
function onClose()
	if Session.IsHost then
		OptionsManager.unregisterCallback("REVL", self.onOptionUpdate);
	end

	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "tablerows.*.fromrange"), "onUpdate", self.updateDieHeader);
	DB.removeHandler(DB.getPath(node, "tablerows.*.torange"), "onUpdate", self.updateDieHeader);
	DB.removeHandler(DB.getPath(node, "tablerows"), "onChildDeleted", self.updateDieHeader);
	DB.removeHandler(DB.getPath(node, "dice"), "onUpdate", self.updateDieHeader);
	DB.removeHandler(DB.getPath(node, "mod"), "onUpdate", self.updateDieHeader);
end

function onLayoutSizeChanged()
	self.updateColumns();
end
function onSubwindowInstantiated()
	_bInitPhase = false;
	self.updateColumns();
end

function onLockModeChanged(bReadOnly)
	local tFields = { "table_iadd_column", "table_idelete_column", "table_iadd_row", };
	WindowManager.callSafeControlsSetVisible(self, tFields, not bReadOnly);
	WindowManager.callSafeControlsSetLockMode(self, { "description", }, bReadOnly);
	WindowManager.callSafeControlsSetVisible(self, { "description", }, not bReadOnly or not description.isEmpty());
	divider.setVisible(WindowManager.getAnyControlVisible(self, { "description", }));
	for _,ctrlLabel in pairs(_tColumnLabels) do
		ctrlLabel.setReadOnly(bReadOnly);
	end
end

function onOptionUpdate()
	local bShow = false;
	if Session.IsHost then
		bShow = OptionsManager.isOption("REVL", "on");
	end

	hiderollresults.setVisible(bShow);
	label_showroll.setVisible(bShow);
end

function updateDieHeader()
	local aDice, nMod = TableManager.getTableDice(getDatabaseNode());
	local sDice = DiceManager.convertDiceToString(aDice, nMod);
	tablecolumnheaders.subwindow.header_die.setValue(sDice);
end

function getColumns()
	return resultscols.getValue();
end
function setColumns(nColumns)
	local nCurrentColumns = self.getColumns();
	if nColumns < 1 then
		nColumns = 1;
	elseif nColumns > TableManager.MAX_COLUMNS then
		nColumns = TableManager.MAX_COLUMNS;
	end
	if nColumns ~= nCurrentColumns then
		resultscols.setValue(nColumns);
	end
end
function calcColumnWidths()
	local w,_ = tablerows.getSize();
	return math.floor(((w - _nColumnLeftMargin - _nColumnRightMargin) / self.getColumns()) + 0.5) - 1;
end

function onColumnsChanged()
	local nColumns = self.getColumns();
	for i = 1, nColumns do
		self.addColumnLabel(i);
	end
	for i = nColumns + 1, TableManager.MAX_COLUMNS do
		self.removeColumnLabel(i);
	end

	if Session.IsHost then
		for _,v in ipairs(tablerows.getWindows()) do
			self.setRowColumns(v, nColumns);
		end
	end

	self.updateColumns();
end

function addColumnLabel(index)
	local ctrlLabel = tablecolumnheaders.subwindow["labelcol" .. index];
	if not ctrlLabel then
		ctrlLabel = tablecolumnheaders.subwindow.createControl("label_tablecolumn", "labelcol" .. index);
		if ctrlLabel then
			table.insert(_tColumnLabels, index, ctrlLabel);
		end
	end
end
function removeColumnLabel(index)
	local ctrlLabel = tablecolumnheaders.subwindow["labelcol" .. index];
	if ctrlLabel then
		ctrlLabel.destroy();
		table.remove(_tColumnLabels, index);
	end
end

function updateColumns()
	if _bInitPhase then
		return;
	end
	local nColumns = self.getColumns();
	local nWidth = self.calcColumnWidths();
	for _,v in ipairs(tablerows.getWindows()) do
		v.results.setColumnWidth(nWidth);
	end
	local x = _nColumnLeftMargin + 10;
	local nLabelWidth = nWidth - _nLabelLeftMargin - _nLabelRightMargin;
	for k,v in pairs(_tColumnLabels) do
		if k <= nColumns then
			v.setAnchor("left", "", "left", "absolute", x + _nLabelLeftMargin);
			v.setVisible(true);
			v.setAnchoredWidth(nLabelWidth);
			x = x + nWidth;
		elseif k > nColumns then
			v.setVisible(false);
		end
	end
end

function addRow()
	local winRow = tablerows.createWindow();
	self.setRowColumns(winRow, self.getColumns());
	winRow.results.setColumnWidth(self.calcColumnWidths());
	return winRow;
end
function setRowColumns(winRow, nColumns)
	local nodeResults = winRow.results.getDatabaseNode();
	if not nodeResults then
		return;
	end
	if DB.isStatic(nodeResults) then
		return;
	end

	local nCount = 0;
	for _,v in ipairs(winRow.results.getWindows()) do
		nCount = nCount + 1;
		if nCount > nColumns then
			DB.deleteNode(v.getDatabaseNode());
		end
	end
	while nCount < nColumns do
		nCount = nCount + 1;
		winRow.results.createWindow();
	end
end

function onDrop(x, _, draginfo)
	-- If no dice, then nothing to do
	local sDragType = draginfo.getType();
	if sDragType ~= "dice" and sDragType ~= "table" then
		return false;
	end
	local aDropDiceList = draginfo.getDiceData();
	if not aDropDiceList then
		return false;
	end

	-- Set up table roll structure
	local rTableRoll = {};
	rTableRoll.nodeTable = getDatabaseNode();

	-- Get dice and mod
	rTableRoll.aDice = {};
	for _,v in ipairs(aDropDiceList) do
		table.insert(rTableRoll.aDice, v.type);
	end
	rTableRoll.nMod = draginfo.getNumberData();

	-- Determine column dropped on (if any)
	rTableRoll.nColumn = 0;
	local nColumns = self.getColumns();
	if nColumns > 1 then
		local nWidth = self.calcColumnWidths();
		if x > _nColumnLeftMargin then
			rTableRoll.nColumn = math.floor((x - _nColumnLeftMargin) / nWidth) + 1;
			if (rTableRoll.nColumn < 1) or (rTableRoll.nColumn > nColumns) then
				rTableRoll.nColumn = 0;
			end
		end
	end

	-- Perform the roll
	TableManager.performRoll(nil, nil, rTableRoll, true);
	return true;
end

function actionRoll(draginfo)
	local rTableRoll = {};
	rTableRoll.nodeTable = getDatabaseNode();

	TableManager.performRoll(draginfo, nil, rTableRoll, true);
	return true;
end
