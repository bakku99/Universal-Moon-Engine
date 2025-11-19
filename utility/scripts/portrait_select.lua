--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Portrait Select (Old Style)

local _nodeChar = nil;
local _tPath = {};

function onInit()
	self.buildWindows();
end

function buildWindows()
	list.closeAll();

	if #_tPath > 0 then
		list.createWindowWithClass("portrait_select_up");
	end

	local sPath = table.concat(_tPath, "/");
	for _, v in ipairs(User.getPortraitDirectoryList(sPath)) do
		local w = list.createWindowWithClass("portrait_select_folder");
		w.icon.setTooltipText(v);
		w.path.setValue(v);
	end

	for _, v in ipairs(User.getPortraitFileList(sPath)) do
		local w = list.createWindow();
		w.portrait.setFile(v);
		local sPortraitSansModule = StringManager.split(v, "@")[1];
		local aPortraitPath = StringManager.split(sPortraitSansModule, "/");
		if #aPortraitPath > 0 then
			w.portrait.setTooltipText(aPortraitPath[#aPortraitPath]);
			w.name.setValue(aPortraitPath[#aPortraitPath]);
		end
	end
end

function setLocalNode(nodeChar)
	_nodeChar = nodeChar;
end

function onActivate(sFile)
	RecordAssetManager.setCharPortrait(_nodeChar, sFile);
	close();
end
function onPathUp()
	if #_tPath > 0 then
		table.remove(_tPath);
		self.buildWindows();
	end
end
function onPathSelect(sFolder)
	table.insert(_tPath, sFolder);
	self.buildWindows();
end
