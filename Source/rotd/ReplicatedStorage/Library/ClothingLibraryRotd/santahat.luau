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
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddModifier("ColoredGifts", {
		SetValues={
			Default="red";
		};
	});

	return equipmentClass;
end

return attirePackage;