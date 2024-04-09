local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));

return function()
	local Clothing = {};
	
	Clothing.BaseHotEquipSlots = 2;
	Clothing.HotEquipSlots = Clothing.BaseHotEquipSlots;
	Clothing.Warmth = -2;
	
	return modClothingProperties.new(Clothing);
end;