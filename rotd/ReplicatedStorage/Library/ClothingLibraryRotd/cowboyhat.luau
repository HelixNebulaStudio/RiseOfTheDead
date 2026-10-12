local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	
	Configurations={
		HasFlinchProtection = true;
		Warmth = -2;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddBaseModifier("LockedIn", {
		SetValues = {
			DamageDropoff = false;
		};
		ArrayValues = {
			PassiveModifiers = "Gunslinger Lock-In";
		};
	});

	return equipmentClass;
end

return attirePackage;