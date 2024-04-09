local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local Enemy = {};

function Enemy.new(self)
	local hurtCooldown = tick();
	local lastDamaged = tick();
	
	self.LastHealth = self.Humanoid.Health;
	return function()
		self.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn; lastDamaged = tick();
		delay(2, function()
			if self.Humanoid == nil then return end;
			if tick()-lastDamaged > 2 then self.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff end;
		end);
		if self.Humanoid.Health < self.LastHealth and tick()-hurtCooldown > random:NextNumber(1, 4) then
			hurtCooldown = tick();
			wait(random:NextNumber(0,0.2));
			if self.Configuration then
				if self.Configuration.Audio and self.Configuration.Audio.Hurt ~= false then
					local hurtSound = modAudio.Play(self.Configuration.Audio.Hurt, self.RootPart);
					hurtSound.PlaybackSpeed = random:NextNumber(0.5, 0.65);
					hurtSound.Volume = random:NextNumber(0.25, 0.55);
				elseif self.Configuration.Audio and self.Configuration.Audio.Hurt == false then
				else
					local hurtSound = modAudio.Play("ZombieHurt", self.RootPart);
					hurtSound.PlaybackSpeed = random:NextNumber(0.5, 0.65);
					hurtSound.Volume = random:NextNumber(0.25, 0.55);
				end
			end
		end
		self.LastHealth = self.Humanoid.Health;
	end
end

return Enemy;