local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="HeadGroup";
	HideHair=true;
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.Warmth = 3;
	toolLib.HasFlinchProtection = true;
	
	local clothing = modClothingProperties.new(toolLib);
	clothing:RegisterPlayerProperty("CultistHood", {});

	return clothing;
end

return attirePackage;