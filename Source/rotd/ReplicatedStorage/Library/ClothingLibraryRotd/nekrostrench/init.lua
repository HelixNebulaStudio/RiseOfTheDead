local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="ChestGroup";
	
	Configurations={
		TickRepellent = 4;
		ArmorPoints = 10;
		Warmth = 7;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage.Class, attirePackage.Configurations, attirePackage.Properties);

	if not modBranchConfigs.IsWorld("Slaughterfest") then
		equipmentClass:AddModifier("Nekrosis", {
			SumValues={
				NekrosisHeal = 2;
			};
		});
	end

	return equipmentClass;
end

return attirePackage;