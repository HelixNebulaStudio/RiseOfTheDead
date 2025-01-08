local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local attirePackage = {
	GroupName="ChestGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};
	
	toolLib.TickRepellent = 2;
	toolLib.BaseArmorPoints = 10;
	toolLib.Warmth = 3;
	
	
	local clothing = modClothingProperties.new(toolLib);
	
	if not modBranchConfigs.IsWorld("Slaughterfest") then
		clothing:RegisterPlayerProperty("TireArmor", {
			Visible=false;
		});
	end
	
	return clothing;
end

return attirePackage;