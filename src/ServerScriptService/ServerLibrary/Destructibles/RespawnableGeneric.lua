local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

return function(Destructible)
	Destructible.Enabled = true;
	Destructible.MaxHealth = 2000;
	Destructible.Health = Destructible.MaxHealth;
	Destructible.Respawn = {Min=20; Max=40;};
	
	function Destructible:OnDestroy()
		game.Debris:AddItem(self.Prefab, 60);
		for _, obj in pairs(self.Prefab:GetDescendants()) do
			if obj:IsA("JointInstance") then
				obj:Destroy();
				
			elseif obj:IsA("BasePart") then
				obj.Anchored = false;
				
				if self.Prefab.PrimaryPart then
					obj.Velocity = (obj.Position - self.Prefab.PrimaryPart.Position).Unit*random:NextNumber(30, 45);
				end
				
				if obj.Name == "Clip" or obj.Name == "Debris" then
					game.Debris:AddItem(obj, 0);
				end
			end
		end
	end
end
