local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="LegGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};
	toolLib.Warmth = 1;

	toolLib.BaseHotEquipSlots = 1;
	toolLib.EquipTimeReduction = 0.4;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;