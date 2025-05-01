local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=4988030453;};
		Use={Id=4988004803};
	};
	Audio={};
	Configurations={};
	Properties={};
};

function toolPackage.OnActionEvent(handler, packet)
	local isActive = packet.IsActive == true;
	local prefab = handler.Prefabs[1];
		
	if prefab then
		local rope = prefab:FindFirstChild("rope");
		if rope then
			rope.Transparency = isActive and 0 or 1;
		end
		local ropeCoil = prefab:FindFirstChild("ropeCoil");
		if ropeCoil then
			ropeCoil.Transparency = isActive and 1 or 0;
		end
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;