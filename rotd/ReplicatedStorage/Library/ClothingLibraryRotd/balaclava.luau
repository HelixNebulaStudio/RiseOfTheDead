local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId = script.Name;
	Class = "Clothing";
	
	GroupName = "HeadGroup";
	
	Configurations = {
		HasFlinchProtection = true;
		Warmth = 2;
	};
	Properties = {};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);
	
	equipmentClass:AddBaseModifier("SneakyBeaky", {
		ProductValues = {
			FireAlertRange = 1/2;
		};
		ArrayValues = {
			PassiveModifiers = "Sneaky Beaky";
		};
	}); 

	return equipmentClass;
end

return attirePackage;