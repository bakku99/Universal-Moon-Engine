--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	SET OPERATIONS
--

local SetOperations = {};
function SetOperations:count()
	local n = 0;
	for k,_ in pairs(self._items) do
		n = n + 1;
	end
	return n;
end
function SetOperations:add(vParam)
	if not vParam then
		return;
	end

	if SetManager.isSet(vParam) then
		for v,_ in pairs(vParam._items) do
			self._items[v] = true;
		end
	elseif type(vParam) == "table" then
		for _,v in ipairs(vParam) do
			self._items[v] = true;
		end
	else
		self._items[vParam] = true;
	end
end
function SetOperations:remove(vParam)
	if not vParam then
		return false;
	end

	local bResult = false;
	if SetManager.isSet(vParam) then
		for v,_ in pairs(vParam._items) do
			if self._items[v] then
				self._items[v] = nil;
				bResult = true;
			end
		end
	elseif type(vParam) == "table" then
		for _,v in ipairs(vParam) do
			if self._items[v] then
				self._items[v] = nil;
				bResult = true;
			end
		end
	else
		if self._items[vParam] then
			self._items[vParam] = nil;
			bResult = true;
		end
	end
	return bResult;
end
function SetOperations:contains(vParam)
	if not vParam then
		return false;
	end

	if SetManager.isSet(vParam) then
		for v,_ in pairs(vParam._items) do
			if not self._items[v] then
				return false;
			end
		end
		return true;
	elseif type(vParam) == "table" then
		for _,v in ipairs(vParam) do
			if not self._items[v] then
				return false;
			end
		end
		return true;
	end

	return (self._items[vParam] == true);
end
function SetOperations:overlaps(vParam)
	if not vParam then
		return false;
	end

	if SetManager.isSet(vParam) then
		for v,_ in pairs(vParam._items) do
			if self._items[v] then
				return true;
			end
		end
		return false;
	elseif type(vParam) == "table" then
		for _,v in ipairs(vParam) do
			if self._items[v] then
				return true;
			end
		end
		return false;
	end

	return (self._items[vParam] == true);
end
function SetOperations:concat(vDelimiter)
	local tOutput = {}
	for k,_ in pairs(self._items) do
		table.insert(tOutput, tostring(k))
	end
	return table.concat(tOutput, vDelimiter);
end
function SetOperations:union(vParam)
	local result = SetManager.new(self);
	result:add(vParam);
	return result;
end
function SetOperations:intersect(vParam)
	local result = SetManager.new();
	if not vParam then
		return result;
	end

	if SetManager.isSet(vParam) then
		for k,_ in pairs(vParam._items) do
			if self:contains(k) then
				result._items[k] = true;
			end
		end
	elseif type(vParam) == "table" then
		for _,v in ipairs(vParam) do
			if self:contains(v) then
				result._items[v] = true;
			end
		end
	else
		if self:contains(vParam) then
			result._items[vParam] = true;
		end
	end
	return result;
end
function SetOperations:difference(vParam)
	local result = SetManager.new(self);
	if not vParam then
		return result;
	end

	if SetManager.isSet(vParam) then
		for k,_ in pairs(vParam._items) do
			if result:contains(k) then
				result:remove(k);
			else
				result:add(k);
			end
		end
	elseif type(vParam) == "table" then
		for _,v in ipairs(vParam) do
			if result:contains(v) then
				result:remove(v);
			else
				result:add(v);
			end
		end
	else
		if result:contains(vParam) then
			result:remove(vParam);
		else
			result:add(vParam);
		end
	end
	return result;
end

--
--	BASE FUNCTIONS
--

function isSet(v)
	return ((v ~= nil) and (type(v) == "table") and (v._items ~= nil));
end
function new(vItems)
	local set = { _items = {} };
	for k,v in pairs(SetOperations) do
		set[k] = v;
	end
	if vItems then
		set:add(vItems);
	end
	return set;
end

--
--	ALTERNATE OPERATION CALLS
--

function count(set)
	if not SetManager.isSet(set) then
		if type(set) == "table" then
			return #set;
		end
		return 0;
	end
	return set:count();
end
function add(set, vItems)
	if not SetManager.isSet(set) then
		return;
	end
	set:add(vItems);
end
function remove(set, vItems)
	if not SetManager.isSet(set) then
		return false;
	end
	return set:remove(vItems);
end
function contains(set, vItems)
	if not SetManager.isSet(set) then
		if type(set) == "table" then
			set = SetManager.new(set);			
		else
			return false;
		end
	end
	return set:contains(vItems);
end
function overlaps(set, set2)
	if not SetManager.isSet(set) then
		if type(set) == "table" then
			set = SetManager.new(set);
		else
			return false;		
		end
	end
	if not SetManager.isSet(set2) then
		if type(set2) == "table" then
			set2 = SetManager.new(set2);
		else
			return false;		
		end
	end
	return set:overlaps(set2);
end
function concat(set, vDelimiter)
	if not SetManager.isSet(set) then
		if type(set) == "table" then
			set = SetManager.new(set);			
		else
			return "";
		end
	end
	return set:concat(vDelimiter);
end
function union(set, set2)
	if not SetManager.isSet(set) then
		if type(set) == "table" then
			set = SetManager.new(set);
		else		
			if not SetManager.isSet(set2) then
				return SetManager.new();
			end
			return SetManager.new(set2);
		end
	end
	return set:union(set2);
end
function intersect(set, set2)
	if not SetManager.isSet(set) then
		if type(set) == "table" then
			set = SetManager.new(set);			
		else
			return SetManager.new();
		end
	end
	return set:intersect(set2);
end
function difference(set, set2)
	if not SetManager.isSet(set) then
		if type(set) == "table" then
			set = SetManager.new(set);			
		else
			return SetManager.new();
		end
	end
	return set:difference(set2);
end
