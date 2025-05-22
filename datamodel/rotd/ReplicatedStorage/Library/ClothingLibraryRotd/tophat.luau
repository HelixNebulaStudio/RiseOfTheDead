local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	
	Configurations={
		Slaughterfest=modConfigurations.SpecialEvent.Halloween;
		Warmth = -1;
		HasFlinchProtection = true;
	};
	Properties={};
};

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage);
end

return attirePackage;