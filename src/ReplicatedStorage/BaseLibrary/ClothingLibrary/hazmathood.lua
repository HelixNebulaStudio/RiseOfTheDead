local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="HeadGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.GasProtection = 0.5;
	toolLib.Warmth = 3;
	toolLib.HasFlinchProtection = true;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;