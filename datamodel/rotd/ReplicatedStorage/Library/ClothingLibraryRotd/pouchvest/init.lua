local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId = script.Name;
	Class = "Clothing";
	
	GroupName = "ChestGroup";
	
	Configurations = {
		ArmorPoints = 10;
		Warmth = -1;
	};
	Properties = {};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddBaseModifier("BulletRecouper", {
		ArrayValues = {
			PassiveModifiers = "BulletRecouper";
		};
	});

	return equipmentClass;
end

return attirePackage;