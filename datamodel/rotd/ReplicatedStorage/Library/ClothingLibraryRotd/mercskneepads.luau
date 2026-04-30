local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="LegGroup";
	
	Configurations={
		HotEquipSlots = 1;
		EquipTimeReduction = 0.4;
		Warmth = 2;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	return equipmentClass;
end

return attirePackage;