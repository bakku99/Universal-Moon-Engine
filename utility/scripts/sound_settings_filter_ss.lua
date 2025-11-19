--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

function onInit()
	self.refresh();
end

function refresh()
	filter_name.setValue("");
	filter_id.setValue("");

	filter_type.clear();
	filter_type.add("");
	filter_type.addItems(SoundManagerSyrinscape.getFilterValues("type"));

	filter_subcategory.clear();
	filter_subcategory.add("");
	filter_subcategory.addItems(SoundManagerSyrinscape.getFilterValues("subcategory"));

	filter_product.clear();
	filter_product.add("");
	filter_product.addItems(SoundManagerSyrinscape.getFilterValues("product"));
end

function setFilterNameControl(s)
	self.refresh();
	filter_name.setValue(s);
end

function onFilterChanged()
	local tValuesLower = {};
	tValuesLower["name"] = filter_name.getValue():lower();
	tValuesLower["id"] = filter_id.getValue():lower();
	tValuesLower["type"] = filter_type.getValue():lower();
	tValuesLower["subcategory"] = filter_subcategory.getValue():lower();
	tValuesLower["product"] = filter_product.getValue():lower();

	SoundManagerSyrinscape.onSettingsFilterChanged(tValuesLower);
end
