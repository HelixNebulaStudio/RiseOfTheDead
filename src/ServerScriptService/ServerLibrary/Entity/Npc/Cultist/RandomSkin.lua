local modAudio = require(game.ReplicatedStorage.Library.Audio);

local Zombie = {};

local skinColors = {
	BrickColor.new("Light orange");
	BrickColor.new("Pine Cone");
	BrickColor.new("Dirt brown");
	BrickColor.new("Nougat");
	BrickColor.new("Brick yellow");
	BrickColor.new("Linen");
};

local faces = {
	"http://www.roblox.com/asset/?id=255828374";
	"http://www.roblox.com/asset/?id=398671601";
};

local hairPrefabs = {
--	script:WaitForChild("BlackFauxhawk");
};

function Zombie.new(self)
	return function()
		local random = self.Seed and Random.new(self.Seed) or Random.new();
		
		if self.Name == "Bandit" then
			local face = self.Head:WaitForChild("face");
			face.Texture = faces[random:NextInteger(1, #faces)];
		end
		
		if random:NextInteger(1, 10) <= 6 then
			local skinColor = skinColors[random:NextInteger(1, #skinColors)];
			local body = self.Prefab:GetChildren();
			for a=1, #body do
				if body[a]:IsA("BasePart") then
					body[a].BrickColor = skinColor;
				end
			end
		end
		
		if self.Name ~= "Bandit" or random:NextInteger(1, 10) <= 9 then
			local hair = hairPrefabs[random:NextInteger(1, #hairPrefabs)]
			if hair then
				hair = hair:Clone();
				hair.Parent = self.Prefab;
			end
		end
	end
end

return Zombie;