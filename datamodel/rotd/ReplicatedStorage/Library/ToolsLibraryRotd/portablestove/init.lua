local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=4706359805;};
	};
	Audio={};
	Configurations={
		DisableMovement = true;
	};
	Properties={};
};

function toolPackage.OnActionEvent(handler, packet)
	local isActive = packet.IsActive;
	local prefab = handler.Prefabs[1];
		
	local food = prefab:FindFirstChild("Food");
	local firePoint = prefab.PrimaryPart:FindFirstChild("FirePoint");
	
	if food then
		for _, obj in pairs(food:GetChildren()) do
			if obj:IsA("BasePart") then
				obj.Transparency = isActive and 0 or 1;
			end
		end
	end
	if firePoint then
		firePoint.FireEffect.Enabled = isActive;
		firePoint.PointLight.Enabled = isActive;
		firePoint.PointLight2.Enabled = isActive;
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;