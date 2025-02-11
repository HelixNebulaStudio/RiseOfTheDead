local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=13067320148;};
		Use={Id=13067328329};
	};
	Audio={};
	Configurations={
		UseViewmodel = false;
	};
	Properties={};
};

function toolPackage.OnClientEquip()
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();

	modInterface:CloseWindow("MarketNewspaper");
end

function toolPackage.ClientItemPrompt(handler)
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();
	
	modInterface:OpenWindow("MarketNewspaper", handler);
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;