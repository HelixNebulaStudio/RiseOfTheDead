local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	
	Configurations={
		HasFlinchProtection = true;
		Warmth = 4;
		Slaughterfest=modConfigurations.SpecialEvent.Halloween;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage);
end

return attirePackage;