local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";

	GroupName="HeadGroup";
	HideHair=true;

	Configurations={
		HasFlinchProtection = true;
		MoveSpeed = 14;
		SprintSpeed = 24;
		SprintDelay = 5;

		Warmth = 1;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	if not modBranchConfigs.IsWorld("Slaughterfest") then
		equipmentClass:AddModifier("NinjaFleet", {
			SetValues={
				MaxAirDash = 1;
			};
		});
	end

	return equipmentClass;
end

return attirePackage;