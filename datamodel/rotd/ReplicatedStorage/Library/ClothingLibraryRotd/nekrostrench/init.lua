local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
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
	local equipmentClass = modEquipmentClass.new(attirePackage);

	if not modBranchConfigurations.IsWorld("Slaughterfest") then
		equipmentClass:AddBaseModifier("Nekrosis", {
			SetValues = {
				NekrosisHeal = 2;
			};
			ArrayValues = {
				PassiveModifiers = "Nekrosis";
			};
		});
	end

	return equipmentClass;
end

return attirePackage;