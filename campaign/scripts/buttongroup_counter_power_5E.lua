--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	DATA
--

local _bCountInitialized = false;
local _bPrepMode = false;
local _bSpontaneous = false;
local _nAvailable = 0;
local _nTotalCast = 0;
function update(sNewSheetMode, bNewSpontaneous, nNewAvailable, nNewTotalCast)
	_bPrepMode = ((sNewSheetMode or "") == "preparation");
	_bSpontaneous = bNewSpontaneous;
	_nAvailable = nNewAvailable;
	_nTotalCast = nNewTotalCast;
	_bCountInitialized = true;

	self.refreshDisplay();
end

function adjustCounter(nAdj)
	if not _bCountInitialized then
		return;
	end

	if _bPrepMode then
		if _bSpontaneous then
			return true;
		end

		local nVal = self.getVarNumber("prepared") + nAdj;
		self.setVarNumber("prepared", math.max(math.min(nVal, _nAvailable), 0));
	else
		local nVal = self.getVarNumber("cast") + nAdj;
		local nMax;
		if _bSpontaneous then
			nMax = nVal - (_nTotalCast + nAdj - _nAvailable);
		else
			nMax = self.getVarNumber("prepared");
		end
		self.setVarNumber("cast", math.max(math.min(nVal, nMax), 0));
	end
end

function getMaxValue()
	local nMax;
	if _bPrepMode then
		nMax = _nAvailable;
	else
		if _bSpontaneous then
			nMax = self.getVarNumber("cast") - (_nTotalCast - _nAvailable);
		else
			nMax = self.getVarNumber("prepared");
		end
	end
	return nMax;
end

--
--	DISPLAY
--

function getSlotCount()
	if _bSpontaneous then
		return _bPrepMode and 0 or _nAvailable;
	end
	return _bPrepMode and _nAvailable or self.getVarNumber("prepared");
end
function getSlotIcon(n)
	local nCurr;
	if _bSpontaneous then
		nCurr = _bPrepMode and 0 or _nTotalCast;
	else
		nCurr = _bPrepMode and self.getVarNumber("prepared") or self.getVarNumber("cast");
	end
	return (n > nCurr) and self.getMetadata("icon_off") or self.getMetadata("icon_on");
end
function getSlotColor(n)
	if not _bSpontaneous then
		return self.getMetadata("color_full");
	end

	local nCurr = _bPrepMode and 0 or _nTotalCast;
	return ((n <= nCurr) and (n > self.getVarNumber("cast"))) and self.getMetadata("color_disabled") or self.getMetadata("color_full");
end

--
--	UI EVENTS
--

function onClickRelease(_, x, y)
	if isReadOnly() then
		return;
	end

	if _bPrepMode then
		if self.calcClickValue(x, y) > self.getVarNumber("prepared") then
			self.adjustCounter(1);
		else
			self.adjustCounter(-1);
		end
	else
		local nCurrent = self.getVarNumber("cast");
		if _bSpontaneous then
			if self.calcClickValue(x, y) > _nTotalCast then
				self.adjustCounter(1);
			elseif nCurrent > 0 then
				self.adjustCounter(-1);
			end
		else
			if self.calcClickValue(x, y) > nCurrent then
				self.adjustCounter(1);
			else
				self.adjustCounter(-1);
			end
		end
		if self.getVarNumber("cast") > nCurrent then
			PowerManagerCore.usePower(window.getDatabaseNode());
		end
	end

	return true;
end
