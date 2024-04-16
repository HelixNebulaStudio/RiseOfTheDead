local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	Name="SurvivorsBackpack";
	GroupName="MiscGroup";
	UniversalVanity = true;
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};
	toolLib.Warmth = 3;

	return modClothingProperties.new(toolLib);
end

return attirePackage;