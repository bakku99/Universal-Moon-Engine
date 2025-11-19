--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onHover(bOver)
	name.setUnderline(bOver);
	if bOver then
		setFrame("fieldfocus");
	else
		setFrame("");
	end
end

local _bAuxBook = false;
local _sModule = "";
local _sCategory = "";
function isAuxBook()
	return _bAuxBook;
end
function getName()
	return _sModule;
end
function getCategory()
	return _sCategory;
end

function setData(sModule, tInfo)
	_bAuxBook = false;
	_sModule = sModule;
	_sCategory = tInfo.category;

	name.setValue(tInfo.displayname or tInfo.name);
	category.setValue(tInfo.category);
	if Interface.isIcon("module_" .. sModule) then
		thumbnail.setIcon("module_" .. sModule);
	else
		thumbnail.setFrame("border");
	end

	resetMenuItems();
	if Session.IsHost then
		registerMenuItem(Interface.getString("menu_revert"), "shuffle", 8);
	end
	registerMenuItem(Interface.getString("module_unload"), "delete", 6);
end
function setAuxBookData(sModule, tInfo)
	_bAuxBook = true;
	_sModule = sModule;
	_sCategory = tInfo.category;

	name.setValue(tInfo.displayname or tInfo.name);
	category.setValue(tInfo.category);
	thumbnail.setIcon("textlist");

	resetMenuItems();
end

function activate()
	if _bAuxBook then
		ModuleManager.onLibraryAuxBookActivate(_sModule);
	else
		ModuleManager.onLibraryModuleActivate(_sModule);
	end
end

function onMenuSelection(selection)
	if selection == 8 then
		ModuleManager.performRevert(_sModule);
	elseif selection == 6 then
		Module.deactivate(_sModule);
	end
end
