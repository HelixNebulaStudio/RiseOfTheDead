local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="ChestGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.LabCoat = true;
	toolLib.TickRepellent = 3;
	toolLib.BaseArmorPoints = 10;
	toolLib.ModArmorPoints = 10;
	toolLib.Warmth = 4;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;