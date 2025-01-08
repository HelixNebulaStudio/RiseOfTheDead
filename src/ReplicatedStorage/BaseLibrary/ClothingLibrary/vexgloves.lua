local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="HandGroup";
	HideHands=true;
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.BaseAdditionalStamina = 50;
	toolLib.AdditionalStamina = toolLib.BaseAdditionalStamina;
	toolLib.Warmth = 4;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;