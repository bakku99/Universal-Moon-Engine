--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

localdatabasenode = nil;
id = "";
function setData(n, node)
	id = n;
	localdatabasenode = node;
end

local _bRequested = false;
function openCharacter()
	if not _bRequested then
		UserManager.requestIdentity(id, { nodeLocal = self.localdatabasenode, fnResponse = self.requestResponse, });
		_bRequested = true;
	end
end
function requestResponse(result, identity)
	if result and identity then
		Interface.openWindow("charsheet", DB.getPath("charsheet", identity));
		if windowlist then
			windowlist.window.close();
		end
	else
		error.setVisible(true);
	end
end
