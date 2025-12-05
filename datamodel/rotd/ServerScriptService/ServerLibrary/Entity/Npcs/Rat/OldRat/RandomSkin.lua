local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local Rat = {};

local skinColors = {
	BrickColor.new("Light orange");
	BrickColor.new("Pine Cone");
	BrickColor.new("Dirt brown");
	BrickColor.new("Nougat");
	BrickColor.new("Brick yellow");
	BrickColor.new("Linen");
};

local faces = {
	"http://www.roblox.com/asset/?id=13079565";
	"http://www.roblox.com/asset/?id=6306427742";
};

local ratShirts = {
	"rbxassetid://9685674212";
	"rbxassetid://9685674641";
	"rbxassetid://9685674902";
	"rbxassetid://9685675286";
	"rbxassetid://9685675656";
}

local ratPants = {
	"rbxassetid://79254205";
	"rbxassetid://1241012595";
	"rbxassetid://1106996955";
};

local hairPrefabs = {};

for _, obj in pairs(script:GetChildren()) do
	if obj:IsA("Accessory") then
		table.insert(hairPrefabs, obj);
	end
end

function Rat.new(self)
	return function()
		local random = self.Seed and Random.new(self.Seed) or Random.new();
		
		if self.Name == "Rat" then
			local face = self.Head:WaitForChild("face");
			face.Texture = faces[random:NextInteger(1, #faces)];
			
			local shirt = self.Prefab:WaitForChild("Shirt");
			shirt.ShirtTemplate = ratShirts[random:NextInteger(1, #ratShirts)];
			
			local pants = self.Prefab:WaitForChild("Pants");
			pants.PantsTemplate = ratPants[random:NextInteger(1, #ratPants)];
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
		
		if self.Name ~= "Rat" or random:NextInteger(1, 10) <= 9 then
			local hair = hairPrefabs[random:NextInteger(1, #hairPrefabs)]:Clone();
			hair.Parent = self.Prefab;
		end
	end
end

return Rat;