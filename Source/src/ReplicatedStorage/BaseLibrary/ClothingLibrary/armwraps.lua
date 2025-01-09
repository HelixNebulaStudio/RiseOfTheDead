local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="HandGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.BaseAdditionalStamina = 20;
	toolLib.AdditionalStamina = toolLib.BaseAdditionalStamina;
	toolLib.Warmth = 2;


	local clothing = modClothingProperties.new(toolLib);
	return clothing;
end

-- roughness texture : rbxassetid://16987783721

return attirePackage;