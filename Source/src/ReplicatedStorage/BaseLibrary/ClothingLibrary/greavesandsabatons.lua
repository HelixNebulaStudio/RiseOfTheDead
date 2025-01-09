local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local attirePackage = {
	GroupName="FootGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	local clothing = modClothingProperties.new(toolLib);

	return clothing;
end

return attirePackage;