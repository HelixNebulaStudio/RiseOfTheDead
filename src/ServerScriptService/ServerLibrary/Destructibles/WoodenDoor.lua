local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

return function(Destructible)
	Destructible.Enabled = true;
	Destructible.MaxHealth = 5000;
	Destructible.Health = Destructible.MaxHealth;
	
	function Destructible:OnDestroy()
		local clipBox = self.Prefab:FindFirstChild("clipBox");
		
		local door = self.Prefab:FindFirstChild("door");
		if door then
			for _, obj in pairs(door:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.Anchored = false;
				end
			end
		end
		if clipBox then clipBox:Destroy(); end
		
		delay(10, function()
			for _, obj in pairs(self.Prefab:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.Anchored = false;
				end
			end
		end)
		game.Debris:AddItem(self.Prefab, 30);
	end
end
