--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

ASSET_WIDTH = 40;
ASSET_HEIGHT = 40;

function onTabletopInit()
	if Session.IsHost then
		Comm.registerSlashHandler("gmid", ChatIdentityManager.slashCommandHandlerGMId, "[name]");
		Comm.registerSlashHandler("id", ChatIdentityManager.slashCommandHandlerId, "[name]");
	end
	ChatManager.registerDeliverMessageCallback(ChatIdentityManager.onChatDeliverMessage);

	if Session.IsHost then
		ChatIdentityManager.initGMIdentity();
	end
	ChatIdentityManager.refreshIdentityList();
end

--
--	CHAT MESSAGE AND COMMAND HANDLING
--

function slashCommandHandlerId(_, sParams)
	ChatIdentityManager.addIdentity(sParams);
end
function slashCommandHandlerGMId(_, sParams)
	ChatIdentityManager.setGMIdentity(sParams);
end

-- NOTE: Do not return true, since we want standard processing to continue
function onChatDeliverMessage(msg, sMode)
	if sMode == "chat" then
		if Session.IsHost then
			local sSender = msg.sender or "";
			if (sSender == "") or (sSender == User.getUsername()) then
				local sSpeaker, tAsset = ChatIdentityManager.getCurrentIdentityAndAsset();
				if tAsset then
					msg.assets = msg.assets or {};
					table.insert(msg.assets, tAsset);
				end
				msg.sender = sSpeaker;
				if ChatIdentityManager.isGMIdentity(sSpeaker) then
					msg.font = "chatgmfont";
				else
					msg.font = "chatnpcfont";
				end
			else
				local tAsset = ChatIdentityManager.getAssetByName(sSender);
				if tAsset then
					msg.assets = msg.assets or {};
					table.insert(msg.assets, tAsset);
				end
				msg.font = "chatnpcfont";
			end
		end

		if #(msg.assets or {}) == 0 then
			local tAsset = ChatIdentityManager.getDefaultAsset();
			if tAsset then
				msg.assets = msg.assets or {};
				table.insert(msg.assets, tAsset);
			end
		end
	elseif sMode == "emote" then
		if Session.IsHost then
			local sSender = msg.sender or "";
			local sSpeaker, tAsset = ChatIdentityManager.getCurrentIdentityAndAsset(sSender);
			if tAsset then
				msg.assets = msg.assets or {};
				table.insert(msg.assets, tAsset);
			end
			if not ChatIdentityManager.isGMIdentity(sSpeaker) then
				msg.sender = "";
				msg.text = sSpeaker .. " " .. msg.text;
			end
		end
	end
end

--
--	SPEAKER MANAGEMENT
--

local _sCurrentIdentity = nil;
function getCurrentIdentity()
	return _sCurrentIdentity;
end
function getCurrentIdentityAndAsset()
	local s = ChatIdentityManager.getCurrentIdentity();

	local tAsset = nil;
	local tData = ChatIdentityManager.getIdentityData(s);
	if tData and tData.nodeActor then
		tAsset = ChatIdentityManager.getActorAsset(ActorManager.resolveActor(tData.nodeActor));
	end
	return s, tAsset;
end
function setCurrentIdentity(s)
	if not ChatIdentityManager.isIdentity(s) then
		return;
	end
	_sCurrentIdentity = s;
	ChatIdentityManager.updateIdentityList();
end
function setCurrentIdentityToGMIdentity()
	ChatIdentityManager.setCurrentIdentity(ChatIdentityManager.getGMIdentity());
end

local _sGMIdentity = "";
function initGMIdentity()
	_sGMIdentity = CampaignRegistry.gmidentity or Interface.getString("gmid_default");
	if _sGMIdentity == "" then
		_sGMIdentity = User.getUsername();
	end
	_sGMIdentity = StringManager.trim(_sGMIdentity);

	ChatIdentityManager.setCurrentIdentityToGMIdentity();
end
function isGMIdentity(s)
	if not s then
		return false;
	end
	return (s == ChatIdentityManager.getGMIdentity());
end
function getGMIdentity()
	return _sGMIdentity;
end
function setGMIdentity(s)
	s = StringManager.trim(s);

	if not ChatIdentityManager.isGMIdentity(s) then
		ChatIdentityManager.removeIdentity(s);

		if (s or "") == "" then
			_sGMIdentity = StringManager.trim(Interface.getString("gmid_default"));
			CampaignRegistry.gmidentity = nil;
		else
			_sGMIdentity = s;
			CampaignRegistry.gmidentity = s;
		end

		ChatIdentityManager.refreshIdentityList();
	end

	ChatIdentityManager.setCurrentIdentityToGMIdentity();
end

local _tIdentities = {};
function getAllIdentityData()
	return _tIdentities;
end
function getIdentityData(s)
	if ChatIdentityManager.isGMIdentity(s) then
		return nil;
	end
	return _tIdentities[s];
end
function isIdentity(s)
	if (s or "") == "" then
		return false;
	end
	return ChatIdentityManager.isGMIdentity(s) or (_tIdentities[s] ~= nil);
end
function addIdentity(s, nodeActor)
	s = StringManager.trim(s);
	if (s or "") == "" then
		return;
	end

	if not ChatIdentityManager.isIdentity(s) then
		_tIdentities[s] = { nodeActor = nodeActor, };
		ChatIdentityManager.refreshIdentityList();
	end

	ChatIdentityManager.setCurrentIdentity(s);
end
function removeIdentity(s)
	if not s then
		return;
	end
	s = StringManager.trim(s);
	if ChatIdentityManager.isGMIdentity(s) then
		return;
	end
	if not _tIdentities[s] then
		return;
	end

	if ChatIdentityManager.getCurrentIdentity() == s then
		ChatIdentityManager.setCurrentIdentityToGMIdentity();
	end

	_tIdentities[s] = nil;
	ChatIdentityManager.refreshIdentityList();
end

local _sActiveCombatant = nil;
function addCombatantIdentity(nodeCT)
	if not OptionsManager.isOption("CTAV", "on") then
		return;
	end

	if CombatManager.isPlayerCT(nodeCT) then
		_sActiveCombatant = nil;
		ChatIdentityManager.setCurrentIdentityToGMIdentity();
		return;
	end

	local s = ActorManager.getDisplayName(nodeCT);
	if (s or "") == "" then
		_sActiveCombatant = nil;
		ChatIdentityManager.setCurrentIdentityToGMIdentity();
	else
		if ChatIdentityManager.isIdentity(s) then
			_sActiveCombatant = nil;
			ChatIdentityManager.setCurrentIdentity(s);
		else
			_sActiveCombatant = s;
			ChatIdentityManager.addIdentity(s, nodeCT);
		end
	end
end
function clearCombatantIdentity()
	if not _sActiveCombatant then
		return;
	end
	ChatIdentityManager.removeIdentity(_sActiveCombatant);
	_sActiveCombatant = nil;
end

--
--	MISC
--

-- Portrait Determination: Actor Param, Active Identity/User
function getActorAsset(rActor)
	local tAsset = ChatIdentityManager.getActorAssetHelper(rActor);
	if tAsset then
		return tAsset;
	end
	return ChatIdentityManager.getDefaultAsset();
end
function getActorAssetHelper(rActor)
	if not rActor then
		return nil;
	end
	if ActorManager.isPC(rActor) then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		if nodeActor then
			local tAsset = ChatIdentityManager.getIdentityAsset(DB.getName(nodeActor));
			tAsset.sActorPath = DB.getPath(nodeActor);
			return tAsset;
		end
	else
		local sToken;
		local nodeActor = ActorManager.getCreatureNode(rActor);
		if nodeActor then
			sToken = DB.getValue(nodeActor, "token", "");
			if (sToken or "") == "" then
				sToken = DB.getValue(nodeActor, "picture", "");
				if (sToken or "") == "" then
					sToken = DB.getValue(nodeActor, "token3Dflat", "");
				end
			end
		end

		sToken = UtilityManager.resolveDisplayToken(sToken, ActorManager.getDisplayName(rActor));
		if (sToken or "") ~= "" then
			return {
				name = sToken,
				sActorPath = nodeActor and DB.getPath(nodeActor),
				w = ChatIdentityManager.ASSET_WIDTH,
				h = ChatIdentityManager.ASSET_HEIGHT,
			};
		end
	end
	return nil;
end
function getDefaultAsset()
	if Session.IsHost then
		return ChatIdentityManager.getIdentityAsset();
	end

	local sIdentity = User.getCurrentIdentity();
	if sIdentity then
		return ChatIdentityManager.getIdentityAsset(sIdentity);
	end

	return nil;
end
function getIdentityAsset(sIdentity)
	if (sIdentity or "") == "" then
		return {
			type = "icon",
			name = "portrait_gm_token",
			w = ChatIdentityManager.ASSET_WIDTH,
			h = ChatIdentityManager.ASSET_HEIGHT,
		};
	end
	return {
		type = "icon",
		name = string.format("portrait_%s_charlist", sIdentity),
		w = ChatIdentityManager.ASSET_WIDTH,
		h = ChatIdentityManager.ASSET_HEIGHT,
	};
end
function getAssetByName(s)
	if (s or "") == "" then
		return nil;
	end
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		if DB.getValue(v, "name", "") == s then
			return ChatIdentityManager.getActorAsset(ActorManager.resolveActor(v));
		end
	end
	local nodeActor = RecordManager.findRecordByString("npc", "name", s);
	if nodeActor then
		return ChatIdentityManager.getActorAsset(ActorManager.resolveActor(nodeActor));
	end
	return nil;
end

function getDiceTowerAsset()
	return {
		type = "icon",
		name = "dicetower_icon",
		w = ChatIdentityManager.ASSET_WIDTH,
		h = ChatIdentityManager.ASSET_HEIGHT,
	};
end

-- Sender Label Order Determination: Actor Param, User Param, Active Identity/User
function getSenderDisplayName(rActor, sUser)
	if rActor then
		return ActorManager.getDisplayName(rActor);
	end
	if (sUser or "") ~= "" then
		return sUser;
	end

	local sSender = (Session.IsHost and ChatIdentityManager.getCurrentIdentity()) or User.getIdentityLabel();
	if (sSender or "") ~= "" then
		return sSender;
	end

	return User.getUsername();
end

function updateIdentityList()
	if not Session.IsHost then
		return;
	end

	local w = ChatManager.getChatWindow();
	if not w then
		return;
	end

	w.speaker.setListValue(ChatIdentityManager.getCurrentIdentity());
end
function refreshIdentityList()
	if not Session.IsHost then
		return;
	end

	local w = ChatManager.getChatWindow();
	if not w then
		return;
	end

	local tNewValues = {};
	for s,_ in pairs(ChatIdentityManager.getAllIdentityData()) do
		table.insert(tNewValues, s);
	end
	table.sort(tNewValues);

	w.speaker.clear();
	w.speaker.add("", ChatIdentityManager.getGMIdentity());
	for _,s in ipairs(tNewValues) do
		w.speaker.add(s, nil, true);
	end
	w.speaker.setListValue(ChatIdentityManager.getCurrentIdentity());
end
