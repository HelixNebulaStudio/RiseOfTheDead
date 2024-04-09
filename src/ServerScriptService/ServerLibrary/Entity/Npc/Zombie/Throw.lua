local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local Zombie = {};

function Zombie.new(self)
	return function(model, force, damage)
		if self.IsDead or self.Humanoid.RootPart == nil then return end;
		local humanoid = model:FindFirstChildWhichIsA("Humanoid");
		
		if humanoid then
			local enemyName = model.Name;
			local enemyPlayer = game.Players:FindFirstChild(enemyName);
			if enemyPlayer then
				remoteCameraShakeAndZoom:FireClient(enemyPlayer, 10, 5, 4, 0.01, true);

				self:DamageTarget(enemyPlayer.Character, damage);
			end
			
			local dir = self.RootPart.CFrame.LookVector;
			modAudio.Play("Throw", self.RootPart);
			modStatusEffects.Throw(enemyPlayer, dir);
		end
		
	end
end

return Zombie;