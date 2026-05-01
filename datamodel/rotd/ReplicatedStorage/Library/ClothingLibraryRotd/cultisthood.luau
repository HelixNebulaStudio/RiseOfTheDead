local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	HideHair=true;
	
	Configurations={
		HasFlinchProtection = true;
		Warmth = 3;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddBaseModifier("HoodsPact", {
		ArrayValues = {
			PassiveModifiers = "Hoods Pact";
		};
	});

	return equipmentClass;
end

return attirePackage;