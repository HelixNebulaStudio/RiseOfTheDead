local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local random = Random.new();

return function(Destructible)
	Destructible.Enabled = true;
	Destructible.MaxHealth = 1000;
	Destructible.Health = Destructible.MaxHealth;
	
	function Destructible:OnDestroy()
		if self.Prefab.PrimaryPart then
			modAudio.Play("VechicleExplosion", self.Prefab.PrimaryPart);
			modAudio.Play("Explosion4", self.Prefab.PrimaryPart);
		end
		
		local ex = Instance.new("Explosion");
		ex.DestroyJointRadiusPercent = 0;
		ex.BlastRadius = 16;
		ex.BlastPressure = 0;
		ex.Position = self.Prefab.PrimaryPart.Position;
		
		if RunService:IsServer() then
			local hitList = {};
			delay(6, function() hitList = {}; end)
			
			ex.Hit:Connect(function(hitPart, distance)
				local npcModel = hitPart.Parent;
				local humanoid = npcModel:FindFirstChildWhichIsA("Humanoid");
				if humanoid and hitList[humanoid] == nil then
					hitList[humanoid] = true;
					
					local damagable = modDamagable.NewDamagable(npcModel);
					if damagable then
						if damagable.Object.ClassName == "NpcStatus" then
							local npcModule = damagable.Object:GetModule();
							
							if npcModule.Name == "Zomborg Prime" then
								npcModule.PlayAnimation("Stun");
								damagable:TakeDamagePackage(modDamagable.NewDamageSource{
									Damage=25000;
									Dealer=Destructible;
									DamageType="Explosive";
									DamageCate=modDamagable.DamageCategory.ExplosiveBarrel;
								});
								
								if npcModule.Stunned == nil then
									npcModule.Stunned = true;
									pcall(function()
										npcModule.Prefab.PowerSource.StunEffect.Enabled = true;
										npcModule.Prefab.PowerSource.StunEffect2.Enabled = true;
									end)
									npcModule.Humanoid.WalkSpeed = 0;
								end
								
							elseif npcModule.Humanoid.Name == "Zombie" then
								local isBasicEnemy = npcModule.Properties and npcModule.Properties.BasicEnemy;
								
								damagable:TakeDamagePackage(modDamagable.NewDamageSource{
									Damage=(humanoid.MaxHealth * (isBasicEnemy and random:NextNumber(0.8, 1) or random:NextNumber(0.1, 0.2)));
									Dealer=Destructible;
									DamageType="Explosive";
									DamageCate=modDamagable.DamageCategory.ExplosiveBarrel;
								});
							end
						end
					end
					
				end
			end)
			ex.Parent = workspace;
		end
		
		for _, obj in pairs(self.Prefab:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.Anchored = false;
				obj.CanCollide = true;
				obj.Velocity = Vector3.new(random:NextNumber(-50, 50), 20, random:NextNumber(-50, 50));
				
			end
		end
		game.Debris:AddItem(self.Prefab, 60);
	end
end
