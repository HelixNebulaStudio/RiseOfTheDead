local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="MiscGroup";
	UniversalVanity = true;
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};
	return modClothingProperties.new(toolLib);
end

return attirePackage;