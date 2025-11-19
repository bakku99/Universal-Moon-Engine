--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	StoryManager.initRecordLegacyText(self);
	self.onLockModeChanged(WindowManager.getReadOnlyState(getDatabaseNode()));
end

function onLockModeChanged(bReadOnly)
	if not bReadOnly then
		StoryManager.migrateRecordLegacyTextToBlock(self);
	end

	local tFields = {
		"button_iadd_block_text",
		"button_iadd_block_dualtext",
		"button_iadd_block_header",
		"button_iadd_block_image",
		"button_iadd_block_textlimager",
		"button_iadd_block_textrimagel",
	};
	WindowManager.callSafeControlsSetVisible(self, tFields, not bReadOnly);
end
