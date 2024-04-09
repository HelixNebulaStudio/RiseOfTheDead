local Clothing = {}
local random = Random.new();

Clothing.Shirts = {
	{Artist="Roblox"; Id=382537084;};
	{Artist="Roblox"; Id=607785311;};
	{Artist="Roblox"; Id=969769092;};
	{Artist="Roblox"; Id=398635080;};
	{Artist="Roblox"; Id=398633582;}; --
	{Artist="Roblox"; Id=382538294;}; --
	{Artist="Roblox"; Id=398634294;};
	{Artist="Roblox"; Id=382537700;};
	{Artist="Roblox"; Id=382538058;};
	{Artist="Roblox"; Id=3670737337;};
}

Clothing.Pants = {
	{Artist="Roblox"; Id=348211416;};
	{Artist="Roblox"; Id=129458425;};
	{Artist="Roblox"; Id=129459076;};
	{Artist="Roblox"; Id=382537568;};
	{Artist="Roblox"; Id=398635336;};
	
	{Artist="Roblox"; Id=398633811;};
	{Artist="Roblox"; Id=398634485;};
	{Artist="Roblox"; Id=382537949;};
	{Artist="Roblox"; Id=382537805;};
	{Artist="Roblox"; Id=382538502;};
	
	{Artist="Roblox"; Id=398633811;};
};

Clothing.GetRandomShirtTexture = function(self, seed)
	local dice = random;
	if seed then
		dice = Random.new(seed);
	end

	return self.Shirts[dice:NextInteger(1, #self.Shirts)];
end

Clothing.GetRandomPantsTexture = function(self, seed)
	local dice = random;
	if seed then
		dice = Random.new(seed);
	end
	
	return self.Pants[dice:NextInteger(1, #self.Pants)];
end

Clothing.GetRandomShirt = function(self, seed)
	local picked = Clothing:GetRandomShirtTexture(seed);
	
	local newShirt = Instance.new("Shirt");
	newShirt.Name = "Shirt";
	newShirt.ShirtTemplate = "rbxassetid://"..picked.Id;
	newShirt:SetAttribute("Artist", picked.Artist);
	
	return newShirt;
end

Clothing.GetRandomPants = function(self, seed)
	local picked = Clothing:GetRandomPantsTexture(seed);
	
	local newPants = Instance.new("Pants");
	newPants.Name = "Pants";
	newPants.PantsTemplate = "rbxassetid://"..picked.Id;
	newPants:SetAttribute("Artist", picked.Artist);
	
	return newPants;
end

return Clothing;