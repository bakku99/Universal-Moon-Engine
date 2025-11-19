--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _sLink = nil;

function onInit()
	self.updateLink();
	self.initIndent();
end
function onClose()
	if _sLink then
		DB.removeHandler(_sLink, "onUpdate", self.onLinkUpdated);
	end
end

function onHover(bOnControl)
	setUnderline(bOnControl);
end
function onGainFocus()
	if not isReadOnly() then
		StoryManager.onBookIndexPagePressed(window, false);
	end
end
function onTab()
	if Input.isShiftPressed() then
		self.adjustIndent(-1);
	else
		self.adjustIndent(1);
	end
	return true;
end

local _nIndent = 0;
function initIndent()
	_nIndent = DB.getValue(window.getDatabaseNode(), "indent", 0);
	self.updateIndentDisplay();
end
function adjustIndent(nStep)
	local nNewIndent = math.max(0, _nIndent + nStep);
	if nNewIndent == _nIndent then
		return;
	end
	_nIndent = nNewIndent;
	DB.setValue(window.getDatabaseNode(), "indent", "number", nNewIndent);
	self.updateIndentDisplay();
end
function updateIndentDisplay()
	if window.spacer_indent then
		window.spacer_indent.setAnchoredWidth(_nIndent * 10);
	end
end

function onClickDown()
	if isReadOnly() then
		return true;
	end
end
function onClickRelease()
	if isReadOnly() then
		StoryManager.onBookIndexPagePressed(window, Input.isShiftPressed());
		return true;
	end
end

local _bLocked = false;
function onValueChanged()
	if _sLink and not _bLocked then
		_bLocked = true;
		DB.setValue(_sLink, "string", getValue());
		_bLocked = false;
	end
end

function onLinkUpdated()
	if _sLink and not _bLocked then
		_bLocked = true;
		setValue(DB.getValue(_sLink, ""));
		_bLocked = false;
	end
end
function updateLink()
	if _sLink then
		DB.removeHandler(_sLink, "onUpdate", self.onLinkUpdated);
		_sLink = nil;
	end

	local nodeWin = window.getDatabaseNode();
	if DB.isStatic(nodeWin) then
		return;
	end

	local node = nil;
	local _,sRecord = window.listlink.getValue();
	if (sRecord or "") ~= "" then
		node = DB.createNode(sRecord);
	end
	if node then
		if nodeWin ~= node then
			local nodeName = DB.createChild(node, "name", "string");
			if nodeName then
				_sLink = DB.getPath(nodeName);
				DB.addHandler(_sLink, "onUpdate", self.onLinkUpdated);
				self.onLinkUpdated();
			end
		end
	end
end
