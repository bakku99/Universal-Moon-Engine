--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _bDialogThumbnailOpen = false;

function onInit()
	self.onFileValueChanged();
end
function onClose()
	if _bDialogThumbnailOpen then
		Interface.dialogFileClose();
	end
end

function onFileValueChanged()
	local sFile = file.getValue();
	if sFile == "" then
		file.setFrame("fieldrequired", 10,5,10,5);
		file.setTooltipText(Interface.getString("export_tooltip_file_empty"));
	elseif not ExportManager.isFileNameValid(sFile) then
		file.setFrame("fieldrequired", 10,5,10,5);
		file.setTooltipText(Interface.getString("export_tooltip_file_invalid"));
	else
		file.setFrame("fielddark", 10,5,10,5);
		file.setTooltipText("");
	end
end

function onThumbnailButtonPress()
	_bDialogThumbnailOpen = Interface.dialogFileOpen(self.onThumbnailFileSelection, { png = "PNG Files" });
end
function onThumbnailFileSelection(result, path)
	_bDialogThumbnailOpen = false;
	if result == "ok" then
		thumbnail.setValue(path);
	end
end
