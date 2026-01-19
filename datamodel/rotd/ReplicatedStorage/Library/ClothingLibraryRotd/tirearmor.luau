local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
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

	if not modBranchConfigs.IsWorld("Slaughterfest") then
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
	end

	return equipmentClass;
end

return attirePackage;