local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
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

function toolPackage.ServerEquip(handler)
	handler.Fuel = handler.StorageItem:GetValues("Fuel") or 100;
end

function toolPackage.OnServerUnequip(handler)
	handler.StorageItem:SetValues("Fuel", (handler.Fuel or 100));
end

function toolPackage.OnActionEvent(handler, packet)
	local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
	local modMath = require(game.ReplicatedStorage.Library.Util.Math);

	handler.IsActive = packet.IsActive == true;

	local prefab = handler.Prefabs[1];
	local emitter = prefab:FindFirstChild("gasolineParticle", true);

	handler.Fuel = handler.StorageItem:GetValues("Fuel") or 100;

	if emitter then
		if handler.IsActive then
			if handler.Fuel > 0 then
				emitter.Enabled = true;

				local attachPoint = emitter.Parent;
				repeat

					local origin = CFrame.new(attachPoint.WorldPosition+Vector3.new(0, 1, 0));

					local projectileObject = modProjectile.Fire("Gasoline", origin, Vector3.new(0, -1, 0), nil, handler.Player);

					local spreadLookVec = modMath.CFrameSpread(-Vector3.yAxis, 90);

					modProjectile.ServerSimulate(projectileObject, origin.p, spreadLookVec * 20);

					handler.Fuel = handler.Fuel - 5;
					handler.StorageItem:SetValues("Fuel", handler.Fuel):Sync("Fuel");

					wait(0.5);
				until not handler.IsActive or handler.Fuel <= 0 or not prefab:IsDescendantOf(workspace);
			end
		end
		emitter.Enabled = false;
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;