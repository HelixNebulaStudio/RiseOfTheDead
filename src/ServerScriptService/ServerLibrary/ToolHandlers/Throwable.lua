local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Class;
local ToolHandler = {};
ToolHandler.__index = ToolHandler;

--== Modules;
local RunService = game:GetService("RunService");


local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modArcTracing = require(game.ReplicatedStorage.Library.ArcTracing);

local TargetableEntities = modConfigurations.TargetableEntities;
--== Script;

function ToolHandler:OnPrimaryFire(...)
	local origin, direction, throwCharge, rootVelocity = ...;
	if origin == nil or direction == nil or throwCharge == nil or rootVelocity == nil then return end;
	local character = self.Player.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");
	local rootPart = humanoid and humanoid.RootPart;

	local configurations = self.ToolConfig.Configurations;
	local _, handle = next(self.Prefabs);
	handle = handle.PrimaryPart;
	
	if humanoid and humanoid.Health > 0 then
		
		if typeof(origin) ~= "Vector3" then Debugger:Warn("Origin is not vector3") return end;
		if typeof(direction) ~= "Vector3" then Debugger:Warn("Direction is not vector3") return end;
		if typeof(throwCharge) ~= "number" then Debugger:Warn("ThrowCharge is not a number") return end;
		if typeof(rootVelocity) ~= "Vector3" then Debugger:Warn("RootVelocity is not vector3") return end;
		
		local distanceFromHandle = (handle.Position - origin).Magnitude;
		if distanceFromHandle > 10 then Debugger:Warn("Too far from handle.") return end;
		
		local itemLib = modItemsLibrary:Find(self.StorageItem.ItemId);
			
		local profile = modProfile:Get(self.Player);
		local inventory = profile.ActiveInventory;
			
		if self.StorageItem and self.StorageItem.Quantity <= 0 then return end;
		
		throwCharge = math.clamp(throwCharge, 0, 1);
		direction = direction.Unit;
		rootVelocity = rootVelocity.Unit * math.clamp(rootVelocity.Magnitude, 0, 60);
		
		local projectileObject = modProjectile.Fire(configurations.ProjectileId, CFrame.new(origin, origin + direction), Vector3.new(), nil, self.Player, self.ToolConfig);
		projectileObject.TargetableEntities = TargetableEntities;
		projectileObject.StorageItem = self.StorageItem;
		
		if projectileObject.Prefab:CanSetNetworkOwnership() then projectileObject.Prefab:SetNetworkOwner(nil); end

		modProjectile.ServerSimulate(
			projectileObject, 
			origin, 
			direction * (configurations.Velocity + (configurations.VelocityBonus or 0) * throwCharge)+ rootVelocity);
		
		if configurations.ConsumeOnThrow then
			inventory:Remove(self.StorageItem.ID, 1);
			shared.Notify(self.Player, ("1 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");
		end
	end
end

function ToolHandler.new(player, storageItem, toolPackage, toolModels)
	local self = {
		Player = player;
		StorageItem = storageItem;
		ToolPackage = toolPackage;
		Prefabs = toolModels;
	};
	self.ToolConfig = toolPackage.NewToolLib(self);
	
	setmetatable(self, ToolHandler);
	return self;
end

return ToolHandler;
