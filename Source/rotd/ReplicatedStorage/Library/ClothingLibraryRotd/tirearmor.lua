local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
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
	local equipmentClass = modEquipmentClass.new(attirePackage.Class, attirePackage.Configurations, attirePackage.Properties);

	if not modBranchConfigs.IsWorld("Slaughterfest") then
		equipmentClass:AddModifier("TireArmor");
	end

	return equipmentClass;
end

return attirePackage;