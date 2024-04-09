local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local random = Random.new();

local Zombie = {};

function Zombie.new(self)
	return function(targetHumanoid, speed, duration)
		if self.IsDead or self.Humanoid == nil or self.Humanoid.Health <= 0 or self.Humanoid.RootPart == nil then return end;
		if self.Humanoid.PlatformStand then return end;
		
		if targetHumanoid then
			local disarmStatus = self.EntityStatus:GetOrDefault("Disarm");

			if disarmStatus and disarmStatus > tick() then 
				self.PlayAnimation("Disarm");
				return
			end
			
			if self.Configuration.Audio and self.Configuration.Audio.Attack ~= false then
				modAudio.Play(self.Configuration.Audio.Attack, self.RootPart).PlaybackSpeed = random:NextNumber(0.7, 0.9);
			elseif self.Configuration.Audio and self.Configuration.Audio.Attack == false then
			else
				modAudio.Play("ZombieAttack"..random:NextInteger(1, 3), self.RootPart).PlaybackSpeed = random:NextNumber(0.7, 0.9);
			end
			
			local targetCharacter = targetHumanoid.Parent;
			if targetCharacter:FindFirstChild("MeleeEquipped") then
				wait(1);
			end

			if disarmStatus and disarmStatus > tick() then 
				self.PlayAnimation("Disarm");
				return
			end
			
			self.PlayAnimation("Attack",0.05);
			local distance = 0;
			if targetHumanoid.RootPart and self.Humanoid.RootPart then
				distance = (targetHumanoid.RootPart.Position - self.Humanoid.RootPart.Position).Magnitude;
			end
			
			if distance >= self.Properties.AttackRange then
				return;
			end
			
			local dmg = self.Properties.AttackDamage *2.5;
			local dmgRatio = (1- math.clamp(distance/self.Properties.AttackRange, 0, 1)^2);
			local attackDamage = dmg * dmgRatio - (self.DamageReduction or 0);
			if attackDamage > dmg*0.5 then
				local player = game.Players:FindFirstChild(targetHumanoid.Parent.Name);
				if player then
					speed, duration = (speed or 10), (duration or 2);
					modStatusEffects.Slowness(player, speed, duration);
				end
			end
			
			self:DamageTarget(targetHumanoid.Parent, attackDamage, nil, nil, "Melee");
		end
	end
end

return Zombie;