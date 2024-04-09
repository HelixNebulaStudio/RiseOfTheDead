local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local random = Random.new();

local Zombie = {};

function Zombie.new(self)
	return function()
		local level = self.Configuration.Level;
		self.Head:WaitForChild("face");
		
		if modConfigurations.SpecialEvent.Halloween then
			self.Head.face.Texture = "http://www.roblox.com/asset/?id=5807299076";
			self.Head.face.Color3 = Color3.fromRGB(2550, 500, 500);
			return;
		end;
		
		if level == 1 then
			self.Head.face.Texture = "rbxassetid://2025515371";
		elseif level == 2 then
			self.Head.face.Texture = "rbxassetid://2025517777";
		elseif level == 3 then
			self.Head.face.Texture = "rbxassetid://3396962265";
		elseif level == 4 then
			self.Head.face.Texture = "rbxassetid://3396968610";
		elseif level == 5 then
			self.Head.face.Texture = "rbxassetid://3396968909";
		end
	end
end

return Zombie;