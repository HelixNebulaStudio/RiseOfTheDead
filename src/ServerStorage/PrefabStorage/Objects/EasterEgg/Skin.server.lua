local skins = {
	"rbxassetid://4835841305";
	"rbxassetid://4835841576";
	"rbxassetid://4835841746";
}


if script.Parent.Name == "Easter Egg 2021" then
	skins = {
		"rbxassetid://4835841305";
		"rbxassetid://4835841576";
		"rbxassetid://4835841746";
	};
	
elseif script.Parent.Name == "Easter Egg 2023" then
	skins = {
		"rbxassetid://12961909431";
		"rbxassetid://12961914801";
		"rbxassetid://12961916162";
	};
	
end

local pickedSkin = skins[math.random(1, #skins)];

script.Parent:WaitForChild("Handle").TextureID = pickedSkin;