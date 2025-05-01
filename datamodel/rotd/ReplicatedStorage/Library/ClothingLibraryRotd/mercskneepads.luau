local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="LegGroup";
	
	Configurations={
		HotEquipSlots = 1;
		EquipTimeReduction = 0.4;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddModifier("TacticalHolsters");

	return equipmentClass;
end

return attirePackage;