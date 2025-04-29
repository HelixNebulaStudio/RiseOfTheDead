local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	
	Configurations={
		HasFlinchProtection = true;
		Warmth = 6;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	if modConfigurations.SpecialEvent.Easter then
		equipmentClass:AddModifier("Bunnyman");
	end

	return equipmentClass;
end

return attirePackage;