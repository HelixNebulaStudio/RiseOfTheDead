local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");
local Projectile = require(script.Parent.Projectile);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modExplosionHandler = require(game.ReplicatedStorage.Library.ExplosionHandler);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

local projectilePrefab = script.Rocket;

--== Script;
function Pool.new()
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=150;
		LifeTime=5;
		Bounce=0;
		Acceleration=Vector3.new(0, -workspace.Gravity/32, 0);
		RayRadius=0.25;
	};
	
	projectile.Configurations = {
		ProjectileVelocity=150;
		ProjectileLifeTime=5;
		ProjectileBounce=0;
		ProjectileAcceleration=Vector3.new(0, -workspace.Gravity/32, 0);
	};
	
	function projectile:Activate()
		Debugger.Expire(self.Prefab, self.Configurations.ProjectileLifeTime);
		modAudio.Play("RocketLoop", self.Prefab);
	end
	
	
	local activated = false;
	function projectile:OnContact(arcPoint)
		local hitPart = arcPoint.Hit;
		
		if activated then return end;
		activated = true;

		self.Prefab.Transparency = 1;
		Debugger.Expire(self.Prefab, 0.1);
		
		if not RunService:IsServer() then return end;
		local lastPosition = arcPoint.Point;
		
		local ex = Instance.new("Explosion");
		ex.DestroyJointRadiusPercent = 0;
		ex.BlastRadius = self.Configurations.ExplosionRadius or 20;
		ex.BlastPressure = 0;
		ex.Position = lastPosition;
		ex.Parent = workspace;
		Debugger.Expire(ex, 6);

		local pointAtt = Debugger:Point(lastPosition);

		modAudio.Play(random:NextInteger(1,2)==1 and "Explosion" or "Explosion2", pointAtt);
		Debugger.Expire(pointAtt, 6);
		
		pcall(function()
			local readTerrain = (workspace.Terrain:ReadVoxels(Region3.new(lastPosition, lastPosition):ExpandToGrid(4), 4));
			local terrainMat = readTerrain[1] and readTerrain[1][1] and readTerrain[1][1][1];
			if terrainMat and terrainMat == Enum.Material.Water then
				modAudio.Play("ExplosionUnderwater", pointAtt);
			end
		end)
		
		local hitLayers = modExplosionHandler:Cast(lastPosition, {
			Radius = self.Configurations.ExplosionRadius or 20;
		});
		
		Debugger:Log("hitlist", hitLayers);
		
		local damage = self.Configurations.Damage;
		local explosionStun = self.Configurations.ExplosionStun;
		local damageRatio = self.Configurations.DamageRatio;
		
		modExplosionHandler:Process(lastPosition, hitLayers, {
			OnPartHit=function(hitPart)
				if hitPart.Anchored then return end
				if not workspace.Environment:IsAncestorOf(hitPart) then return end;
				
				
				local rootModel = hitPart;
				while rootModel:GetAttribute("DynamicPlatform") == nil do
					rootModel = rootModel.Parent;
					if rootModel == workspace or rootModel == game then break; end
				end
				if rootModel:GetAttribute("DynamicPlatform") then return end;
				
				
				local assemblyRootPart = hitPart:GetRootPart();
				if assemblyRootPart and assemblyRootPart.Anchored ~= true then
					assemblyRootPart.Velocity = (assemblyRootPart.Position-lastPosition).Unit*30;
				end
			end;
			
			Owner = self.Owner;
			StorageItem = self.StorageItem;
			TargetableEntities = projectile.TargetableEntities;
			
			Damage = damage;
			ExplosionStun = explosionStun;
			DamageRatio = damageRatio;
		});
		
	end

	return projectile;
end

return Pool;
