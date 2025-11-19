--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	-- Show active section, if combatant is active
	self.onActiveChanged();

	-- Acquire token reference, if any
	self.linkToken();

	-- Set up the PC links
	self.onLinkChanged();
	self.onFactionChanged();

	-- Register the deletion menu item for the host
	registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		self.delete();
	end
end

function onLinkChanged()
	-- If a PC, then set up the links to the char sheet
	if self.isPC() then
		self.linkPCFields();
		name.setLine(false);
	end
	self.onIDChanged();
end
function onIDChanged()
	local nodeRecord = getDatabaseNode();
	local sClass = link.getValue();
	local sRecordType = RecordDataManager.getRecordTypeFromDisplayClass(sClass);
	local bID = RecordDataManager.getIDState(sRecordType, nodeRecord, true);

	name.setVisible(bID);
	nonid_name.setVisible(not bID);

	isidentified.setVisible(RecordDataManager.getIDMode(sRecordType));
end
function onFactionChanged()
	-- Update the entry frame
	self.updateDisplay();

	-- If not a friend, then show visibility toggle
	if friendfoe.getValue() == "friend" then
		tokenvis.setVisible(false);
	else
		tokenvis.setVisible(true);
	end
end
function onVisibilityChanged()
	TokenManager.updateVisibility(getDatabaseNode());
	windowlist.onVisibilityToggle();
end
function onActiveChanged()
	self.onSectionChanged("active");
end

function updateDisplay()
	local sFaction = friendfoe.getValue();

	if DB.getValue(getDatabaseNode(), "active", 0) == 1 then
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

function linkToken()
	local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
	if imageinstance then
		TokenManager.linkToken(getDatabaseNode(), imageinstance);
	end
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		name.setLink(DB.createChild(nodeChar, "name", "string"), true);
		token.setLink(DB.createChild(nodeChar, "token", "token"));
		token3Dflat.setLink(DB.createChild(nodeChar, "token3Dflat", "token"));

		if Session.RulesetName == "CoreRPG" then
			senses.setLink(DB.createChild(nodeChar, "senses", "string"), true);
		end
	end
end

function delete()
	CombatManager.deleteCombatant(getDatabaseNode());
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
		if (sKey == "active") and self.isActive() and not self.isPC() then
			bResult = true;
		end
	end

	return bResult;
end
function onSectionChanged(sKey)
	local bShow = self.getSectionToggle(sKey);

	local sSectionName = "sub_" .. sKey;
	local cSection = self[sSectionName];
	if cSection then
		if bShow then
			local sSectionClassByRecord = string.format("ct_section_%s_%s", sKey, self.getRecordType());
			if Interface.isWindowClass(sSectionClassByRecord) then
				cSection.setValue(sSectionClassByRecord, getDatabaseNode());
			else
				local sSectionClass = "ct_section_" .. sKey;
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
