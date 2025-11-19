--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onFactionChanged();
end

function onFactionChanged()
	self.updateDisplay();
end
function onActiveChanged()
	self.updateDisplay();
end
function onIDChanged()
	local nodeRecord = getDatabaseNode();
	local sClass = link.getValue();
	local sRecordType = RecordDataManager.getRecordTypeFromDisplayClass(sClass);
	local bID = RecordDataManager.getIDState(sRecordType, nodeRecord, true);

	name.setVisible(bID);
	nonid_name.setVisible(not bID);

	self.onActiveChanged();
end

function onLinkChanged()
	self.onIDChanged();
end

function updateDisplay()
	local sFaction = friendfoe.getValue();

	if initresult then
		local sOptCTSI = OptionsManager.getOption("CTSI");
		local bShowInit = ((sOptCTSI == "friend") and (sFaction == "friend")) or (sOptCTSI == "on");
		initresult.setVisible(bShowInit);
	end

	if active.getValue() == 1 then
		name.setFont("sheetlabel");
		nonid_name.setFont("sheetlabel");

		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);

		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end

		windowlist.scrollToWindow(self);
	else
		name.setFont("sheettext");
		nonid_name.setFont("sheettext");

		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);

		if sFaction == "friend" then
			setFrame("ctentrybox_friend");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe");
		else
			setFrame("ctentrybox");
		end
	end
end

--
--	HELPERS
--

function getRecordType()
	local sClass = link.getValue();
	return RecordDataManager.getRecordTypeFromDisplayClass(sClass);
end
function isRecordType(s)
	return (self.getRecordType() == s);
end
function isPC()
	return self.isRecordType("charsheet");
end
function isActive()
	return (active.getValue() == 1);
end

--
--	SECTION HANDLING
--

function getSectionToggle(sKey)
	local bResult = false;

	local sButtonName = "button_section_" .. sKey;
	local cButton = self[sButtonName];
	if cButton then
		bResult = (cButton.getValue() == 1);
	end

	return bResult;
end
function onSectionChanged(sKey)
	local bShow = self.getSectionToggle(sKey);

	local sSectionName = "sub_" .. sKey;
	local cSection = self[sSectionName];
	if cSection then
		if bShow then
			local sSectionClassByRecord = string.format("client_ct_section_%s_%s", sKey, self.getRecordType());
			if Interface.isWindowClass(sSectionClassByRecord) then
				cSection.setValue(sSectionClassByRecord, getDatabaseNode());
			else
				local sSectionClass = "client_ct_section_" .. sKey;
				cSection.setValue(sSectionClass, getDatabaseNode());
			end
		else
			cSection.setValue("", "");
		end
		cSection.setVisible(bShow);
	end

	local sSummaryName = "summary_" .. sKey;
	local cSummary = self[sSummaryName];
	if cSummary then
		cSummary.onToggle();
	end
end
