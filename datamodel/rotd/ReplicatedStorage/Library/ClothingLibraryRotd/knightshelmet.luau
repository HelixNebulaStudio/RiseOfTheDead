local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId = script.Name;
	Class = "Clothing";
	
	GroupName = "HeadGroup";
	
	Configurations = {
		HasFlinchProtection = true;
	};
	Properties = {};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	

	return equipmentClass;
end

return attirePackage;