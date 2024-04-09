local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local destructPrefab = game.ServerStorage.PrefabStorage.Destructibles:WaitForChild(script.Name.."Destruct");

return function(Destructible)
	Destructible.Enabled = true;
	Destructible.MaxHealth = 5000;
	Destructible.Health = Destructible.MaxHealth;
	
	function Destructible:OnDestroy()
		local newDestruct = destructPrefab:Clone();
		newDestruct:SetPrimaryPartCFrame(self.Prefab.Crate.CFrame);
		newDestruct.Parent = self.Prefab;
		for _, obj in pairs(newDestruct:GetChildren()) do
			if obj:IsA("BasePart") then
				if obj ~= newDestruct then
					obj.Velocity = (obj.Position-newDestruct.PrimaryPart.Position).Unit*random:NextNumber(30, 45);
				end
			end
		end
		
		self.Prefab.Crate:Destroy();
		game.Debris:AddItem(self.Prefab, 60);
	end
end
