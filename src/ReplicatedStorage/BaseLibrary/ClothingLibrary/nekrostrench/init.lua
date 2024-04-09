local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local attirePackage = {
	GroupName="ChestGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};
	
	toolLib.TickRepellent = 4;
	
	toolLib.BaseNekrosisHeal = 2;
	toolLib.BaseArmorPoints = 10;
	
	toolLib.Warmth = 7;
	
	local clothing = modClothingProperties.new(toolLib);
	
	if not modBranchConfigs.IsWorld("Slaughterfest") then
		clothing:RegisterPlayerProperty("Nekrosis", {});
	end
	
	return clothing;
end

return attirePackage;