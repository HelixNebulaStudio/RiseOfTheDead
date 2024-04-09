local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local random = Random.new();

local Zombie = {};

function Zombie.new(self)
	return function(damage, radius, ticks, duration)
		if self.IsDead or self.Humanoid.RootPart == nil then return end;
		self.RootPart.Velocity = Vector3.new();
		local smokeParticle = script.Smoke:Clone();
		smokeParticle.Size = radius or 16;
		smokeParticle.Parent = self.RootPart;
		for t=1, (ticks or 4) do
			if self.Enemies == nil then return end;
			for a=1, #self.Enemies do
				local enemyHumanoid = self.Enemies[a].Humanoid;
				if enemyHumanoid.RootPart and self.RootPart then
					local distance = (enemyHumanoid.RootPart.CFrame.p-self.RootPart.CFrame.p).Magnitude
					if distance < radius and enemyHumanoid and enemyHumanoid.Health > 0 then
						local ratio = math.clamp(distance/radius, 0, 1);
						local dmg = (1-ratio) * (damage or 10);
						if game.Players:FindFirstChild(enemyHumanoid.Parent.Name) then
							local classPlayer = modPlayers.Get(game.Players[enemyHumanoid.Parent.Name]);
							
							if classPlayer then
								local gasProtection = classPlayer:GetBodyEquipment("GasProtection");
								if gasProtection then
									dmg = dmg * (1-gasProtection);
								end
							end
						end
						self:DamageTarget(enemyHumanoid.Parent, dmg);
					end
				else
					break;
				end
			end
			wait(duration or 0.1);
		end
		smokeParticle:Destroy();
	end
end

return Zombie;