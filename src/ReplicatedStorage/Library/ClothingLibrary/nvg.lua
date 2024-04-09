local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local toolLib = {};
	
	toolLib.UnderwaterVision = 0.06;
	toolLib.HasFlinchProtection = true;

	local clothing = modClothingProperties.new(toolLib);
	clothing:RegisterPlayerProperty("NightVision", true);

	return clothing;
end;