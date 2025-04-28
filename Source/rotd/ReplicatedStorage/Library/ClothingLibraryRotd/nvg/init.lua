local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	HideFacewear=true;
	
	Configurations={
		HasFlinchProtection = true;
		UnderwaterVision = 0.06;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage.Class, attirePackage.Configurations, attirePackage.Properties);

	equipmentClass:AddModifier("NightVision");

	return equipmentClass;
end

return attirePackage;