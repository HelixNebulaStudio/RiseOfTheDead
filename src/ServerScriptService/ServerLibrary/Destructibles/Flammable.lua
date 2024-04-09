local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

return function(Destructible)
	Destructible.Enabled = true;
	Destructible.MaxHealth = 0;
	Destructible.Health = Destructible.MaxHealth;
	
	
	function Destructible:OnDestroy()
	end
end
