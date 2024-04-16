local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="ChestGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.TickRepellent = 1;
	toolLib.BaseArmorPoints = 1;
	toolLib.ModArmorPoints = 1;
	toolLib.Warmth = 5;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;