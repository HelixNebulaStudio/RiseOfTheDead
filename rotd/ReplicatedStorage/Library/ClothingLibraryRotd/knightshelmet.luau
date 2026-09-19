local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId = script.Name;
	Class = "Clothing";
	
	GroupName = "HeadGroup";
	
	Configurations = {
		HasFlinchProtection = true;
		ArmorPoints = 20;
		Warmth = 3;
	};
	Properties = {};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddBaseModifier("HelmOverwhelm", {
		ArrayValues = {
			PassiveModifiers = "Helm Overwhelm";
		};
	});

	return equipmentClass;
end

return attirePackage;