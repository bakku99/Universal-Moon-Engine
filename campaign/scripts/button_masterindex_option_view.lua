--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals nodrag recordpath recordtype recordview text textres

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	if not text and not textres then
		local sRecordType, sRecordView = self.getData();
		if sRecordType and sRecordView then
			local sRecordViewLabelRes = string.format("library_recordview_label_%s_%s", sRecordType, sRecordView);
			setText(Interface.getString(sRecordViewLabelRes));
		end
	end
end

function getData()
	return recordtype and recordtype[1], recordview and recordview[1], recordpath and recordpath[1];
end

function onButtonPress()
	ListManager.toggleRecordView(self.getData());
end
function onDragStart(_, _, _, draginfo)
	if nodrag then
		return;
	end
	return ListManager.onDragRecordView(draginfo, self.getData());
end
