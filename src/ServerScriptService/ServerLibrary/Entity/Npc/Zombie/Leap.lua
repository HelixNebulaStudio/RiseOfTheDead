local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local RunService = game:GetService("RunService");

local Zombie = {};

function Zombie.new(self)
	return function(position, power)
		if self.IsDead or self.Humanoid == nil or self.Humanoid.Health <= 0 or self.Humanoid.RootPart == nil then return end;
		power = power or 5;
		if position then
			self.RootPart.Velocity = Vector3.new();
			self.Movement:Face(position);
			RunService.Heartbeat:Wait();
			self.RootPart.Velocity = ((position-self.RootPart.CFrame.p).Unit*Vector3.new(power, 0, power));
			self.Humanoid.Jump = true;
			--repeat until self.RootPart.Velocity.Magnitude < 5 or wait(0.2);
			-- rootPart:ApplyImpulse((rootPart.CFrame.LookVector + Vector3.new(0,0.5,0)) * 500 * rootPart:GetMass())
		end
	end
end

return Zombie;