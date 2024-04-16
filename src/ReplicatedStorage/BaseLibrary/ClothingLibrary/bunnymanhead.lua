local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local attirePackage = {
	GroupName="HeadGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.Warmth = 6;
	toolLib.HasFlinchProtection = true;
	
	local clothing = modClothingProperties.new(toolLib);
	if modConfigurations.SpecialEvent.Easter then
		clothing:RegisterPlayerProperty("bunnyman", true);
	end
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;