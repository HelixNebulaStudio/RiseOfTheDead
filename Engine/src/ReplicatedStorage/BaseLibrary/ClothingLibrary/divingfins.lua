local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="FootGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.SwimmingSpeed = 25;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;