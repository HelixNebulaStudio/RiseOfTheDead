local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="ChestGroup";
	
	Configurations={
		TickRepellent = 20;
		
		ArmorPoints = 10;
		Warmth = -4;
	};
	Properties={};
};

function attirePackage.newClass()
	local equipmentClass = modEquipmentClass.new(attirePackage);

	equipmentClass:AddBaseModifier("SplashReflect", {
		SetValues = {
			SplashReflection = 2;
		};
		ArrayValues = {
			PassiveModifiers = "Splash Reflect";
		};
	}); 
	

	return equipmentClass;
end

return attirePackage;