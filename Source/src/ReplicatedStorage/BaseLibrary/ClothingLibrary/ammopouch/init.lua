local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="MiscGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.Configurations = {
		BaseRefillCharge = 3;
	};

	return modClothingProperties.new(toolLib);
end

return attirePackage;