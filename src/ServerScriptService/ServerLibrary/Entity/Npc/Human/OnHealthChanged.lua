local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local Human = {};

function Human.new(self)
	local lastDamaged = tick();
	
	return function()
		self.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn; lastDamaged = tick();
		delay(2, function()
			if tick()-lastDamaged > 2 and self.Humanoid then
				self.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			end;
		end);
	end
end

return Human;