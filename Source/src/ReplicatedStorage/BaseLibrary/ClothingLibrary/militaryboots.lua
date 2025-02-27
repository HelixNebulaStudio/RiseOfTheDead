local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="FootGroup";
	
	Configurations={
		MoveImpairReduction = 0.2;
		Warmth = 4;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage.Class, attirePackage.Configurations, attirePackage.Properties);
end

return attirePackage;