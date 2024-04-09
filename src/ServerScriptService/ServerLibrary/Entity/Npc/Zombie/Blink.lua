local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local Zombie = {};

function Zombie.new(self)
	return function(targetHumanoid)
		if self.CanBlink == false then return end;
		if self.IsDead or self.Humanoid.RootPart == nil then return end;
		if targetHumanoid and targetHumanoid.RootPart then
			local att = Debugger:Point(self.RootPart.CFrame.Position);
			local newBlinkEffect = script.BlinkEffect:Clone();
			game.Debris:AddItem(att, 1.1);
			newBlinkEffect.Parent = att;
			newBlinkEffect:Emit(20);
			
			local floorHit, floorPos = workspace:FindPartOnRayWithWhitelist(Ray.new(targetHumanoid.RootPart.CFrame.p, Vector3.new(0, -32, 0)), {workspace.Environment;}, true);
			if floorHit then	
				if self.Humanoid and self.Humanoid.SeatPart and self.Humanoid.SeatPart:FindFirstChild("SeatWeld") then 
					self.Humanoid.SeatPart.SeatWeld:Destroy();
				end
				self.RootPart.CFrame = CFrame.new(floorPos + Vector3.new(0, 1.35, 0)) * self.RootPart.CFrame.Rotation;
			end
			modAudio.Play("BlinkAbility", self.RootPart);
		end
	end
end

return Zombie;