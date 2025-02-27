local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="ChestGroup";
	
	Configurations={
		TickRepellent = 2;
		ArmorPoints = 5;
		Warmth = 7;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage.Class, attirePackage.Configurations, attirePackage.Properties);

	if not modBranchConfigs.IsWorld("Slaughterfest") then
		equipmentClass:AddModifier("NinjaAgility", {
			SetValues={
				MaxAirJump = 1;
			};
		});
	end

	return equipmentClass;
end

return attirePackage;