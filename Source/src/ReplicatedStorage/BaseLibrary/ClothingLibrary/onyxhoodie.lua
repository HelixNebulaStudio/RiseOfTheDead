local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="ChestGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.TickRepellent = 1;
	toolLib.BaseArmorPoints = 5;
	toolLib.ModArmorPoints = 5;
	toolLib.Warmth = 10;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;