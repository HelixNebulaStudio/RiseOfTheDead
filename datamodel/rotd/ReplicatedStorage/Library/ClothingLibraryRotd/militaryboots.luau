local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId = script.Name;
	Class = "Clothing";
	
	GroupName = "FootGroup";
	
	Configurations = {
		MoveImpairReduction = 0.2;
		Warmth = 4;
	};
	Properties = {};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);
	return equipmentClass;
end

return attirePackage;