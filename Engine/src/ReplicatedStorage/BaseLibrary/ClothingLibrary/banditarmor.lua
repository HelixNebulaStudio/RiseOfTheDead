local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local attirePackage = {
	GroupName="ChestGroup";
}

function attirePackage.NewToolLib(handler)
	local Clothing = {};
	
	Clothing.BaseArmorPoints = 50;
	Clothing.ModArmorPoints = 50;
	Clothing.Warmth = -5;
	
	return modClothingProperties.new(Clothing);
end

return attirePackage;