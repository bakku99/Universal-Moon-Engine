--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onClickDown()
	if isReadOnly() then
		return true;
	end
end
function onClickRelease()
	if isReadOnly() then
		StoryManager.onBookIndexSectionPressed(window);
	end
end
