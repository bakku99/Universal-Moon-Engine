--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

function onInit()
	self.onAuthTokenChanged();
	self.onSessionChanged();
	DB.addHandler(SoundManagerSyrinscape.PATH_AUTHTOKEN, "onUpdate", self.onAuthTokenChanged);
	DB.addHandler(SoundManagerSyrinscape.PATH_SESSION, "onUpdate", self.onSessionChanged);
end
function onClose()
	DB.removeHandler(SoundManagerSyrinscape.PATH_AUTHTOKEN, "onUpdate", self.onAuthTokenChanged);
	DB.removeHandler(SoundManagerSyrinscape.PATH_SESSION, "onUpdate", self.onSessionChanged);
end

function onAuthTokenChanged()
	if SoundManagerSyrinscape.checkAuthToken(false) then
		sub_system.setFrame(nil);
	else
		sub_system.setFrame("fieldrequired", 0, 0, 0, 0);
	end
end
function onSessionChanged()
	if SoundManagerSyrinscape.checkSession() then
		sub_session.setFrame(nil);
	else
		sub_session.setFrame("fieldrequired", 0, 0, 0, 0);
	end
end
