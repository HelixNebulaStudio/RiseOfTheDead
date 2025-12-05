local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
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

function toolPackage.ActionEvent(handler: ToolHandlerInstance, packet)
	local isActive = packet.IsActive == true;
	local prefab = handler.MainToolModel;
		
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

	local characterClass: CharacterClass = handler.CharacterClass;
	if characterClass and characterClass.ClassName == "NpcClass" then
		if isActive then
			handler.ToolAnimator:Play("Use");
		else
			handler.ToolAnimator:Stop("Use");
		end
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;