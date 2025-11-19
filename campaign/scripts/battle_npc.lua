--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
	self.synchToCount();
	self.synchTokenView();
end

function onLockModeChanged(bReadOnly)
	WindowManager.callSafeControlsSetLockMode(self, { "count", "token", "name", "faction", "isidentified", "idelete", }, bReadOnly);
end

function synchToCount()
	if not Session.IsHost then
		return;
	end

	local nodeList = maplinks.getDatabaseNode();
	local nCount = count.getValue();

	local nListCount = DB.getChildCount(nodeList);
	if nListCount < nCount then
		for _ = nListCount + 1, nCount do
			DB.createChild(nodeList);
		end
		self.synchTokenView();

	elseif nListCount > nCount then
		local i = 1;
		for _, v in pairs(maplinks.getWindows()) do
			if i > nCount then
				WindowManager.safeDelete(v);
			end
			i = i + 1;
		end
	end
end
function synchTokenView()
	local sToken = token.getPrototype();
	local bShowLinks = Session.IsHost and (sToken ~= "");
	maplinks.setVisible(bShowLinks);
	maplinks_label.setVisible(bShowLinks);

	for _, v in pairs(maplinks.getWindows()) do
		v.token.setPrototype(sToken);
	end
end
