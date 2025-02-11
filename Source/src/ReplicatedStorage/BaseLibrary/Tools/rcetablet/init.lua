local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=14471065189;};
		Use={Id=14471085942};
	};
	Audio={};
	Configurations={
		UseViewmodel = false;

		ItemPromptHint = " to use tablet.";
	};
	Properties={};
};

function toolPackage.OnServerEquip(handler)
	local weaponModel = handler.Prefabs[1];
	local handle = weaponModel.Handle;
	
	local baseInteractable = script:WaitForChild("Interactable");
	handler.InteractScript = baseInteractable:Clone();
	handler.InteractScript.Parent = handle;
end

function toolPackage.OnActionEvent(handler, packet)
	if packet.ActionIndex ~= 1 then return end;

	handler.IsActive = packet.IsActive == true;
end

function toolPackage.ClientItemPrompt(handler)
	local localPlayer = game.Players.LocalPlayer;
	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
	local prefab = handler.Prefabs[1];
	local primaryPart = prefab.PrimaryPart;
	local interactableModule = primaryPart:FindFirstChild("Interactable");
	
	modData.InteractRequest(interactableModule, primaryPart);
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;