local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local remoteGameModeLobbies = modRemotesManager:Get("GameModeLobbies");
local mapInteractable = script:WaitForChild("Interactable");

local modToolsLibrary;
--==

local toolPackage = {
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=139169439697737;};
		Use={Id=131853830244385};
	};
	Audio={};
	Configurations={
		UseViewmodel = false;

		ItemPromptHint = " to use map.";
	};
	Properties={};
};

function toolPackage.ClientItemPrompt(handler)
	local player = game.Players.LocalPlayer;
	local classPlayer = shared.modPlayers.get(player);

	local modData = shared.require(player:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();
	
	if classPlayer.Properties.InBossBattle or modConfigurations.DisableMapItems then
		modInterface:HintWarning("Cant use this right now!");
		Debugger:Warn("InBossBattle", tostring(classPlayer.Properties.InBossBattle), "DisableMapItems", tostring(modConfigurations.DisableMapItems));

		return;
	end
	modInterface:ToggleGameBlinds(false, 0.5);
	
	local storageItem = handler.StorageItem;
	
	local timeLapse = tick();
	local lobbyData = remoteGameModeLobbies:InvokeServer("StorageItem", storageItem.ID);
	wait(math.clamp(0.5-(tick()-timeLapse), 0, 0.5));
	modData.LobbyInterfaceRequest(lobbyData);
end

function toolPackage.OnActionEvent(handler, packet)
	if packet.ActionIndex ~= 1 then return end;
	handler.IsActive = packet.IsActive == true;

	local weaponModel = handler.Prefabs[1];
	local handle = weaponModel.Handle;

	for _, obj in pairs(handle:GetChildren()) do
		if obj.Name == "Interactable" and obj:IsA("ModuleScript") then
			obj:Destroy();
		end
	end

	if handler.IsActive then
		local copyInteractable = handler.ToolPackage.InteractData.Script:Clone();
		copyInteractable.Parent = handle;
	end
end

function toolPackage.inherit(packet)
	toolPackage.__index = toolPackage;
	local inheritPackage = packet;

	local itemId = packet.ItemId;
	local itemModel = modToolsLibrary.getModel(inheritPackage, script);
	
	inheritPackage.Welds = {
		ToolGrip=itemModel.Name;
	};

	setmetatable(inheritPackage, toolPackage);
	modToolsLibrary.set(inheritPackage);

	function inheritPackage.newClass()
		if inheritPackage.InteractData == nil then
			local itemLib = modItemsLibrary:Find(itemId);
	
			local newInteractable = mapInteractable:Clone();
	
			local gameModeInfo = itemLib.GameMode;
			newInteractable:SetAttribute("Mode", gameModeInfo.Mode);
			newInteractable:SetAttribute("Stage", gameModeInfo.Stage);
			newInteractable:SetAttribute("Label", `Join {gameModeInfo.Mode}: {gameModeInfo.Stage}`);
	
			inheritPackage.InteractData = shared.require(newInteractable);
		end

		return modEquipmentClass.new(inheritPackage.Class, inheritPackage.Configurations, inheritPackage.Properties);
	end

	return inheritPackage;
end

function toolPackage.init(super)
	modToolsLibrary = super;

	toolPackage.inherit({
		ItemId="abandonedbunkermap";
	});
	
	toolPackage.inherit({
		ItemId="banditoutpostmap";
	});
	
	toolPackage.inherit({
		ItemId="communityfissionbaymap";
	});
	
	toolPackage.inherit({
		ItemId="communityrooftopmap";
	});
	
	toolPackage.inherit({
		ItemId="communitywaysidemap";
	});
	
	toolPackage.inherit({
		ItemId="klawsmap";
	});

end

return toolPackage;