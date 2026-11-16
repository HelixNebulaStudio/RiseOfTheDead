local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="FootGroup";
	
	Configurations={
		Warmth = 2;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddBaseModifier("BullLeaping", {
		SetValues = {
			BullLeapingVelocity = 20;
		};
		ArrayValues = {
			PassiveModifiers = "BullLeaping";
		};
	});

	return equipmentClass;
end

return attirePackage;