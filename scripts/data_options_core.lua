--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- DEFAULT BEHAVIORS FOR OPTIONS: sType = "option_entry_cycler", on|off, default = off
function onInit()
	OptionsManager.registerOptionData({	sKey = "COLOR", bLocal = true, sType = "option_entry_colorselect_user", });
	OptionsManager.registerOptionData({	sKey = "MANUALROLL", bLocal = true, });
	OptionsManager.registerOptionData({
		sKey = "CMAT", bLocal = true,
		tCustom = {
			labelsres = "option_val_center|option_val_select",
			values = "on|select",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "on",
		},
	});
	OptionsManager.registerOptionData({	sKey = "CWHR", bLocal = true, tCustom = { default = "on", }, });
	OptionsManager.registerOptionData({	sKey = "WSAV", bLocal = true, tCustom = { default = "on", }, });

	OptionsManager.registerOptionData({	sKey = "CTAV", sGroupRes = "option_header_game", });
	OptionsManager.registerOptionData({	sKey = "DRMO", sGroupRes = "option_header_game", });
	OptionsManager.registerOptionData({	sKey = "SHPW", sGroupRes = "option_header_game", });
	OptionsManager.registerOptionData({	sKey = "REVL", sGroupRes = "option_header_game", tCustom = { default = "on", }, });
	OptionsManager.registerOptionData({	sKey = "TBOX", sGroupRes = "option_header_game", });
	OptionsManager.registerOptionData({
		sKey = "CLSH", sGroupRes = "option_header_game",
		tCustom = {
			labelsres = "option_val_active",
			values = "active",
			baselabelres = "option_val_all",
			baseval = "all",
			default = "all",
		},
	});
	OptionsManager.registerOptionData({	sKey = "PSIN", sGroupRes = "option_header_game", });
	OptionsManager.registerOptionData({	sKey = "PSMN", sGroupRes = "option_header_game", });

	OptionsManager.registerOptionData({
		sKey = "NNPC", sGroupRes = "option_header_combat",
		tCustom = {
			labelsres = "option_val_append|option_val_random",
			values = "append|random",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "append",
		},
	});
	OptionsManager.registerOptionData({	sKey = "RING", sGroupRes = "option_header_combat", });
	OptionsManager.registerOptionData({
		sKey = "CTSI", sGroupRes = "option_header_combat",
		tCustom = {
			labelsres = "option_val_all|option_val_friendly",
			values = "on|friend",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "on",
		},
	});
	OptionsManager.registerOptionData({	sKey = "RSHE", sGroupRes = "option_header_combat", });
	OptionsManager.registerOptionData({	sKey = "CTSD", sGroupRes = "option_header_combat", });
	OptionsManager.registerOptionData({	sKey = "CTSH", sGroupRes = "option_header_combat", });

	OptionsManager.registerOptionData({
		sKey = "INITIND", sGroupRes = "option_header_token", sType = "option_entry_assetselectinit",
	});
	OptionsManager.registerOptionData({
		sKey = "TASG", sGroupRes = "option_header_token",
		tCustom = {
			labelsres = "option_val_scale80|option_val_scale100",
			values = "80|100",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "80",
		},
	});
	OptionsManager.registerOptionData({	sKey = "TFAC", sGroupRes = "option_header_token", });
	OptionsManager.registerOptionData({	sKey = "TPTY", sGroupRes = "option_header_token", });
	OptionsManager.registerOptionData({
		sKey = "TNAM", sGroupRes = "option_header_token",
		tCustom = {
			labelsres = "option_val_tooltip|option_val_title|option_val_titlehover",
			values = "tooltip|on|hover",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "tooltip",
		},
	});
	OptionsManager.registerOptionData({
		sKey = "TFOW", sGroupRes = "option_header_token",
		tCustom = {
			labelsres = "option_val_on|option_val_pc",
			values = "on|pc",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "pc",
		},
	});
	OptionsManager.registerOptionData({
		sKey = "INITIND", sGroupRes = "option_header_token", sType = "option_entry_assetselectinit",
	});

	OptionsManager.registerOptionData({
		sKey = "HRDD", sGroupRes = "option_header_houserule",
		tCustom = {
			labelsres = "option_val_x1|option_val_x1_5|option_val_raw",
			values = "x1|variant|raw",
			baselabelres = "option_val_default",
			baseval = "",
			default = "",
		},
	});

	OptionsManager.registerButton("option_label_currencies", "currencylist", "currencies");
	OptionsManager.registerButton("option_label_languages", "languagelist", "languages");
	OptionsManager.registerButton("option_label_motd", "motd", "motd");
	OptionsManager.registerButton("option_label_setup", "setup", "");
	OptionsManager.registerButton("option_label_tokenlights", "tokenlightlist", "settings.tokenlight");
	if Session.IsHost then
		OptionsManager.registerButton("option_label_decalselect", "decal_select", "");
	end
end
