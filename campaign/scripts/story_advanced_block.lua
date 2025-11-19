--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onLockModeChanged(StoryManager.getBlockReadOnlyState(self));

	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "blocktype"), "onUpdate", self.onBlockTypeChanged);
	DB.addHandler(DB.getPath(node, "frame"), "onUpdate", self.onFrameChanged);
	DB.addHandler(DB.getPath(node, "frameleft"), "onUpdate", self.onFrameChanged);
	DB.addHandler(DB.getPath(node, "order"), "onUpdate", self.onOrderChanged);
end
function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "blocktype"), "onUpdate", self.onBlockTypeChanged);
	DB.removeHandler(DB.getPath(node, "frame"), "onUpdate", self.onFrameChanged);
	DB.removeHandler(DB.getPath(node, "frameleft"), "onUpdate", self.onFrameChanged);
	DB.removeHandler(DB.getPath(node, "order"), "onUpdate", self.onOrderChanged);
end

function onBlockTypeChanged()
	if not self.getBlockWidth() then
		return;
	end
	StoryManager.onBlockRebuild(self);
end
function onFrameChanged()
	WindowManager.callInnerWindowFunction(contents, "onFrameChanged");
end
function onOrderChanged()
	windowlist.applySort();
end
function onLockModeChanged(bReadOnly)
	WindowManager.callSafeControlsSetVisible(self, { "idelete", "ireorder" }, not bReadOnly);
end

local _nWidth = nil;
local _bWrap = false;
function getBlockWidth()
	return _nWidth;
end
function getBlockWrap()
	return _bWrap;
end
function setBlockWidth(n)
	_nWidth = n;
end
function setBlockWrap(bValue)
	_bWrap = bValue;
end

function onFirstLayout()
	self.setBlockWidth(getSize());
	self.setBlockWrap(StoryManager.getBlockWrapMode(self));
	StoryManager.onBlockRebuild(self);
end
function onLayoutSizeChanged()
	local nOldWidth = self.getBlockWidth();
	if not nOldWidth then
		return;
	end
	self.setBlockWidth(getSize());
	local nCurrWidth = self.getBlockWidth();
	if nCurrWidth ~= nOldWidth then
		local bWrap = StoryManager.getBlockWrapMode(self);
		if self.getBlockWrap() ~= bWrap then
			self.setBlockWrap(bWrap);
			StoryManager.onBlockRebuild(self);
		end
	end
end

function onDrop(_, _, draginfo)
	WindowManager.handleDropReorder(self, draginfo)
end
