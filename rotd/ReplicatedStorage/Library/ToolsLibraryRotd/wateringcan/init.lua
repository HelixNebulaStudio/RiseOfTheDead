local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);
--==

local toolPackage = {
	ItemId = script.Name;
	Class = "Tool";
	HandlerType = "GenericTool";

	Animations = {
		Core={Id=5191611634;};
		Use={Id=5191647600};
	};
	Audio = {};
	Configurations = {};
	Properties = {};
};

function toolPackage.ServerEquip(toolHandler: ToolHandlerInstance)
	local properties = toolHandler.EquipmentClass.Properties;
	properties.Water = toolHandler.StorageItem:GetValues("Water") or 100;
end

function toolPackage.ServerUnequip(toolHandler: ToolHandlerInstance)
	local properties = toolHandler.EquipmentClass.Properties;
	toolHandler.StorageItem:SetValues("Water", (properties.Water or 100));
	properties.IsActive = false;
end

function toolPackage.ActionEvent(toolHandler: ToolHandlerInstance, packet)
	local toolModel = toolHandler.MainToolModel;
	local storageItem: StorageItem = toolHandler.StorageItem;

	local properties = toolHandler.EquipmentClass.Properties;
	properties.IsActive = packet.IsActive == true;
	properties.Water = storageItem:GetValues("Water") or 100;

	local outletHoles = toolModel:FindFirstChild("outletHoles");
	local waterParticle = outletHoles:FindFirstChild("waterParticle");
	local waterOutlet = outletHoles:FindFirstChild("WaterOutlet");

	if properties.IsActive and properties.Water > 0 then
		waterParticle.Enabled = true;

		local attachPoint = waterOutlet;
		repeat
			local origin = CFrame.new(attachPoint.WorldPosition);

			local projectileInstance: ProjectileInstance = modProjectile.fire("water", {
				CharacterClass = toolHandler.CharacterClass;
				OriginCFrame = origin;
				SpreadDirection = Vector3.new(0, -1, 0);
			});
					
			local spreadLookVec = modMath.CFrameSpread(-Vector3.yAxis, 90);
			modProjectile.serverSimulate(projectileInstance, {
				Velocity = spreadLookVec * 20;
				IncludeInstances = {workspace.Environment; workspace.Terrain; workspace.Interactables};
				IgnoreEntities = true;
			});

			properties.Water = properties.Water - 4;
			storageItem:SetValues("Water", properties.Water);
			storageItem:Sync({"Water"});

			task.wait(0.5);
			if properties.IsActive == false then break; end;
		until properties.Water <= 0 or not workspace:IsAncestorOf(toolModel);
	end
	properties.IsActive = false;
	waterParticle.Enabled = false;
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;