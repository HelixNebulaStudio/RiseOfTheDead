local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="FootGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.MoveImpairReduction = 0.1;
	toolLib.Warmth = 4;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;