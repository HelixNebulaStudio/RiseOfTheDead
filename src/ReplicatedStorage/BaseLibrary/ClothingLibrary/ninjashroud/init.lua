local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local attirePackage = {
	GroupName="HeadGroup";
	HideHair=true;
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};
	toolLib.Warmth = 1;
	toolLib.HasFlinchProtection = true;
	
	local clothing = modClothingProperties.new(toolLib);

	if not modBranchConfigs.IsWorld("Slaughterfest") then
		clothing:RegisterPlayerProperty("SuperiorFocus", {
			Visible = false;
		});
	end

	return clothing;
end

return attirePackage;