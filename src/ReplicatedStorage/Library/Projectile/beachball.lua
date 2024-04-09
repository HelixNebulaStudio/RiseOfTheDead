local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local Projectile = require(script.Parent.Projectile);

local modProjectileRicochet = require(game.ReplicatedStorage.Library.Projectile.Mechanics.Ricochet);

local projectilePrefab = script.beachball;
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	--projectile.Configurations = {
	--	ProjectileVelocity=50;
	--	ProjectileLifeTime=10;
	--	ProjectileBounce=0.9;
	--};
	
	projectile.ArcTracerConfig = {
		Velocity=50;
		Bounce=0.9;
		MaxBounce=32;
		LifeTime=10;
		RayRadius=1.5;
	}
	
	function projectile:Activate()
	end	
	
	local hitTracker = {};
	function projectile:ProjectileDamage(hitObjects)
		local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
		
		hitObjects = type(hitObjects) == "table" and hitObjects or {hitObjects};
		for _, hitObj in pairs(hitObjects) do
			local targetModel = hitObj.Parent;
			local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
			local dmgMulti = humanoid and self.TargetableEntities[humanoid.Name];
			
			if humanoid and dmgMulti then
				if hitTracker == nil then return end;
				if hitTracker[humanoid] == nil or tick()-hitTracker[humanoid] >= 1 then
					hitTracker[humanoid] = tick();
				
					if targetModel then
						--== Duel
						local duelDmgMulti = bindIsInDuel:Invoke(self.Owner, humanoid.Parent.Name);
						if duelDmgMulti then dmgMulti = duelDmgMulti end;
						--== Duel
					end
					
					modTagging.Tag(targetModel, self.Owner.Character);
					humanoid = (targetModel:FindFirstChild("NpcStatus") and require(targetModel.NpcStatus)) or humanoid;
					
					if humanoid.ClassName == "NpcStatus" and not humanoid:CanTakeDamageFrom(self.Owner) then
						return;
					end
					
					local damage = self.Configurations.Damage;
					damage = damage*dmgMulti;
					humanoid:TakeDamage(damage, self.Owner, self.StorageItem, hitObj);
					if humanoid.RootPart then
						local dir = ((humanoid.RootPart.Position - self.Prefab.Position) * Vector3.new(1, 0, 1)).Unit * 128;
						humanoid.RootPart.Velocity = humanoid.RootPart.Velocity + Vector3.new(dir.X, 20, dir.Z);
					end
					modAudio.Play("Beachball", self.Prefab);
				end
			end
		end
	end
	
	if RunService:IsServer() then
		projectile.Prefab.Touched:Connect(function(part)
			projectile:ProjectileDamage(part);
		end)
	end
	
	function projectile:Destroy()
		hitTracker = nil;
	end
	
	--function projectile:OnStepped(arcPoint)
	--	modProjectileRicochet.OnStepped(self, arcPoint);
	--end
	
	function projectile:OnContact(arcPoint)
		if arcPoint.Hit and RunService:IsServer() then
			modAudio.Play("Beachball", self.Prefab).MaxDistance = 256;
			
			projectile:ProjectileDamage(arcPoint.Hit);
			
		end
	end
	
	return projectile;
end

return Pool;