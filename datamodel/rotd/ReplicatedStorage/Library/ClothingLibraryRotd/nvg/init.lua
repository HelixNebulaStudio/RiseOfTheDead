local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
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
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddBaseModifier("NightVision");

	return equipmentClass;
end

return attirePackage;