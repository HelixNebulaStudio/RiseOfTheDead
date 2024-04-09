local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local Zombie = {};

function Zombie.new(self)
	local bodyParts = self.Prefab:GetDescendants();
	
	return function(duration)
		if self.IsDead or self.Humanoid.RootPart == nil then return end;
		for a=1, #bodyParts do
			if bodyParts[a].Name ~= "HumanoidRootPart" and (bodyParts[a]:IsA("BasePart") or bodyParts[a]:IsA("Decal")) then
				bodyParts[a].Transparency = 0.85;
			end
		end
		delay(duration, function()
			if self.IsDead or self.Humanoid.RootPart == nil then return end;
			for a=1, #bodyParts do
				if bodyParts[a].Name ~= "HumanoidRootPart" and (bodyParts[a]:IsA("BasePart") or bodyParts[a]:IsA("Decal")) then
					bodyParts[a].Transparency = 0;
				end
			end
		end)
	end
end

return Zombie;