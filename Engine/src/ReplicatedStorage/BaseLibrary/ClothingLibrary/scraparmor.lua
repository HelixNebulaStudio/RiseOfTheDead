local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="ChestGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.TickRepellent = 2;
	toolLib.BulletProtection = 0.25;
	
	toolLib.BaseArmorPoints = 30;
	toolLib.ModArmorPoints = 30;
	toolLib.Warmth = -8;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;