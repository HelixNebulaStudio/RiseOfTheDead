local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local attirePackage = {
	GroupName="FootGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.Warmth = 4;
	
	local clothing = modClothingProperties.new(toolLib);
	
	if not modBranchConfigs.IsWorld("Slaughterfest") then
		clothing:RegisterPlayerProperty("BullLeaping", {
			Visible = false;
		});
	end
	
	return clothing;
end

return attirePackage;