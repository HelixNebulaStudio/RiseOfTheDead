local skins = {
	"rbxassetid://4835841305";
	"rbxassetid://4835841576";
	"rbxassetid://4835841746";
}
local pickedSkin = skins[math.random(1, #skins)];

script.Parent:WaitForChild("Handle").TextureID = pickedSkin;