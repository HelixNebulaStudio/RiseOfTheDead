local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=5191611634;};
		Use={Id=5191647600};
	};
	Audio={};
	Configurations={};
	Properties={};
};

function toolPackage.ActionEvent(handler, packet)
	local prefab = handler.Prefabs[1];
	local outletHoles = prefab:FindFirstChild("outletHoles");
	local waterParticle = outletHoles and outletHoles:FindFirstChild("waterParticle");
	if waterParticle then
		waterParticle.Enabled = packet.IsActive == true;
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;