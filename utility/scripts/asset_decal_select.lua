--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _sLastDecal;

function onInit()
	_sLastDecal = DecalManager.getDecal();
	super.onInit();
end

function onActivate(sAsset)
	DecalManager.setDecal(sAsset);
end

function handleClear()
	DecalManager.clearDecal();
end
function handleOK()
	close();
end
function handleCancel()
	DecalManager.setDecal(_sLastDecal);
	close();
end
