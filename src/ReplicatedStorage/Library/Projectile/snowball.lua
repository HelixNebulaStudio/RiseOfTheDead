local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local Projectile = require(script.Parent.Projectile);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local projectilePrefab = script.Snowball;
local random = Random.new();

local templateSnowSplash = game.ReplicatedStorage.Particles.SnowSplash;

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		KeepAcceleration=true;
		Velocity=250;
		LifeTime=20;
		Bounce=0;
		IgnoreWater=false;
		RayRadius=0.6;
	}
	
	projectile.Configurations = {
		ProjectileKeepAcceleration=true;
		ProjectileVelocity=250;
		ProjectileLifeTime=20;
		ProjectileBounce=0;
		IgnoreWater=false;
	};
	
	function projectile:Activate()
		
	end	
	
	function projectile:OnContact(arcPoint)
		if RunService:IsClient() then return end;
		
		local hitPart = arcPoint.Hit;
		local hitPosition = arcPoint.Point;
		local hitMaterial = arcPoint.Material;
		
		if hitMaterial == Enum.Material.Water then
			local snd = modAudio.Play("HeavySplash", hitPosition);
			snd.Volume = 1;
			snd.PlaybackSpeed = math.random(270, 310)/100;
			
			Debugger.Expire(self.Prefab, 0);
			
			return true -- break arctrace;
			
		elseif hitPart then
			local snd = modAudio.Play("SnowballImpact", hitPosition);
			snd.Volume = 2;
			snd.PlaybackSpeed = math.random(70, 85)/100;

			Debugger.Expire(self.Prefab, 0);
			
			local pt = Debugger:PointPart(hitPosition);
			pt.Transparency = 1;
			Debugger.Expire(pt, 1.5);
			
			local snowSplash = templateSnowSplash:Clone();
			snowSplash.Parent = pt
			
			snowSplash:Emit(math.random(8, 10));
			
			Debugger.Expire(self.Prefab, 0);
			
			
			local damagable = modDamagable.NewDamagable(hitPart.Parent);
			if damagable and damagable:CanDamage(self.Owner) then
				local npcStatus = damagable.Object;
				
				if damagable.Object.ClassName == "NpcStatus" then
					local npcModule = npcStatus:GetModule();
					local humanoid = npcStatus.NpcModule.Humanoid;

					modDamageTag.Tag(npcModule.Prefab, self.Owner.Character);
					
					if npcModule.Name == "Winter Treelum" then
						local damage = math.clamp(humanoid.Health * 0.01, 45, Projectile.MaxDamage);

						npcStatus:TakeDamagePackage(modDamagable.NewDamageSource{
							Damage=damage;
							Dealer=self.Owner;
							ToolStorageItem=self.StorageItem;
							TargetPart=hitPart;
							DamageType="FrostDamage";
							DamageCate=modDamagable.DamageCategory.Projectile;
						});
						
					else
						npcStatus:TakeDamagePackage(modDamagable.NewDamageSource{
							Damage=45;
							Dealer=self.Owner;
							ToolStorageItem=self.StorageItem;
							TargetPart=hitPart;
							DamageType="FrostDamage";
							DamageCate=modDamagable.DamageCategory.Projectile;
						});
						
					end
					
				else
					npcStatus:TakeDamagePackage(modDamagable.NewDamageSource{
						Damage=45;
						Dealer=self.Owner;
						ToolStorageItem=self.StorageItem;
						TargetPart=hitPart;
						DamageType="FrostDamage";
						DamageCate=modDamagable.DamageCategory.Projectile;
					});

				end
			end

			return true -- break arctrace;
		end
		
		return;
	end
	
	return projectile;
end

return Pool;