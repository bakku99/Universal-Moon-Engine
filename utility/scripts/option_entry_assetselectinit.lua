--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function getDisplayValue()
	return UtilityManager.getAssetBaseFileName(asset.getValue());
end
function getOptionValue()
	return OptionsManager.getOption("INITIND");
end
function onSetOptionValue()
	local tData = TokenManager.getTokenActiveOptions();
	asset.setValue(tData.sAsset);
	if tData.bOver then
		placement.setValue("over");
	else
		placement.setValue("");
	end
end

function setReadOnly(bReadOnly)
	super.setReadOnly(bReadOnly);

	asset.setReadOnly(bReadOnly);
	placement.setReadOnly(bReadOnly);
	if not bReadOnly then
		asset.setTooltipText(Interface.getString("option_tooltip_INITIND_value"));
		placement.setTooltipText(Interface.getString("option_tooltip_INITIND_value"));
	end
end

function onOptionPressed()
	if self.isReadOnly() then
		return;
	end
	Interface.openWindow("initind_select", "");
end
function handleDrop(draginfo)
	if not StringManager.contains({ "image", "portrait", "token" }, draginfo.getType()) then
		return;
	end
	local tData = TokenManager.getTokenActiveOptions();
	tData.sAsset = draginfo.getTokenData();
	TokenManager.setTokenActiveOptions(tData);
end
