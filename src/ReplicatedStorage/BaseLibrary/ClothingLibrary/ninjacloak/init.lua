local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local attirePackage = {
	GroupName="ChestGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};
	
	toolLib.TickRepellent = 2;
	toolLib.BaseArmorPoints = 5;
	
	toolLib.Warmth = 5;

	local clothing = modClothingProperties.new(toolLib);
	
	if not modBranchConfigs.IsWorld("Slaughterfest") then
		clothing:RegisterPlayerProperty("SuperiorAgility", {
			Visible = false;
		});
	end
	
	return clothing;
end

return attirePackage;