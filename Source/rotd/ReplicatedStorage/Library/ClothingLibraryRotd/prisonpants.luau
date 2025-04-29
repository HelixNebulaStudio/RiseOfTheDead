local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="LegGroup";
	
	Configurations={
		Warmth = 2;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage);
end

return attirePackage;