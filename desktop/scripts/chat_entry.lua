--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onDeliverMessage(msg, mode)
	if ChatManager.onDeliverMessage(msg, mode) then
		return false;
	end
	return msg;
end

function onGainFocus()
	if not Session.IsHost then
		LanguageManager.refreshChatLanguages();
	end
end
function onTab()
	ChatManager.doUserAutoComplete(self);
	return true;
end
function onChar()
	if ChatManager.resetAutocompleteMode then
		ChatManager.resetAutocompleteMode();
	end
end
