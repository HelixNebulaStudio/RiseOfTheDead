local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local Human = {};

function Human.new(self)
	local lastDamaged = tick();
	
	return function()
		self.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn; lastDamaged = tick();
		
		task.delay(2, function()
			if tick()-lastDamaged > 2 and self.Humanoid then
				self.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			end;
		end);
		
		task.wait();
		local hurtSound = modAudio.Play("ZombieHurt", self.RootPart);
		hurtSound.Volume = random:NextNumber(0.5, 0.6);
		hurtSound.PlaybackSpeed = random:NextNumber(1.1, 1.2);
	end
end

return Human;