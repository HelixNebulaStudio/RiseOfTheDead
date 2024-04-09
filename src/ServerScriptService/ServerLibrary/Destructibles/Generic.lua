local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

return function(Destructible)
	Destructible.Enabled = true;
	Destructible.MaxHealth = 2000;
	Destructible.Health = Destructible.MaxHealth;
	
	function Destructible:OnDestroy()
		self.Prefab.Parent = workspace.Debris;
		game.Debris:AddItem(self.Prefab, 60);
		for _, obj in pairs(self.Prefab:GetDescendants()) do
			if obj:IsA("JointInstance") then
				obj:Destroy();
				
			elseif obj:IsA("BasePart") then
				obj.Anchored = false;
				game.Debris:AddItem(obj, 60);
				
				if self.Prefab.PrimaryPart and self.Prefab.PrimaryPart ~= obj then
					obj.Velocity = (obj.Position - self.Prefab.PrimaryPart.Position).Unit * random:NextNumber(35, 40);
				end
				
				if obj.Name == "Clip" or obj.Name == "Debris" or obj.Name == "PrimaryPart" then
					game.Debris:AddItem(obj, 0);
				end
			end
		end
	end
end
