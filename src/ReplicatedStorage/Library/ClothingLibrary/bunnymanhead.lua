local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local toolLib = {};
	
	toolLib.Warmth = 6;
	toolLib.HasFlinchProtection = true;
	
	local clothing = modClothingProperties.new(toolLib);
	if modConfigurations.SpecialEvent.Easter then
		clothing:RegisterPlayerProperty("bunnyman", true);
	end
	
	return clothing;
end;
