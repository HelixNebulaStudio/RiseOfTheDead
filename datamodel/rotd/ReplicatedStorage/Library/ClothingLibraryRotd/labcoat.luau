local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="ChestGroup";
	
	Configurations={
		LabCoat = 0.3;
		TickRepellent = 3;
		ArmorPoints = 10;
		Warmth = 4;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);
	
	equipmentClass:AddBaseModifier("LabSafety", {
		ArrayValues = {
			PassiveModifiers = "Lab Safety";
		};
	}); 

	return equipmentClass;
end

return attirePackage;