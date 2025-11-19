--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _bInitialized = false;
function onInit()
	self.initValue();
	super.onInit();
	_bInitialized = true;
end

local _tLastOption,_tCurrentOption;
function initValue()
	_tLastOption = TokenManager.getTokenActiveOptions();
	_tCurrentOption = UtilityManager.copyDeep(_tLastOption);
	sub_buttons.subwindow.placement.setValue(_tCurrentOption.bOver and "over" or "");
end

function onActivate(sAsset)
	if not _bInitialized then
		return;
	end
	_tCurrentOption.sAsset = sAsset;
	TokenManager.setTokenActiveOptions(_tCurrentOption);
end
function onPlacementChange()
	if not _bInitialized then
		return;
	end
	_tCurrentOption.bOver = (sub_buttons.subwindow.placement.getValue() == "over");
	TokenManager.setTokenActiveOptions(_tCurrentOption);
end

function handleFolder()
	Interface.openDataFolder("images/Initiative");
end
function handleDefault()
	_tCurrentOption = { sAsset = "", bOver = false, };
	sub_buttons.subwindow.placement.setValue("");
	TokenManager.setTokenActiveOptions(_tCurrentOption);
end
function handleOK()
	close();
end
function handleCancel()
	TokenManager.setTokenActiveOptions(_tLastOption);
	close();
end
