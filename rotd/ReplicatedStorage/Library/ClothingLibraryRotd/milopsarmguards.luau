local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId = script.Name;
	Class = "Clothing";
	
	GroupName = "HandGroup";
	
	Configurations={
		Warmth = 3;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage);
end

return attirePackage;