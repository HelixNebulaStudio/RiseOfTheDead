local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

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