--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	AssetWindowManager.initAssetWindow(self);
end
function onClose()
	AssetWindowManager.closeAssetWindow(self);
end

function onLayoutSizeChanged()
	AssetWindowManager.onLayoutSizeChanged(self);
end

function onMenuLinkDrag(draginfo)
	return AssetWindowManager.onMenuLinkDrag(self, draginfo);
end

function handleHome()
	AssetWindowManager.onHomeButtonPressed(self);
end
function handlePagePrev()
	AssetWindowManager.onPagePrevButtonPressed(self);
end
function handlePageNext()
	AssetWindowManager.onPageNextButtonPressed(self);
end
function handleHistoryBack()
	AssetWindowManager.onBackButtonPressed(self);
end

function getTypeFilter()
	return AssetWindowManager.getTypeFilter(self);
end
function handleTypeFilter(s)
	AssetWindowManager.onTypeFilterSelected(self, s);
end
