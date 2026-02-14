local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
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
	local equipmentClass = modEquipmentClass.new(attirePackage);

	if not modBranchConfigurations.IsWorld("Slaughterfest") then
		equipmentClass:AddBaseModifier("NinjaAgility", {
			SetValues={
				MaxAirJump = 1;
			};
		});
	end

	return equipmentClass;
end

return attirePackage;