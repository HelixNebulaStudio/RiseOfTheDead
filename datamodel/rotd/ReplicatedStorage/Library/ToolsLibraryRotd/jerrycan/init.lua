local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=5888506042;};
		Use={Id=5966533550};
	};
	Audio={};
	Configurations={};
	Properties={};
};

function toolPackage.ServerEquip(toolHandler: ToolHandlerInstance)
	local properties = toolHandler.EquipmentClass.Properties;
	properties.Fuel = toolHandler.StorageItem:GetValues("Fuel") or 100;
end

function toolPackage.ServerUnequip(toolHandler: ToolHandlerInstance)
	local properties = toolHandler.EquipmentClass.Properties;
	toolHandler.StorageItem:SetValues("Fuel", (properties.Fuel or 100));
end

function toolPackage.ActionEvent(toolHandler: ToolHandlerInstance, packet)
	local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
	local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

	local properties = toolHandler.EquipmentClass.Properties;
	local storageItem: StorageItem = toolHandler.StorageItem;

	properties.IsActive = packet.IsActive == true;

	local prefab = toolHandler.Prefabs[1];
	local emitter = prefab:FindFirstChild("gasolineParticle", true);

	properties.Fuel = storageItem:GetValues("Fuel") or 100;

	if emitter then
		if properties.IsActive then
			if properties.Fuel > 0 then
				emitter.Enabled = true;

				local attachPoint = emitter.Parent;
				repeat
					local origin = CFrame.new(attachPoint.WorldPosition+Vector3.new(0, 1, 0));

					local projectileInstance: ProjectileInstance = modProjectile.fire("gasoline", {
						OriginCFrame = origin;
						SpreadDirection = Vector3.new(0, -1, 0);
					});
							
					local spreadLookVec = modMath.CFrameSpread(-Vector3.yAxis, 90);
					modProjectile.serverSimulate(projectileInstance, {
						Velocity = spreadLookVec * 20;
						RayWhitelist = {workspace.Environment; workspace.Terrain};
						IgnoreEntities = true;
					});

					properties.Fuel = properties.Fuel - 5;
					storageItem:SetValues("Fuel", properties.Fuel);
					storageItem:Sync({"Fuel"});

					task.wait(0.5);
				until not properties.IsActive or properties.Fuel <= 0 or not prefab:IsDescendantOf(workspace);
			end
		end
		emitter.Enabled = false;
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;