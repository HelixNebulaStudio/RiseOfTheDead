local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="LegGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};
	toolLib.Warmth = 1;

	toolLib.BaseHotEquipSlots = 1;
	toolLib.HotEquipSlots = toolLib.BaseHotEquipSlots;
	toolLib.EquipTimeReduction = 0.4;
	
	local clothing = modClothingProperties.new(toolLib);

	clothing:RegisterPlayerProperty("TacticalHolsters", {
		Visible = false;
	});

	return clothing;
end

return attirePackage;