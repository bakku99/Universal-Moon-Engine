--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function setCurrent(s)
	ChatIdentityManager.setCurrentIdentity(s);
end
function getCurrent()
	local s = ChatIdentityManager.getCurrentIdentity();
	if (s or "") ~= "" then
		return s, ChatIdentityManager.isGMIdentity(s);
	end
	return nil, nil;
end

function getGMIdentity()
	return ChatIdentityManager.getGMIdentity();
end
function activateGMIdentity()
	ChatIdentityManager.setCurrentIdentityToGMIdentity();
end

function existsIdentity(s)
	return ChatIdentityManager.isIdentity(s);
end
function addIdentity(s, _)
	ChatIdentityManager.addIdentity(s);
end
function removeIdentity(s)
	ChatIdentityManager.removeIdentity(s);
end
