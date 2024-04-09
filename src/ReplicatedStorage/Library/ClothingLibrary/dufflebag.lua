local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="MiscGroup";
	UniversalVanity = true;
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};
	toolLib.Warmth = 2;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;