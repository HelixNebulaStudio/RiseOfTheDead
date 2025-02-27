local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	
	Configurations={
		Warmth = 1;
		HasFlinchProtection = true;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage.Class, attirePackage.Configurations, attirePackage.Properties);
end

return attirePackage;