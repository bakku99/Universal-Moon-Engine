--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _sDefaultAsset = "images/decals/swk_decal.png@SmiteWorks Assets";

function onInit()
	OptionsManager.registerOptionData({
		sKey = "DECALPOS", sGroupRes = "option_header_game",
		tCustom = { labelsres = "option_val_decalfill|option_val_decalfit", values = "fill|fit", baselabelres = "option_val_decalcenter", baseval = "center", default = "center", },
	});
end

function onTabletopInit()
	if Session.IsHost then
		local nodeCustom = DB.findNode("options.DDCL-custom");
		if not nodeCustom then
			DB.setValue("options.DDCL-custom", "string", _sDefaultAsset);
		end
	end

	DecalManager.update();
	DB.addHandler("options.DDCL-custom", "onAdd", DecalManager.update);
	DB.addHandler("options.DDCL-custom", "onUpdate", DecalManager.update);

	DecalManager.onOptionUpdate();
	OptionsManager.registerCallback("DECALPOS", DecalManager.onOptionUpdate);
end

function onOptionUpdate()
	DecalManager.update();
end
function update()
	local wDecal = Interface.findWindow("desktopdecal", "");
	local wDecalFill = Interface.findWindow("desktopdecalfill", "");
	if OptionsManager.isOption("DECALPOS", "fill") then
		DecalManager.helperSetWindowDecal(wDecal, "");
		DecalManager.helperSetWindowDecal(wDecalFill, DecalManager.getDecal(), "fill");
	elseif OptionsManager.isOption("DECALPOS", "fit") then
		DecalManager.helperSetWindowDecal(wDecal, "");
		DecalManager.helperSetWindowDecal(wDecalFill, DecalManager.getDecal(), "fit");
	else
		DecalManager.helperSetWindowDecal(wDecal, DecalManager.getDecal());
		DecalManager.helperSetWindowDecal(wDecalFill, "");
	end
end
function helperSetWindowDecal(w, sAsset, sDrawMode)
	if not w or not w.decal then
		return;
	end
	w.decal.setAsset(sAsset);
	if sDrawMode then
		w.decal.setDrawMode(sDrawMode);
	end
end

function setDefault(sAsset)
	_sDefaultAsset = sAsset;
end

function getDecal()
	local sAsset = DB.getValue("options.DDCL-custom", "");
	if sAsset == "-" then
		sAsset = "";
	end
	return sAsset;
end
function setDecal(sAsset)
	if not Session.IsHost then
		return;
	end
	DB.setValue("options.DDCL-custom", "string", sAsset or "");
end
function clearDecal()
	if not Session.IsHost then
		return;
	end
	DB.setValue("options.DDCL-custom", "string", "-");
end
