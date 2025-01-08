local skins = {
	"rbxassetid://12961909431";
	"rbxassetid://12961914801";
	"rbxassetid://12961916162";
}
local pickedSkin = skins[math.random(1, #skins)];

script.Parent:WaitForChild("Handle").TextureID = pickedSkin;