local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HandGroup";
	
	Configurations={
		AdditionalStamina = 30;
		Warmth = 2;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage);
end

return attirePackage;