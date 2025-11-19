--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals widgetsize

local DEFAULT_SIZE_WIDGET = 28;
local DEFAULT_SIZE_PADDING = 5;

function onInit()
	if widgetsize then
		self.setWidgetSize(tonumber(widgetsize[1]) or DEFAULT_SIZE_WIDGET);
	end

	self.updateDisplay();

	local sName = getName();
	if sName == "token" then
		local nodeActor = window.getDatabaseNode();
		DB.addHandler(DB.getPath(nodeActor, "token"), "onUpdate", self.updateDisplay);
		DB.addHandler(DB.getPath(nodeActor, "token3Dflat"), "onUpdate", self.updateDisplay);
	elseif sName == "picture" then
		local nodeActor = window.getDatabaseNode();
		DB.addHandler(DB.getPath(nodeActor, "picture"), "onUpdate", self.updateDisplay);
	end
end
function onClose()
	local sName = getName();
	if sName == "token" then
		local nodeActor = window.getDatabaseNode();
		DB.removeHandler(DB.getPath(nodeActor, "token"), "onUpdate", self.updateDisplay);
		DB.removeHandler(DB.getPath(nodeActor, "token3Dflat"), "onUpdate", self.updateDisplay);
	elseif sName == "picture" then
		local nodeActor = window.getDatabaseNode();
		DB.removeHandler(DB.getPath(nodeActor, "picture"), "onUpdate", self.updateDisplay);
	end
end

local _nWidgetSize = DEFAULT_SIZE_WIDGET;
function setWidgetSize(n)
	_nWidgetSize = n;
end
function getWidgetSize()
	return _nWidgetSize;
end

local _nPadding = DEFAULT_SIZE_PADDING;
function getPadding()
	return _nPadding;
end

function updateDisplay()
	local sName = getName();
	if sName == "token" then
		self.updateTokenDisplay();
	elseif sName == "picture" then
		self.updatePictureDisplay();
	end
end
function updateTokenDisplay()
	local nWidgetSize = self.getWidgetSize();
	local nHalfWidget = ((nWidgetSize / 2) + (nWidgetSize % 2));
	local nPadding = self.getPadding();

	local nodeActor = window.getDatabaseNode();

	local widgetToken = findWidget("token");
	local sToken = DB.getValue(nodeActor, "token", "");
	if (sToken or "") ~= "" then
		if not widgetToken then
			widgetToken = addBitmapWidget({
				name = "token",
				asset = sToken,
				position = "topleft", x = nHalfWidget, y = nHalfWidget,
				w = nWidgetSize, h = nWidgetSize,
			});
		else
			widgetToken.setAsset(sToken);
		end
	else
		if widgetToken then
			widgetToken.destroy();
			widgetToken = nil;
		end
	end

	local widgetToken3DFlat = findWidget("token3dflat");
	local s3DToken = DB.getValue(nodeActor, "token3Dflat", "");
	if ((s3DToken or "") ~= "") then
		if not widgetToken3DFlat then
			widgetToken3DFlat = addBitmapWidget({
				name = "token3dflat",
				asset = s3DToken,
				position = "topleft", x = nWidgetSize + nPadding + nHalfWidget, y = nHalfWidget,
				w = nWidgetSize, h = nWidgetSize,
			});
		else
			widgetToken3DFlat.setAsset(s3DToken);
		end
	else
		if widgetToken3DFlat then
			widgetToken3DFlat.destroy();
			widgetToken3DFlat = nil;
		end
	end

	if widgetToken and widgetToken3DFlat then
		setAnchoredWidth(nWidgetSize + nPadding + nWidgetSize);
	else
		setAnchoredWidth(nWidgetSize);
	end

	local widgetEmpty = findWidget("empty");
	if not widgetToken and not widgetToken3DFlat then
		if not widgetEmpty then
			addBitmapWidget({
				name = "empty",
				icon = "token_empty",
				position = "topleft", x = nHalfWidget, y = nHalfWidget,
				w = nWidgetSize, h = nWidgetSize,
				});
		end
	else
		if widgetEmpty then
			widgetEmpty.destroy();
		end
	end
end
function updatePictureDisplay()
	local nWidgetSize = self.getWidgetSize();
	local nHalfWidget = ((nWidgetSize / 2) + (nWidgetSize % 2));

	local nodeActor = window.getDatabaseNode();

	local widgetPicture = findWidget("picture");
	local sAsset = DB.getValue(nodeActor, "picture", "");
	if (sAsset or "") ~= "" then
		if not widgetPicture then
			widgetPicture = addBitmapWidget({
				name = "picture",
				asset = sAsset,
				position = "topleft", x = nHalfWidget, y = nHalfWidget,
				w = nWidgetSize, h = nWidgetSize,
			});
		else
			widgetPicture.setAsset(sAsset);
		end
	else
		if widgetPicture then
			widgetPicture.destroy();
			widgetPicture = nil;
		end
	end

	setAnchoredWidth(nWidgetSize);

	local widgetEmpty = findWidget("empty");
	if not widgetPicture then
		if not widgetEmpty then
			addBitmapWidget({
				name = "empty",
				icon = "button_toolbar_image",
				position = "topleft", x = nHalfWidget, y = nHalfWidget,
				w = nWidgetSize, h = nWidgetSize,
				frame = "border",
				color = Interface.getFontColor("recordsheet_header"),
				});
		end
	else
		if widgetEmpty then
			widgetEmpty.destroy();
		end
	end
end

function onClickDown()
	return true;
end
function onClickRelease()
	return RecordAssetManager.handlePicturePressed(window.getDatabaseNode(), window);
end
function onDragStart(_, _, _, draginfo)
	return RecordAssetManager.handlePictureDragStart(window.getDatabaseNode(), draginfo);
end
function onDrop(_, _, draginfo)
	if not isReadOnly() then
		return RecordAssetManager.handlePictureDrop(window.getDatabaseNode(), draginfo, getName());
	end
end
