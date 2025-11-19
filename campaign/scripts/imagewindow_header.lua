--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		nonid_name.resetAnchor("left");
		nonid_name.setAnchor("left", nil, "center", "absolute", 22);
		self.onLayoutSizeChanged = self.onStateChanged;
	end
	self.onStateChanged();
end

function onLockModeChanged()
	self.onStateChanged();
end
function onIDModeChanged()
	self.onStateChanged();
end

function onStateChanged()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = RecordDataManager.getIDState("image", nodeRecord);
	WindowManager.callSafeControlsSetLockMode(self, { "name", "nonid_name", }, bReadOnly);

	if Session.IsHost then
		local bShow;
		if bReadOnly and (nonid_name.getValue() == "") then
			bShow = false;
		else
			local w,_ = getSize();
			bShow = (w >= 500);
		end
		nonid_icon.setVisible(bShow);
		nonid_name.setVisible(bShow);
	else
		name.setVisible(bID);
		nonid_name.setVisible(not bID);
	end
end
