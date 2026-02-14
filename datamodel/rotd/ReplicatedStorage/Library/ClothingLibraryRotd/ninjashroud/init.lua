local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
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

	if not modBranchConfigurations.IsWorld("Slaughterfest") then
		equipmentClass:AddBaseModifier("NinjaFleet", {
			SetValues={
				MaxAirDash = 1;
			};
		});
	end

	return equipmentClass;
end

return attirePackage;