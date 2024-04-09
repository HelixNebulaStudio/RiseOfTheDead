local skins = {
	{Texture="rbxassetid://8402019367"; BowColor=Color3.fromRGB(255, 255, 255)};
	{Texture="rbxassetid://8402043227"; BowColor=Color3.fromRGB(255, 255, 255)};
	{Texture="rbxassetid://8402045201"; BowColor=Color3.fromRGB(255, 255, 255)};
	{Texture="rbxassetid://8402046675"; BowColor=Color3.fromRGB(255, 255, 255)};
	{Texture="rbxassetid://8402047826"; BowColor=Color3.fromRGB(255, 255, 255)};
}
local pickedSkin = skins[math.random(1, #skins)];

script.Parent:WaitForChild("Handle").TextureID = pickedSkin.Texture;