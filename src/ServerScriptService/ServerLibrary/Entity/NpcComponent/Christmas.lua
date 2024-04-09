local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local Christmas = {};

local hairPrefabs = {
	script:WaitForChild("SantaHat");
	script:WaitForChild("Cartoony Santa");
	script:WaitForChild("santahat");
};

function Christmas.new(self)
	return function()
		if self.Prefab.Name == "Mr. Klaws" then return end;
		if random:NextInteger(1, 10) == 1 then
			local hair = hairPrefabs[random:NextInteger(1, #hairPrefabs)]:Clone();
			hair.Parent = self.Prefab;
			if self.Configuration then
				self.Configuration.SantaHat = true;
			end
		end
	end
end

return Christmas;