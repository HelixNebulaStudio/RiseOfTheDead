local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="HeadGroup";
	HideFacewear=true;
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.UnderwaterVision = 0.06;
	toolLib.HasFlinchProtection = true;

	local clothing = modClothingProperties.new(toolLib);
	clothing:RegisterPlayerProperty("NightVision", true);
	
	return clothing;
end

return attirePackage;