local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="FootGroup";
	
	Configurations={
		Warmth = 4;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	if not modBranchConfigurations.IsWorld("Slaughterfest") then
		equipmentClass:AddBaseModifier("BullLeaping");
	end

	return equipmentClass;
end

return attirePackage;