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
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

local projectilePrefab = script.vexSpit;

--== Script;
function Pool.new()
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=150;
		LifeTime=20;
		Bounce=0;
		Acceleration=Vector3.new(0, 0, 0);
		IgnoreEntities=true;
	};
	
	projectile.Configurations = {
		ProjectileVelocity=150;
		ProjectileLifeTime=20;
		ProjectileBounce=0;
		ProjectileAcceleration=Vector3.new(0, 0, 0);
		IgnoreEntities=true;
	};
	
	function projectile:Activate()
		Debugger.Expire(self.Prefab, self.Configurations.ProjectileLifeTime);
	end
	
	function projectile:ProjectileDamage(hitObjects, epicenter)
		local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
		
		local enemyUnits = 0;
		local fs = {};
		
		hitObjects = type(hitObjects) == "table" and hitObjects or {hitObjects};
		
		for _, hitObj in pairs(hitObjects) do
			local targetModel = hitObj.Parent;
			
			local damagable = modDamagable.NewDamagable(targetModel);
			if damagable then
				table.insert(fs, function()
					local damage = self.Configurations.Damage or 1;
					
					local player = game.Players:GetPlayerFromCharacter(targetModel);
					if self.Owner and player == self.Owner then
						if targetModel.PrimaryPart then
							targetModel.PrimaryPart.Velocity = Vector3.new(0, 100, 0);
						end
						
					elseif damagable:CanDamage(self.Owner) then
						modTagging.Tag(targetModel, self.Owner and self.Owner.Character);
						
						local healthInfo = damagable:GetHealthInfo();
						damage = healthInfo.MaxHealth*0.1;
						
						if self.Configurations.ExplosionStun then
							local isHumanoid = typeof(damagable.HealthObj) == "Instance" and damagable.HealthObj:IsA("Humanoid");
							
							if healthInfo.Armor <= 0 and damage > healthInfo.MaxHealth*0.4 and isHumanoid then
								damagable.HealthObj.PlatformStand = true;
								task.delay(self.Configurations.ExplosionStun, function()
									damagable.HealthObj.PlatformStand = false;
								end)
							end
						end

						local newDmgSrc = modDamagable.NewDamageSource{
							Damage=damage;
							Dealer=self.Owner;
							ToolStorageItem=self.StorageItem;
							TargetPart=hitObj;
							DamageType="ExplosiveDamage";
						}
						damagable:TakeDamagePackage(newDmgSrc);

						local assemblyRootPart = player and targetModel.PrimaryPart or hitObj:GetRootPart();
						if assemblyRootPart and assemblyRootPart.Anchored ~= true then
							assemblyRootPart.Velocity = (assemblyRootPart.Position-epicenter).Unit*50 + Vector3.new(0, 40, 0);
						end
						
					end
				end)
			else
				if targetModel.Name == "Zombie" then
					Debugger:Log("No damagable for zombie?");
				end
			end
		end
		for a=1, #fs do
			fs[a]();
		end
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
		ex.BlastRadius = self.Configurations.ExplosionRadius or 10;
		ex.BlastPressure = 0;
		ex.Position = lastPosition;
		ex.Parent = workspace;
		Debugger.Expire(ex, 6);
		
		local soundDebris = Instance.new("Part");
		soundDebris.Size = Vector3.new(0, 0, 0);
		soundDebris.Anchored = true;
		soundDebris.CanCollide = true;
		soundDebris.Transparency = 1;
		soundDebris.Parent = workspace.Debris;
		Debugger.Expire(soundDebris, 6);
		soundDebris.CFrame = CFrame.new(lastPosition);
		modAudio.Play("TicksZombieExplode", soundDebris).PlaybackSpeed = 1.5;
		
		pcall(function()
			local readTerrain = (workspace.Terrain:ReadVoxels(Region3.new(lastPosition, lastPosition):ExpandToGrid(4), 4));
			local terrainMat = readTerrain[1] and readTerrain[1][1] and readTerrain[1][1][1];
			if terrainMat and terrainMat == Enum.Material.Water then
				modAudio.Play("ExplosionUnderwater", soundDebris);
			end
		end)
		
		local hitLayers = modExplosionHandler:Cast(lastPosition, self.Configurations.ExplosionRadius);
		local hitlist = hitLayers and hitLayers[1] or {};
		
		for a=1, #hitlist do
			local hitpart = hitlist[a];
			if not hitpart.Anchored and hitpart:IsDescendantOf(workspace.Environment) then
				local rootModel = hitpart;

				while rootModel:GetAttribute("DynamicPlatform") == nil do
					rootModel = rootModel.Parent;
					if rootModel == workspace or rootModel == game then break; end
				end

				if rootModel:GetAttribute("DynamicPlatform") == nil then
					local assemblyRootPart = hitpart:GetRootPart();
					if assemblyRootPart and assemblyRootPart.Anchored ~= true then
						assemblyRootPart.Velocity = (assemblyRootPart.Position-lastPosition).Unit*30;
						
					end
				end
			end
		end
		
		if self.ProjectileDamage then self:ProjectileDamage(hitlist, lastPosition); end
	end

	return projectile;
end

return Pool;