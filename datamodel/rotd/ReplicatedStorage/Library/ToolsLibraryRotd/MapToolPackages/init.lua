local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local remoteGameModeLobbies = modRemotesManager:Get("GameModeLobbies");

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
	local localPlayer = game.Players.LocalPlayer;
	local playerClass = shared.modPlayers.get(localPlayer);

	if playerClass.Properties.InBossBattle or modConfigurations.DisableMapItems then
		modClientGuis.hintWarning("Cant use this right now!");
		Debugger:Warn(
			"InBossBattle", tostring(playerClass.Properties.InBossBattle), 
			"DisableMapItems", tostring(modConfigurations.DisableMapItems)
		);

		return;
	end
	modClientGuis.toggleGameBlinds(false, 0.5);
	
	local storageItem = handler.StorageItem;
	
	local timeLapse = tick();
	local rPacket = remoteGameModeLobbies:InvokeServer("map", storageItem.ID);
	wait(math.clamp(0.5-(tick()-timeLapse), 0, 0.5));
	modClientGuis.toggleGameBlinds(true, 0.5);
	
	if rPacket and rPacket.Success then
		modClientGuis.toggleWindow("GameRoom", true, rPacket.LobbyData);
	else
		modClientGuis.promptWarning(rPacket.FailMsg or "Please try again!");
	end;

	modClientGuis.toggleGameBlinds(true, 0.5);
end

function toolPackage.ActionEvent(handler: ToolHandlerInstance, packet)
	if packet.ActionIndex ~= 1 then return end;

	local equipmentClass: EquipmentClass = handler.EquipmentClass;
	local properties = equipmentClass.Properties;

	properties.IsActive = packet.IsActive == true;

	local weaponModel = handler.MainToolModel;
	local handle = weaponModel.PrimaryPart;

	for _, obj in pairs(handle:GetChildren()) do
		if obj.Name == "Interactable" and obj:IsA("Configuration") then
			obj:Destroy();
		end
	end

	if properties.IsActive then
		local newInteractConfig = handler.ToolPackage.Interactable:Clone();
		newInteractConfig.Parent = handle;
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
		if inheritPackage.Interactable == nil then
			local itemLib = modItemsLibrary:Find(itemId);
	
			local newInteractConfig = modInteractables.createInteractable("GameModeEnter");
	
			local gameModeInfo = itemLib.GameMode;
			newInteractConfig:SetAttribute("Mode", gameModeInfo.Mode);
			newInteractConfig:SetAttribute("Stage", gameModeInfo.Stage);
			newInteractConfig:SetAttribute("Label", `Join {gameModeInfo.Mode}: {gameModeInfo.Stage}`);
	
			inheritPackage.Interactable = newInteractConfig;
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