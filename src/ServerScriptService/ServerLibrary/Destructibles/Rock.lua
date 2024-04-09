local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local destructPrefab = game.ServerStorage.PrefabStorage.Destructibles:WaitForChild(script.Name.."Destruct");

return function(Destructible)
	Destructible.Enabled = true;
	Destructible.MaxHealth = 5000;
	Destructible.Health = Destructible.MaxHealth;
	
	function Destructible:OnDestroy()
		local newDestruct = destructPrefab:Clone();
		newDestruct:SetPrimaryPartCFrame(self.Prefab.BaseRock.CFrame);
		newDestruct.Parent = self.Prefab;
		for _, obj in pairs(newDestruct:GetChildren()) do
			if obj:IsA("BasePart") then
				obj.Velocity = (obj.Position-newDestruct.PrimaryPart.Position).Unit*random:NextNumber(30, 45);
			end
		end
		
		self.Prefab.BaseRock:Destroy();
		game.Debris:AddItem(self.Prefab, 5);
	end
	
	function Destructible:OnEnableChange()
		self.Prefab.BaseRock.Color = self.Enabled and Color3.fromRGB(163, 162, 165) or Color3.fromRGB(99, 95, 98);
	end
end
