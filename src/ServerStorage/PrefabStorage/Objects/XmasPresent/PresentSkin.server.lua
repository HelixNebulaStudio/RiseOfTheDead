local skins = {
	"rbxassetid://4527242130";
	"rbxassetid://4527242331";
	"rbxassetid://4527242469";
	"rbxassetid://4527242591";
	"rbxassetid://4527242713";
	"rbxassetid://4527242820";
	"rbxassetid://4527259843";
	"rbxassetid://4527259963";
	"rbxassetid://4527257042";
	"rbxassetid://4527242932";
	"rbxassetid://4527256263";
}
local pickedSkin = skins[math.random(1, #skins)];

script.Parent:WaitForChild("Handle").TextureID = pickedSkin;
script.Parent:WaitForChild("cover").TextureID = pickedSkin;