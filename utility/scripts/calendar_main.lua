--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals list.scrollToCampaignDate list.rebuildCalendarWindows

local aEvents = {};
local nSelMonth = 0;
local nSelDay = 0;

function onInit()
	nSelMonth = DB.getValue("calendar.current.month", 0);
	nSelDay = DB.getValue("calendar.current.day", 0);

	DB.addHandler("calendar.log", "onChildUpdate", self.onEventsChanged);
	DB.addHandler("calendar.current.day", "onUpdate", self.onDateChanged);
	DB.addHandler("calendar.current.month", "onUpdate", self.onDateChanged);
	DB.addHandler("calendar.current.year", "onUpdate", self.onYearChanged);
	DB.addHandler("calendar.current.hour", "onUpdate", self.onTimeChanged);
	DB.addHandler("calendar.current.minute", "onUpdate", self.onTimeChanged);

	self.buildEvents();
	self.onDateChanged();
end
function onClose()
	DB.removeHandler("calendar.log", "onChildUpdate", self.onEventsChanged);
	DB.removeHandler("calendar.current.day", "onUpdate", self.onDateChanged);
	DB.removeHandler("calendar.current.month", "onUpdate", self.onDateChanged);
	DB.removeHandler("calendar.current.year", "onUpdate", self.onYearChanged);
	DB.removeHandler("calendar.current.hour", "onUpdate", self.onTimeChanged);
	DB.removeHandler("calendar.current.minute", "onUpdate", self.onTimeChanged);
end

local bEnableBuild = true;
function onEventsChanged(bListChanged)
	if bListChanged then
		if bEnableBuild then
			self.buildEvents();
			self.updateDisplay();
		end
	end
end
function buildEvents()
	aEvents = {};

	for _,v in ipairs(DB.getChildList("calendar.log")) do
		local nYear = DB.getValue(v, "year", 0);
		local nMonth = DB.getValue(v, "month", 0);
		local nDay = DB.getValue(v, "day", 0);

		if not aEvents[nYear] then
			aEvents[nYear] = {};
		end
		if not aEvents[nYear][nMonth] then
			aEvents[nYear][nMonth] = {};
		end
		aEvents[nYear][nMonth][nDay] = v;
	end
end

function onTimeChanged()
	sub_date.subwindow.currenthour.setValue(CalendarManager.getDisplayHour());
	sub_date.subwindow.currentminute.setValue(CalendarManager.getDisplayMinute());
	sub_date.subwindow.currentphase.setValue(CalendarManager.getDisplayHourPhase())
end
function onDateChanged()
	self.updateDisplay();
	list.scrollToCampaignDate();
	self.onTimeChanged();
end
function onYearChanged()
	list.rebuildCalendarWindows();
	self.onDateChanged();
end
function onCalendarChanged()
	list.rebuildCalendarWindows();
	self.setSelectedDate(DB.getValue("calendar.current.month", 0), DB.getValue("calendar.current.day", 0));
end

function updateDisplay()
	local sCampaignEpoch = DB.getValue("calendar.current.epoch", 0);
	local nCampaignYear = DB.getValue("calendar.current.year", 0);
	local nCampaignMonth = DB.getValue("calendar.current.month", 0);
	local nCampaignDay = DB.getValue("calendar.current.day", 0);

	local sDate = CalendarManager.getDateString(sCampaignEpoch, nCampaignYear, nCampaignMonth, nCampaignDay, true, true);
	sub_date.subwindow.viewdate.setValue(sDate);

	if aEvents[nCampaignYear] and
			aEvents[nCampaignYear][nSelMonth] and
			aEvents[nCampaignYear][nSelMonth][nSelDay] then
		sub_buttons.subwindow.button_view.setVisible(true);
		sub_buttons.subwindow.button_addlog.setVisible(false);
	else
		sub_buttons.subwindow.button_view.setVisible(false);
		sub_buttons.subwindow.button_addlog.setVisible(true);
	end

	for _,v in pairs(list.getWindows()) do
		local nMonth = v.month.getValue();

		local bCampaignMonth = false;
		local bLogMonth = false;
		if nMonth == nCampaignMonth then
			bCampaignMonth = true;
		end
		if nMonth == nSelMonth then
			bLogMonth = true;
		end

		if bCampaignMonth then
			v.label_period.setColor(ColorManager.getUIColor("calendar_month"));
		else
			v.label_period.setColor("");
		end

		for _,y in pairs(v.list_days.getWindows()) do
			local nDay = y.day.getValue();
			if nDay > 0 then
				local nodeEvent = nil;
				if aEvents[nCampaignYear] and aEvents[nCampaignYear][nMonth] and aEvents[nCampaignYear][nMonth][nDay] then
					nodeEvent = aEvents[nCampaignYear][nMonth][nDay];
				end

				local bHoliday = CalendarManager.isHoliday(nMonth, nDay);
				local bCurrDay = (bCampaignMonth and nDay == nCampaignDay);
				local bSelDay = (bLogMonth and nDay == nSelDay);

				y.setState(bCurrDay, bSelDay, bHoliday, nodeEvent);
			end
		end
	end
end

function setSelectedDate(nMonth, nDay)
	nSelMonth = nMonth;
	nSelDay = nDay;

	self.updateDisplay();
	list.scrollToCampaignDate();
end
function onSetButtonPressed()
	if Session.IsHost then
		CalendarManager.setCurrentDay(nSelDay);
		CalendarManager.setCurrentMonth(nSelMonth);
	end
end

function addLogEntryToSelected()
	self.addLogEntry(nSelMonth, nSelDay);
end
function addLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear();

	local nodeEvent;
	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		nodeEvent = aEvents[nYear][nMonth][nDay];
	elseif Session.IsHost then
		local nodeLog = DB.createNode("calendar.log");
		bEnableBuild = false;
		nodeEvent = DB.createChild(nodeLog);

		DB.setValue(nodeEvent, "epoch", "string", DB.getValue("calendar.current.epoch", ""));
		DB.setValue(nodeEvent, "year", "number", nYear);
		DB.setValue(nodeEvent, "month", "number", nMonth);
		DB.setValue(nodeEvent, "day", "number", nDay);
		bEnableBuild = true;

		self.onEventsChanged();
	end

	if nodeEvent then
		Interface.openWindow("advlogentry", nodeEvent);
	end
end
function removeLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear();

	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		local nodeEvent = aEvents[nYear][nMonth][nDay];

		local bDelete = false;
		if Session.IsHost then
			bDelete = true;
		end

		if bDelete then
			DB.deleteNode(nodeEvent);
		end
	end
end
