local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="BodyGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.Warmth = 6;
	toolLib.OxygenDrainReduction = 0.7;
	toolLib.OxygenRecoveryIncrease = 0.3;

	return modClothingProperties.new(toolLib);
end

return attirePackage;