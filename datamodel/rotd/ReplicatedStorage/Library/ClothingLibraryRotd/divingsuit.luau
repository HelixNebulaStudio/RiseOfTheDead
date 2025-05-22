local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="BodyGroup";
	
	Configurations={
		Warmth = 6;
		OxygenDrainReduction = 0.7;
		OxygenRecoveryIncrease = 0.3;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage);
end

return attirePackage;