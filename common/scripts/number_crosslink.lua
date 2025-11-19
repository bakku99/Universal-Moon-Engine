--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _bLocked = false;
local _sLink = nil;

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	if self.update then
		self.update();
	end
end
function onClose()
	if _sLink then
		DB.removeHandler(_sLink, "onUpdate", self.onLinkUpdated);
	end
end

function hasLink()
	return (_sLink ~= nil);
end
function setLink(dbnode, bLock)
	if _sLink then
		DB.removeHandler(_sLink, "onUpdate", self.onLinkUpdated);
		_sLink = nil;
	end

	if dbnode then
		_sLink = DB.getPath(dbnode);

		setReadOnly(bLock or false);

		DB.addHandler(_sLink, "onUpdate", self.onLinkUpdated);
		self.onLinkUpdated();
	else
		setReadOnly(false);
	end
end
function onLinkUpdated()
	if _sLink and not _bLocked then
		_bLocked = true;

		setValue(DB.getValue(_sLink, 0));

		if self.update then
			self.update();
		end

		_bLocked = false;
	end
end

function onValueChanged()
	if _sLink then
		if not _bLocked then
			_bLocked = true;

			if _sLink and not isReadOnly() then
				DB.setValue(_sLink, "number", getValue());
			end

			if self.update then
				self.update();
			end

			_bLocked = false;
		end
	else
		if self.update then
			self.update();
		end
	end
end

function onDrop(_, _, draginfo)
	if Session.IsHost then
		if draginfo.getType() ~= "number" then
			return false;
		end

		if self.handleDrop then
			self.handleDrop(draginfo);
			return true;
		end
	end
end
