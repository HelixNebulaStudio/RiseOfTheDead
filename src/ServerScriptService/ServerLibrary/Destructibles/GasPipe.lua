local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local random = Random.new();

return function(Destructible)
	Destructible.Enabled = true;
	Destructible.MaxHealth = 1;
	Destructible.Health = Destructible.MaxHealth;
	Destructible.PipeFuel = 100;
	
	function Destructible:OnDestroy(hitPart)
		local oldColor = hitPart.Color;
		
		hitPart.Color = Color3.new(math.clamp(oldColor.R * 0.5, 0, 1), math.clamp(oldColor.G * 0.5, 0, 1), math.clamp(oldColor.B * 0.5, 0, 1));
		
		repeat
			local origin = CFrame.new(hitPart.Position);
			
			local projectileObject = modProjectile.Fire("Gasoline", origin, Vector3.new(0, -1, 0));
			
			local dirCf = CFrame.lookAt(origin.Position, origin.Position + Vector3.new(random:NextNumber(-1,1), 0, random:NextNumber(-1,1))).LookVector * random:NextNumber(0, 1.4)
			
			modProjectile.Simulate(projectileObject, origin.p, dirCf * 20, {workspace.Environment});
			
			wait(math.random(3,6)/10);
			self.PipeFuel = self.PipeFuel - math.random(1, 5)
			
		until self.PipeFuel <= 0;
		
		task.delay(20, function()
			self.Destroyed = false;
			self.PipeFuel = 100;
			hitPart.Color = oldColor;
		end)
	end
end
