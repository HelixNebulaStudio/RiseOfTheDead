local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local Projectile = require(script.Parent.Projectile);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local projectilePrefab = script.beachball;
--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=50;
		Bounce=0.9;
		MaxBounce=32;
		LifeTime=10;
		RayRadius=1.5;
	};

	function projectile:OnContact(arcPoint)
		if RunService:IsClient() then return end;
		if arcPoint.Hit == nil then return end;

		local hitPart = arcPoint.Hit;
		local hitPosition = arcPoint.Point;

		modAudio.Play("Beachball", self.Prefab).RollOffMaxDistance = 256;
		
		local damagable = modDamagable.NewDamagable(hitPart.Parent);
		if damagable and damagable:CanDamage(self.Owner) then
			local npcStatus = damagable.Object;
			
			local snd = modAudio.Play("Beachball", hitPosition);
			snd.PlaybackSpeed = math.random(90, 110)/100;
			
			local damage = self.Configurations.Damage;

			if damagable.Object.ClassName == "NpcStatus" then
				local npcModule = npcStatus:GetModule();
				modDamageTag.Tag(npcModule.Prefab, self.Owner.Character);
			end

			npcStatus:TakeDamagePackage(modDamagable.NewDamageSource{
				Damage=damage;
				Dealer=self.Owner;
				ToolStorageItem=self.StorageItem;
				TargetPart=hitPart;
				DamageCate=modDamagable.DamageCategory.Projectile;
			});
		end
	end
	
	return projectile;
end

return Pool;