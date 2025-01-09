local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local attirePackage = {
	GroupName="HandGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.BaseAdditionalStamina = 30;
	toolLib.AdditionalStamina = toolLib.BaseAdditionalStamina;
	toolLib.Warmth = 2;


	local clothing = modClothingProperties.new(toolLib);
	return clothing;
end

return attirePackage;