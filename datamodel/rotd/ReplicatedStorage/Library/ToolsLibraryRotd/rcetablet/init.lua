local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
--==

local toolPackage = {
	ItemId = script.Name;
	Class = "Tool";
	HandlerType = "GenericTool";

	Animations = {
		Core={Id=14471065189;};
		Use={Id=14471085942};
	};
	Audio = {};
	Configurations = {
		UseViewmodel = false;

		ItemPromptHint = " to use tablet.";
	};
	Properties = {};
};

function toolPackage.ServerEquip(handler: ToolHandlerInstance)
	local weaponModel = handler.MainToolModel;
	
	local newInteractConfig = modInteractables.createInteractable("Terminal");
	newInteractConfig.Parent = weaponModel;
end

function toolPackage.ActionEvent(handler, packet)
	if packet.ActionIndex ~= 1 then return end;

	handler.IsActive = packet.IsActive == true;
end

function toolPackage.ClientItemPrompt(handler: ToolHandlerInstance)
	local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
	local prefab = handler.MainToolModel;
	local interactConfig = prefab:FindFirstChild("Interactable");

	modData.InteractRequest(interactConfig);
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;