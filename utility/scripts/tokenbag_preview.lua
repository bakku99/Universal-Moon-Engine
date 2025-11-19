--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _sAssetName;
local _sAssetType;
function getData()
	return _sAssetName, _sAssetType;
end
function setData(sAssetName, sAssetType)
	_sAssetName = sAssetName;
	_sAssetType = sAssetType;

	preview.setAsset(_sAssetName);

	sub_buttons.setVisible(Session.IsHost and ((_sAssetType or "") == "image"));

	local sModule;
	local tModuleSplit = StringManager.splitByPattern(_sAssetName, "@");
	if #tModuleSplit > 1 then
		sModule = table.concat(tModuleSplit, "@", 2);
	end
	if (sModule or "") ~= "" then
		sub_path.subwindow.module.setValue(ModuleManager.getModuleDisplayName(sModule));
	else
		sub_path.subwindow.module_label.setVisible(false);
		sub_path.subwindow.module.setVisible(false);
	end
	local tPath = StringManager.split(tModuleSplit[1], "/");
	if #tPath > 1 then
		tPath[#tPath] = nil;
		sub_path.subwindow.path.setValue(table.concat(tPath, "/"));
	else
		sub_path.subwindow.path_label.setVisible(false);
		sub_path.subwindow.path.setVisible(false);
	end
end

function handleDrag(draginfo)
	if (_sAssetType or "") ~= "" then
		draginfo.setType(_sAssetType);
		draginfo.setTokenData(_sAssetName);
		return true;
	end
end

function onQuickMapClicked()
	if (_sAssetType or "") ~= "" then
		QuickMapManager.openWindowWithAsset(_sAssetName);
		close();
	end
end
function onShareClicked()
	if (_sAssetType or "") ~= "" then
		PictureManager.createPictureItem(_sAssetName);
		close();
	end
end
function onShareByNameClicked()
	if (_sAssetType or "") ~= "" then
		PictureManager.createPictureItem(_sAssetName, UtilityManager.getAssetBaseFileName(_sAssetName));
		close();
	end
end
function onImportClicked()
	if (_sAssetType or "") ~= "" then
		CampaignDataManager.createImageRecordFromAsset(_sAssetName, true);
		close();
	end
end
function onDecalClicked()
	if (_sAssetType or "") ~= "" then
		DecalManager.setDecal(_sAssetName);
		close();
	end
end
