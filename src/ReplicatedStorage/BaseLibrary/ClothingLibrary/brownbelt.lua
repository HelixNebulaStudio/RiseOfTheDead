local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="WaistGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.BaseHotEquipSlots = 2;
	toolLib.HotEquipSlots = toolLib.BaseHotEquipSlots;
	toolLib.Warmth = -2;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;