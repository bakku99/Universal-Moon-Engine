--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	StoryManager.updatePageSub(sub_paging, getDatabasePath());
end

function handlePageTop()
	StoryManager.handlePageTop(self, getDatabasePath());
end
function handlePagePrev()
	StoryManager.handlePagePrev(self, getDatabasePath());
end
function handlePageNext()
	StoryManager.handlePageNext(self, getDatabasePath());
end
