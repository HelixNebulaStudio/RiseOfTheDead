local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="HeadGroup";
	HideFacewear=true;
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.GasProtection = 0.1;
	toolLib.HasFlinchProtection = true;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;