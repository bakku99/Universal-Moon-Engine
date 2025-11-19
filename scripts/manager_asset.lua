--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	Interface.addKeyedEventHandler("onHotkeyActivated", "image", AssetManager.onImageHotKeyActivate);
	Interface.addKeyedEventHandler("onHotkeyActivated", "token", AssetManager.onTokenHotKeyActivate);
	Interface.addKeyedEventHandler("onHotkeyActivated", "portrait", AssetManager.onPortraitHotKeyActivate);

	ChatManager.registerDropCallback("image", AssetManager.onImageChatDrop);
	ChatManager.registerDropCallback("token", AssetManager.onTokenChatDrop);
	ChatManager.registerDropCallback("portrait", AssetManager.onPortraitChatDrop);
end

function onImageHotKeyActivate(draginfo)
	AssetManager.openAssetPreview(draginfo.getTokenData(), "image");
	return true;
end
function onTokenHotKeyActivate(draginfo)
	AssetManager.openAssetPreview(draginfo.getTokenData(), "token");
	return true;
end
function onPortraitHotKeyActivate(draginfo)
	AssetManager.openAssetPreview(draginfo.getTokenData(), "portrait");
	return true;
end

function onImageChatDrop(draginfo)
	if Session.IsHost then
		PictureManager.createPictureItem(draginfo.getTokenData(), "");
	else
		AssetManager.openAssetPreview(draginfo.getTokenData(), "image");
	end
	return true;
end
function onTokenChatDrop(draginfo)
	local _, tokenMap = draginfo.getTokenData();
	if tokenMap then
		return true;
	end
	if Session.IsHost then
		PictureManager.createPictureItem(draginfo.getTokenData(), "");
	else
		AssetManager.openAssetPreview(draginfo.getTokenData(), "token");
	end
	return true;
end
function onPortraitChatDrop(draginfo)
	if Session.IsHost then
		PictureManager.createPictureItem(draginfo.getTokenData(), "");
	else
		AssetManager.openAssetPreview(draginfo.getTokenData(), "portrait");
	end
	return true;
end

function onAssetFieldPressed(sField, sAsset)
	AssetManager.onAssetPressed(sAsset, AssetManager.getAssetTypeFromField(sField));
end
function onAssetFieldDrag(sField, sAsset, draginfo)
	return AssetManager.onAssetDrag(sAsset, AssetManager.getAssetTypeFromField(sField), draginfo);
end
function onAssetFieldAdd(sField)
	local sAssetType = AssetManager.getAssetTypeFromField(sField);
	local w = Interface.openWindow("tokenbag", "");
	AssetWindowManager.setViewLink(w, { sFilterType = sAssetType }, true);
end

function onAssetPressed(sAsset, sAssetType)
	AssetManager.openAssetPreview(sAsset, sAssetType);
end
function onAssetDrag(sAsset, sAssetType, draginfo)
	if (sAsset or "") == "" then
		return;
	end
	draginfo.setType(sAssetType);
	draginfo.setTokenData(sAsset);
	return true;
end

function getAssetTypeFromField(sField)
	if sField == "token" then
		return "token";
	elseif sField == "portrait" then
		return "portrait";
	end
	-- "picture" / "token3Dflat"
	return "image";
end

function openAssetPreview(sAsset, sAssetType)
	if ((sAsset or "") == "") then
		return;
	end
	local wPreview = Interface.openWindow("asset_preview", "");
	if wPreview then
		wPreview.setData(sAsset, sAssetType);
	end
end
