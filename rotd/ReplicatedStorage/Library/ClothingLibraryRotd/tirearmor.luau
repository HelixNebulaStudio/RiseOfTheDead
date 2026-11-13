local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="ChestGroup";
	
	Configurations={
		TickRepellent = 2;
		ArmorPoints = 10;
		Warmth = 3;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddBaseModifier("MeleeDampening", {
		MaxValues = {
			BlockChance = 0.73;
		};
		SumValues = {
			DamageBlock = 40;
		};
		ArrayValues = {
			PassiveModifiers = "MeleeDampening";
		};
	});

	return equipmentClass;
end

return attirePackage;