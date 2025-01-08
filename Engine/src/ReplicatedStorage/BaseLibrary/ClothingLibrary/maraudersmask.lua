local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local attirePackage = {
	GroupName="HeadGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.Slaughterfest=modConfigurations.SpecialEvent.Halloween;
	toolLib.Warmth = 3;
	toolLib.HasFlinchProtection = true;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;