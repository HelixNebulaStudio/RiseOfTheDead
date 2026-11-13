local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="ChestGroup";
	
	Configurations={
		TickRepellent = 2;
		ArmorPoints = 5;
		Warmth = 5;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	if modConfigurations.DisableGearMods ~= true then
		equipmentClass:AddBaseModifier("NinjaAgility", {
			SetValues = {
				NinjaAgility = true;
				MaxAirJump = 1;
			};
			ArrayValues = {
				PassiveModifiers = "NinjaAgility";
			};
		});
	end

	return equipmentClass;
end

return attirePackage;