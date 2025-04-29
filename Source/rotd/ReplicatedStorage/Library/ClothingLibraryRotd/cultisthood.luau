local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	HideHair=true;
	
	Configurations={
		HasFlinchProtection = true;
		Warmth = 3;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddModifier("CultistHood");

	return equipmentClass;
end

return attirePackage;