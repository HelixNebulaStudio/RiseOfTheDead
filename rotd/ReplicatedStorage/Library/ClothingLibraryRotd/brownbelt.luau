local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="WaistGroup";
	
	Configurations={
		HotEquipSlots = 2;
		Warmth = -2;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage);
end

return attirePackage;