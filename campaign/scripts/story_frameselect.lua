--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _bLeft = false;
local _wBlock = nil;

function onInit()
	self.buildWindows();
end

function buildWindows()
	list.closeAll();

	list.createWindow().setData("");

	for _,sName in ipairs(StoryManager.getBlockFrames()) do
		list.createWindow().setData(sName);
	end
end

function setBlockData(wBlock, bLeft)
	if not wBlock then
		close();
		return;
	end
	local nodeBlock = wBlock.getDatabaseNode();
	if not nodeBlock then
		close();
		return;
	end
	_bLeft = bLeft;
	_wBlock = wBlock;
end

function activate(sName)
	if _wBlock then
		if _bLeft then
			DB.setValue(_wBlock.getDatabaseNode(), "frameleft", "string", sName);
		else
			DB.setValue(_wBlock.getDatabaseNode(), "frame", "string", sName);
		end

		StoryManager.onBlockNodeRebuild(_wBlock.getDatabaseNode());
	end
	close();
end
