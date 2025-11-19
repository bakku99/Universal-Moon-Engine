--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals separator

--
--	ACTION PARSING AND HANDLING
--

function getActor()
	return ActorManager.resolveActor(window.getDatabaseNode());
end

local _tCurrAction = nil;
function getCurrentAction()
	return _tCurrAction;
end
function setCurrentAction(t)
	_tCurrAction = t;
end

function action(draginfo)
	local tAction = self.getCurrentAction();
	if not tAction then
		return;
	end
	ActionsManager.performAction(draginfo, self.getActor(), tAction);
end

function getActionSeparators()
	return separator and separator[1] or ",;\r\n";
end

local _bParsed = false;
local _tActions = {};
function getParsed()
	return _bParsed;
end
function setParsed(v)
	_bParsed = v;
end

function getActionData()
	if not _bParsed then
		self.parseActionData();
	end
	return _tActions;
end
function parseActionData(bForce)
	if not bForce and _bParsed then
		return;
	end

	_tActions = {};

	local tStrings, tStringStats = StringManager.split(getValue(), self.getActionSeparators(), true);
	for i = 1, #tStrings do
		local tAction = self.parseAction(tStrings[i]);
		if tAction then
			tAction._nStartPos = tStringStats[i].startpos;
			tAction._nEndPos = tStringStats[i].endpos;
			table.insert(_tActions, tAction);
		end
	end

	self.setParsed(true);
end
function getActionText(tAction)
	if not tAction then
		return "";
	end
	local s = getValue();
	if tAction._nStartPos >= #s then
		return "";
	end
	return s:sub(tAction._nStartPos, tAction._nEndPos);
end

--
--	UI BEHAVIORS
--

local _bDragging = false;
function isDragging()
	return _bDragging;
end
function setDragging(v)
	_bDragging = v;
end

function onChar()
	self.setParsed(false);
end
-- Hilight roll when hovering over it
function onHover(bOnControl)
	if self.isDragging() or bOnControl then
		return;
	end
	self.setCurrentAction(nil);
	setSelectionPosition(0);
end
function onHoverUpdate(x, y)
	if self.isDragging() then
		return;
	end

	local nMouseIndex = getIndexAt(x, y);

	local tActions = self.getActionData();
	for i = 1, #tActions, 1 do
		local tAction = tActions[i];
		if tAction._nStartPos <= nMouseIndex and tAction._nEndPos > nMouseIndex then
			setCursorPosition(tAction._nStartPos);
			setSelectionPosition(tAction._nEndPos);

			self.setCurrentAction(tAction);
			setHoverCursor("hand");
			return;
		end
	end

	self.setCurrentAction(nil);
	setHoverCursor("arrow");
end
function onClickDown()
	-- Suppress default processing to support dragging
	return true;
end
function onClickRelease(_, x, y)
	-- On mouse click, set focus, set cursor position and clear selection
	local n = getIndexAt(x, y);
	setFocus();
	setSelectionPosition(n);
	setCursorPosition(n);
	return true;
end
function onDoubleClick()
	self.action();
	return true;
end
function onDragStart(_, _, _, draginfo)
	self.setDragging(true);
	self.action(draginfo);
	setCursorPosition(0);
	return true;
end
function onDragEnd()
	self.setDragging(false);
end
