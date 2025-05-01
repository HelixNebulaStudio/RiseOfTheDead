local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=5932487712;};
		Use={Id=5932203028};
	};
	Audio={};
	Configurations={};
	Properties={};
};

function toolPackage.OnClientUnequip(handler)
	local localPlayer = game.Players.LocalPlayer;
	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();
	
	modInterface:CloseWindow("GpsWindow");
end

function toolPackage.ClientItemPrompt(handler)
	local localPlayer = game.Players.LocalPlayer;
	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();
	
	modInterface:OpenWindow("GpsWindow", handler);
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;