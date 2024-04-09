local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modClothing = require(game.ServerScriptService.ServerLibrary.Clothing);
local modZombieClothing = require(game.ServerScriptService.ServerLibrary.ZombieClothing);

local Zombie = {};

local ShirtParts = {"LeftUpperArm"; "RightUpperArm"; "UpperTorso"};
local PantsParts = {"LeftUpperLeg"; "RightUpperLeg";};
local ZombieFaces2 = {
	"rbxassetid://15544818103";
	"rbxassetid://15544826076";
}

function Zombie.new(self)
	return function(npcName, addHair)
		local shirt = self.Prefab:FindFirstChild("Shirt");
		local pants = self.Prefab:FindFirstChild("Pants");
		
		if shirt == nil then
			shirt = modClothing:GetRandomShirt(self.Seed);
			shirt.Name = "Shirt";
			shirt.Parent = self.Prefab;
			
		else
			local picked = modClothing:GetRandomShirtTexture(self.Seed);
			shirt.ShirtTemplate = "rbxassetid://"..picked.Id;
			shirt:SetAttribute("Artist", picked.Artist);
			
		end
		
		if pants == nil then
			pants = modClothing:GetRandomPants(self.Seed);
			pants.Name = "Pants";
			pants.Parent = self.Prefab;

		else
			local picked = modClothing:GetRandomPantsTexture(self.Seed);
			pants.PantsTemplate = "rbxassetid://"..picked.Id;
			pants:SetAttribute("Artist", picked.Artist);
			
		end
		
		if self.SetShirt then
			shirt.ShirtTemplate = self.SetShirt;
		end
		if self.SetPants then
			pants.PantsTemplate = self.SetPants;
		end
		
		self.SetShirt = nil;
		self.SetPants = nil;
		self.RandomClothing = nil;
	end
end

return Zombie;