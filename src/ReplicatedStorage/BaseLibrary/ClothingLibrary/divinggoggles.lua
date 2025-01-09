local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="HeadGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.GasProtection = 0.2;
	toolLib.Warmth = 2;
	toolLib.UnderwaterVision = 0.1;
	toolLib.HasFlinchProtection = true;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;