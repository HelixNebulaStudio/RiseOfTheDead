local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modNpcClothing = require(game.ServerScriptService.ServerLibrary.NpcClothing);

local NpcRandomClothing = {};

function NpcRandomClothing.new(self)
	return function(npcName, addHair)
		if self.PresetShirt == nil then
			self.PresetShirt = modNpcClothing:GetShirt(npcName, self.Seed);
		end
		if self.PresetPants == nil then
			self.PresetPants = modNpcClothing:GetPants(npcName, self.Seed);
		end

		if self.PresetSkinColor == nil then
			self.PresetSkinColor = modNpcClothing:GetSkinColor(npcName, self.Seed);
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
		self:UpdateClothing();
	end
end

return NpcRandomClothing;