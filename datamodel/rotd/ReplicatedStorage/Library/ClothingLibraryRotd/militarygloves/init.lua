local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HandGroup";
	
	Configurations={
		AdditionalStamina = 30;
		Warmth = 2;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddBaseModifier("InstinctiveBullseye", {
		SetValues = {
			InstinctiveBullseye = true;
		};
		ArrayValues = {
			PassiveModifiers = "Instinctive Bullseye";
		};
	}); 

	return equipmentClass;
end

return attirePackage;