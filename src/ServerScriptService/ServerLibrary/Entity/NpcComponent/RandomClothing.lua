local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
--local modClothing = require(game.ServerScriptService.ServerLibrary.Clothing);
local modNpcClothing = require(game.ServerScriptService.ServerLibrary.NpcClothing);

local NpcRandomClothing = {};

local ShirtParts = {
	"UpperTorso"; "LowerTorso"; 
	"LeftUpperArm"; "RightUpperArm"; 
	"LeftLowerArm"; "RightLowerArm"; 
	"LeftHand"; "RightHand"; 
	--"LeftPoint"; "LeftMiddle"; "LeftPinky";
	--"RightPoint"; "RightPoint"; "RightPinky";
};
local PantsParts = {
	"LeftUpperLeg"; "RightUpperLeg"; 
	"LeftLowerLeg"; "RightLowerLeg";
	"LeftFoot"; "RightFoot";
};

function NpcRandomClothing.new(self)
	return function(npcName, addHair)
		local oldShirt = self.Prefab:FindFirstChildWhichIsA("Shirt");
		local oldPants = self.Prefab:FindFirstChildWhichIsA("Pants");
		
		local rngShirt = modNpcClothing:GetShirt(npcName, self.Seed);
		local rngPants = modNpcClothing:GetPants(npcName, self.Seed);

		local rngSkinColor = modNpcClothing:GetSkinColor(npcName, self.Seed);
		self.Head.Color = rngSkinColor;
		
		for a=1, #ShirtParts do
			local part = self.Prefab:FindFirstChild(ShirtParts[a]);
			part.Color = rngSkinColor;
			
			if oldShirt then
				oldShirt.ShirtTemplate = rngShirt.Id;
			else
				part.TextureID = rngShirt.Id;
			end
		end
		for a=1, #PantsParts do
			local part = self.Prefab:FindFirstChild(PantsParts[a]);
			part.Color = rngSkinColor;
			

			if oldPants then
				oldPants.PantsTemplate = rngPants.Id;
			else
				part.TextureID = rngPants.Id;
			end
		end
		
		if self.Prefab:FindFirstChild("RightPoint") then
			self.Prefab.RightPoint.Color = rngSkinColor;
		end
		if self.Prefab:FindFirstChild("RightMiddle") then
			self.Prefab.RightMiddle.Color = rngSkinColor;
		end
		if self.Prefab:FindFirstChild("RightPinky") then
			self.Prefab.RightPinky.Color = rngSkinColor;
		end
		if self.Prefab:FindFirstChild("LeftPoint") then
			self.Prefab.LeftPoint.Color = rngSkinColor;
		end
		if self.Prefab:FindFirstChild("LeftMiddle") then
			self.Prefab.LeftMiddle.Color = rngSkinColor;
		end
		if self.Prefab:FindFirstChild("LeftPinky") then
			self.Prefab.LeftPinky.Color = rngSkinColor;
		end
		
		
		if addHair ~= false then
			local rngHair, rngHairColor = modNpcClothing:GetHair(npcName, self.Seed);
			if rngHair ~= nil then
				local newHair = rngHair:Clone();
				newHair.Parent = self.Prefab;

				local handle = newHair:WaitForChild("Handle");
				handle.Color = rngHairColor;
			end
		end
		
		local rngFace = modNpcClothing:GetFace(npcName, self.Seed);
		if self.Head:IsA("MeshPart") then
			self.Head.TextureID = rngFace.Id;
		elseif self.Head:FindFirstChild("face") then
			self.Head.face.Texture = rngFace.Id;
		end
			
		self.RandomClothing = nil;
	end
end

return NpcRandomClothing;