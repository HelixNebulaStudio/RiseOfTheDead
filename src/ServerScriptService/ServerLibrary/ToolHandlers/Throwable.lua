local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Class;
local ToolHandler = {};
ToolHandler.__index = ToolHandler;

--== Modules;

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);


local TargetableEntities = modConfigurations.TargetableEntities;
--== Script;

function ToolHandler:OnPrimaryFire(...)
	local origin, targetPoint, throwCharge = ...;
	if origin == nil or targetPoint == nil or throwCharge == nil then return end;
	local character = self.Player.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");

	local configurations = self.ToolConfig.Configurations;
	local _, toolModel = next(self.Prefabs);
	local handle = toolModel.PrimaryPart;
	
	if humanoid and humanoid.Health > 0 then
		
		if typeof(origin) ~= "Vector3" then Debugger:Warn("Origin is not vector3"); return end;
		if typeof(targetPoint) ~= "Vector3" then Debugger:Warn("TargetPoint is not vector3"); return end;
		if typeof(throwCharge) ~= "number" then Debugger:Warn("ThrowCharge is not a number"); return end;
		
		local distanceFromHandle = (handle.Position - origin).Magnitude;
		if distanceFromHandle > 10 then Debugger:Warn("Too far from handle."); return end;
		
		local itemLib = modItemsLibrary:Find(self.StorageItem.ItemId);
			
		local profile = modProfile:Get(self.Player);
		local inventory = profile.ActiveInventory;
			
		if self.StorageItem and self.StorageItem.Quantity <= 0 then return end;
		
		
		local projectileObject = modProjectile.Fire(configurations.ProjectileId, CFrame.new(origin), Vector3.new(), nil, self.Player, self.ToolConfig);
		projectileObject.TargetableEntities = TargetableEntities;
		projectileObject.StorageItem = self.StorageItem;
		
		if projectileObject.Prefab:CanSetNetworkOwnership() then projectileObject.Prefab:SetNetworkOwner(nil); end

		throwCharge = math.clamp(throwCharge, 0, 1);

		local velocity;

		if configurations.ThrowingMode == "Directional" then
			local dir = (targetPoint-origin).Unit;

			velocity = dir * configurations.Velocity;

		else
			local velocityScalar = (configurations.Velocity + configurations.VelocityBonus * throwCharge);
			local travelTime = (targetPoint-origin).Magnitude/velocityScalar;
			Debugger:StudioWarn("travelTime",travelTime, "velocityScalar", velocityScalar);
			velocity = projectileObject.ArcTracer:GetVelocityByTime(origin, targetPoint, travelTime);
			
		end


		modProjectile.ServerSimulate(projectileObject, origin, velocity);
		
		local infType = toolModel:GetAttribute("InfAmmo");
		if configurations.ConsumeOnThrow and infType == nil then
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
