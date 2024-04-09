local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.poisonWood;
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

--== Script;
local touchHandler = modTouchHandler.new("PoisonIvy", 1);
function touchHandler:OnPlayerTouch(player, basePart, part)
	local npcModel = basePart.Parent;
	
	local modNpcStatus = npcModel:FindFirstChild("NpcStatus") and require(npcModel.NpcStatus);
	modAudio.Play(random:NextInteger(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", basePart);
	
	if modNpcStatus then
		local canDamage = false;
		if modNpcStatus.NpcModule.NetworkOwners and player then
			for a=1, #modNpcStatus.NpcModule.NetworkOwners do
				if modNpcStatus.NpcModule.NetworkOwners[a] == player then
					canDamage = true;
					break;
				end
			end
		else
			canDamage = true;
		end
		
		if canDamage then
			modStatusEffects.Poison(player, 6);
			modNpcStatus.NpcModule:DamageTarget(player.Character, 20);
		end
	end 
end

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		LifeTime=60;
		Velocity=20;
		Bounce=0;
		Acceleration=Vector3.new(0, -workspace.Gravity/16, 0);
		IgnoreEntities=true;
	};
	
	projectile.Configurations = {
		ProjectileLifeTime=60;
		ProjectileVelocity=20;
		ProjectileBounce=0;
		ProjectileAcceleration=Vector3.new(0, -workspace.Gravity/16, 0);
		IgnoreEntities=true;
	};
	
	function projectile:Activate()
		-- On Launch;
		touchHandler:AddObject(self.Prefab);
	end	
	
	function projectile:OnContact(arcPoint)
		if not RunService:IsServer() then return end;
		if arcPoint.Hit then
			if self.Prefab:CanSetNetworkOwnership() then self.Prefab:SetNetworkOwner(nil) end;
			self.Prefab.CFrame = CFrame.new(arcPoint.Point, arcPoint.Point+arcPoint.Direction-arcPoint.Normal);
		end
	end
	
	return projectile;
end

return Pool;
