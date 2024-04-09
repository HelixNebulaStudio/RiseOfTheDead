local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.Grenade;
local random = Random.new();

--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=50;
		LifeTime=10;
		Bounce=0;
		Acceleration=Vector3.new(0, workspace.Gravity, 0);
		KeepAcceleration = true;
	};
	
	function projectile:Activate()
		-- On Launch;
	end	
	
	function projectile:OnContact(arcPoint)
		if arcPoint.Hit and not arcPoint.Hit.Anchored then
			self.Prefab.Anchored = false;
			if RunService:IsServer() then
				if self.Prefab:CanSetNetworkOwnership() then self.Prefab:SetNetworkOwner(nil) end;
			end
			
			local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;
			local weld = Instance.new("Motor6D");
			weld.Name = "stick";
			weld.Parent = self.Prefab;
			
			weld.Part0 = self.Prefab;
			weld.Part1 = hitPart;
			
			local worldCf = CFrame.new(hitPoint, hitPoint - arcPoint.Direction);
			weld.C1 = hitPart.CFrame:ToObjectSpace(worldCf);
		end
	end
	
	return projectile;
end

return Pool;