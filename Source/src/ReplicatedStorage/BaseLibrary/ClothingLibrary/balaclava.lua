local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	
	Configurations={
		HasFlinchProtection = true;
		Warmth = 2;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage.Class, attirePackage.Configurations, attirePackage.Properties);
end

return attirePackage;