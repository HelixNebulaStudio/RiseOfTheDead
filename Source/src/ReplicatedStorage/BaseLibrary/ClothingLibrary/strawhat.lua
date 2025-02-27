local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	
	Configurations={
		Warmth = -3;
		HasFlinchProtection = true;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage.Class, attirePackage.Configurations, attirePackage.Properties);
end

return attirePackage;