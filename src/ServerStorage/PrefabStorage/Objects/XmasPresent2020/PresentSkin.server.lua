local skins = {
	{Texture="rbxassetid://6109052204"; BowColor=Color3.fromRGB(81, 214, 115)};
	{Texture="rbxassetid://6109059756"; BowColor=Color3.fromRGB(255, 255, 0)};
	{Texture="rbxassetid://6109074464"; BowColor=Color3.fromRGB(255, 89, 89)};
	{Texture="rbxassetid://6109084797"; BowColor=Color3.fromRGB(245, 205, 48)};
	{Texture="rbxassetid://6109157985"; BowColor=Color3.fromRGB(91, 154, 76)};
	{Texture="rbxassetid://6109157985"; BowColor=Color3.fromRGB(245, 205, 48)};
	{Texture="rbxassetid://6109215107"; BowColor=Color3.fromRGB(196, 40, 28)};
}
local pickedSkin = skins[math.random(1, #skins)];

script.Parent:WaitForChild("Handle").TextureID = pickedSkin.Texture;
script.Parent:WaitForChild("bow").Color = pickedSkin.BowColor;