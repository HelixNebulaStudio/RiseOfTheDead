local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local Projectile = require(script.Parent.Projectile);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modStatusLibrary = require(game.ReplicatedStorage.Library.StatusLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local projectilePrefab = script.gasCloud;
local random = Random.new();

--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=10;
		LifeTime=5;
		Bounce=0;
		Acceleration=Vector3.new(0, -0.2, 0);
		KeepAcceleration = true;
		RayRadius=1.5;
	};
	
	function projectile:Activate()
		-- On Launch;
		
		local gasEmitter = self.Prefab:WaitForChild("SporeGasEmitter");
		gasEmitter:Emit(3); --:WaitForChild("SporeGasEmitter")
		
	end	
	
	function projectile:OnContact(arcPoint)
		if arcPoint.Hit == nil then return end;
		Debugger.Expire(self.Prefab, 0);
			
		local player = game.Players:GetPlayerFromCharacter(arcPoint.Hit.Parent);
		
		if player then
			local classPlayer = shared.modPlayers.Get(player);
			
			for k, status in pairs(classPlayer.Properties) do
				local lib = modStatusLibrary:Find(k);
				if lib == nil or lib.Buff == false then continue end
				if lib.Cleansable ~= true then continue end;
				if status.Expires == nil then continue end;

				status.Expires = modSyncTime.GetTime();
				classPlayer:SyncProperty(k);
			end

			modStatusEffects.Dizzy(player, 3, "bloater");
		end
		
			
		return true;
		--if arcPoint.Hit and not arcPoint.Hit.Anchored then
		--	self.Prefab.Anchored = false;
		--	if RunService:IsServer() then
		--		if self.Prefab:CanSetNetworkOwnership() then self.Prefab:SetNetworkOwner(nil) end;
		--	end
			
		--	local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;
		--	local weld = Instance.new("Motor6D");
		--	weld.Name = "stick";
		--	weld.Parent = self.Prefab;
			
		--	weld.Part0 = self.Prefab;
		--	weld.Part1 = hitPart;
			
		--	local worldCf = CFrame.new(hitPoint, hitPoint - arcPoint.Direction);
		--	weld.C1 = hitPart.CFrame:ToObjectSpace(worldCf);
		--end
	end
	
	return projectile;
end

return Pool;
