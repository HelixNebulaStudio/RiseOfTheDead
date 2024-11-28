local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="HeadGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.Warmth = 1;
	toolLib.HasFlinchProtection = true;
	
	local clothing = modClothingProperties.new(toolLib);

	clothing:RegisterPlayerProperty("ColoredGifts", {
		Default="red";
		Visible = false;
	});

	return clothing;
end

return attirePackage;