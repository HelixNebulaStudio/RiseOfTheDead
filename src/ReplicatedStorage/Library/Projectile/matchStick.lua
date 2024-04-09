local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.MatchStick;
local random = Random.new();
--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=100;
		Bounce=0;
		LifeTime = 4;
		Acceleration = Vector3.new(0, -workspace.Gravity, 0);
		KeepAcceleration = true;
	};
	
	projectile.Configurations = {
		ProjectileVelocity=100;
		ProjectileBounce=0;
		ProjectileLifeTime = 4;
		ProjectileAcceleration = Vector3.new(0, -workspace.Gravity, 0);
		ProjectileKeepAcceleration = true;
	};
	
	function projectile:OnContact(arcPoint)
		local hitPart = arcPoint.Hit;
		if hitPart then
			if RunService:IsServer() then
				if self.Prefab:CanSetNetworkOwnership() then self.Prefab:SetNetworkOwner(nil) end;
				
				if CollectionService:HasTag(hitPart, "Flammable") then
					local modFlammable = require(game.ServerScriptService.ServerLibrary.Flammable);
					modFlammable:Ignite(hitPart);
				end
			end
		end
	end
	
	return projectile;
end

return Pool;
