local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="MiscGroup";
	UniversalVanity = true;
	
	Configurations={
		Warmth = 3;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage.Class, attirePackage.Configurations, attirePackage.Properties);
end

return attirePackage;