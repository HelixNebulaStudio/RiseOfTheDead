local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};
	
	Clothing.TickRepellent = 2;
	Clothing.BulletProtection = 0.25;
	
	Clothing.BaseArmorPoints = 30;
	Clothing.ModArmorPoints = 30;
	Clothing.Warmth = -8;
	
	return modClothingProperties.new(Clothing);
end;