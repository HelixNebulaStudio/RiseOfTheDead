local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

return function(Destructible)
	Destructible.Enabled = true;
	Destructible.MaxHealth = 5000;
	Destructible.Health = Destructible.MaxHealth;
	
	function Destructible:OnDestroy()
		self:DestroyExplode(30, 45);
		game.Debris:AddItem(self.Prefab, 60);
	end
end
