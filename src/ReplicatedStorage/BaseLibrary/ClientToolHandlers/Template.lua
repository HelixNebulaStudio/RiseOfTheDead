local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

--== Modules;
local modData = require(localPlayer:WaitForChild("DataModule"));

local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);

--== Remotes;
local remoteEngineersPlanner = modRemotesManager:Get("EngineersPlanner");

--== Vars;
local character, humanoid, modCharacter, modInterface, mouseProperties, characterProperties;

local Equipped;
local animationFiles = {};

local ToolHandler = {};
--== Script;

function ToolHandler:Equip(storageItem, toolModels)
	local itemId = storageItem.ItemId;
	local itemLib = modItemsLibrary:Find(itemId);
	
	local toolInfo = modTools[itemId];
	local toolLib = toolInfo.NewToolLib();
	
	local toolModel: Model = Equipped.RightHand.Prefab;
	local handle: BasePart = toolModel and toolModel:WaitForChild("Handle") or nil;
	
	local animator: Animator = humanoid:WaitForChild("Animator");
	local animations = Equipped.Animations;
	for key, _ in pairs(toolLib.Animations) do
		local animationId = "rbxassetid://"..(toolLib.Animations[key].OverrideId or toolLib.Animations[key].Id);
		local animationFile = animationFiles[animationId] or Instance.new("Animation");
		animationFile.AnimationId = animationId;
		animationFile.Parent = humanoid;
		animationFiles[animationId] = animationFile;
		
		if animations[key] then animations[key]:Stop() end;
		animations[key] = animator:LoadAnimation(animationFile);
		animations[key].Name = (storageItem.ID)..":"..key;
		
		if key ~= "Core" and key ~= "SwimCore" then
			animations[key].Priority = Enum.AnimationPriority.Action2;
		end
	end;
	animations["Core"]:Play();
	
	if animations["Load"] then
		animations["Load"]:Play();
	end
	
	if toolLib.HideCrosshair ~= nil then
		characterProperties.HideCrosshair = toolLib.HideCrosshair;
	else
		characterProperties.HideCrosshair = true;
	end
	if toolLib.UseViewmodel == false then
		characterProperties.UseViewModel = false;
	end
	if toolLib.CustomViewModel then
		characterProperties.CustomViewModel = toolLib.CustomViewModel;
	end
	
	Equipped.RightHand.Unequip = function()
		if toolLib.DisableMovement then
			characterProperties.CanMove = true;
		end
		characterProperties.UseViewModel = true;
		characterProperties.CustomViewModel = nil;
		characterProperties.FieldOfView = nil;
		for key, _ in pairs(animations) do
			animations[key]:Stop();
		end
		
		modCharacter.EquippedTool = nil;
		characterProperties.Joints.WaistY = 0;
		if modData.ItemPromptConn then
			modData.ItemPromptConn:Disconnect();
		end
		
	end
	
	local function PrimaryFireRequest(isActive, ...)
		if not characterProperties.CanAction then return end;
		toolLib.IsActive = not toolLib.IsActive;
		
		if isActive then
			toolLib.IsActive = isActive;
		end
		
		--Debugger:Warn("animator", animator:GetPlayingAnimationTracks());
		if toolLib.IsActive then
			if animations.Use then animations.Use:Play(); end
			
			if toolLib.UseFOV then
				characterProperties.FieldOfView = toolLib.UseFOV;
			end
		else
			if animations.Use then animations.Use:Stop(); end
			characterProperties.FieldOfView = nil;
		end
		if toolLib.ClientPrimaryFire then
		--	remoteToolPrimaryFire:FireServer(storageItem.ID, toolConfig.IsActive, toolConfig:ClientPrimaryFire());
		--else
		--	remoteToolPrimaryFire:FireServer(storageItem.ID, toolConfig.IsActive, ...);
		end
	end
	
	local function SecondaryFireRequest()
		if not characterProperties.CanAction then return end;
		if toolLib.ClientSecondaryFire then
			toolLib:ClientSecondaryFire();
		end
	end
	
	function Equipped.OnToolRender(delta: number)
		if toolLib.OnClientToolRender then
			toolLib.OnClientToolRender(toolLib, Equipped, delta);
		end
	end
	
	function Equipped.ItemPromptRequest()
		if not characterProperties.CanAction then return end;
		if characterProperties.ActiveInteract ~= nil and characterProperties.ActiveInteract.CanInteract and characterProperties.ActiveInteract.Reachable then return end;
		if toolLib.ClientItemPrompt then
			toolLib:ClientItemPrompt();
		end
	end
	
	
	if toolLib.DisableMovement then
		characterProperties.CanMove = false;
	end
	
	toolLib.Player = localPlayer;
	toolLib.Prefab = toolModel;
	toolLib.Handle = handle;
	toolLib.StorageItem = storageItem;
	toolLib.PrimaryFireRequest = PrimaryFireRequest;
	toolLib.SecondaryFireRequest = SecondaryFireRequest;
	
	if storageItem.MockItem then
		toolLib.MockItem = true;
	end
	
	Equipped.RightHand["KeyFire"] = PrimaryFireRequest;
	Equipped.RightHand["KeyFocus"] = SecondaryFireRequest;
	Equipped.RightHand["KeyInteract"] = Equipped.ItemPromptRequest;
	
	Equipped.ModCharacter = modCharacter;
	Equipped.ToolConfig = toolLib;

	if Equipped.ToolConfig then
		if Equipped.ToolConfig.ClientEquip then
			Equipped.ToolConfig:ClientEquip();
		end
		
		if Equipped.ToolConfig.ClientItemPrompt then
			if UserInputService.KeyboardEnabled then
				local hintString = Equipped.ToolConfig.ItemPromptHint or (" to toggle "..toolLib.Name.." menu.")
				hintString = "Press ["..modKeyBindsHandler:ToString("KeyInteract").."]"..hintString;
				modInterface:HintWarning(hintString, nil, Color3.fromRGB(255, 255, 255));
			end
			
			if UserInputService.TouchEnabled then
				local itemPromptButton = modInterface.TouchControls:WaitForChild("ItemPrompt");
				local touchItemPrompt = itemPromptButton:WaitForChild("Item");

				touchItemPrompt.Image = itemLib.Icon;
				itemPromptButton.Visible = true;

				if modData.ItemPromptConn then modData.ItemPromptConn:Disconnect(); end
				modData.ItemPromptConn = itemPromptButton.MouseButton1Click:Connect(function()
					Equipped.ItemPromptRequest();
				end)
			end
		end
		
		function Equipped.ToolConfig:OnInputEvent(inputData)
			if inputData.KeyIds and inputData.KeyIds.KeyFocus then
				if inputData.InputType == "Begin" then
					modInterface:OpenWindow("EngineerPlannerWindow", self);
				end
			end

			if inputData.InputType ~= "Begin" then return end;
		end
	end
end

function ToolHandler:Unequip(storageItem)
	local itemPromptButton = modInterface.TouchControls:WaitForChild("ItemPrompt");
	itemPromptButton.Visible = false;

	--local modFlashlight = require(script.Parent.Parent:WaitForChild("Flashlight"));
	--modFlashlight:Destroy();
	
	modInterface:CloseWindow("EngineerPlannerWindow");
	modData.UpdateProgressionBar();
	characterProperties.HideCrosshair = false;
	
	if Equipped.ToolConfig then
		if Equipped.ToolConfig.ClientUnequip then
			Equipped.ToolConfig:ClientUnequip();
		end
		
		Equipped.ToolConfig.IsActive = false;
		Equipped.ToolConfig = nil;
	end
	for key, equipment in pairs(Equipped) do
		if typeof(equipment) == "table" and equipment.Item and equipment.Item.ID == storageItem.ID then
			if equipment.Unequip then equipment.Unequip(); end
			Equipped[key] = {Data={};};
		end;
	end
end

function ToolHandler:Initialize(equipped)
	if Equipped ~= nil then return end;
	Equipped = equipped;
	
	character = localPlayer.Character;
	humanoid = character:WaitForChild("Humanoid");
	modCharacter = require(character:WaitForChild("CharacterModule"));
	modInterface = modData:GetInterfaceModule();
	mouseProperties = modCharacter.MouseProperties;
	characterProperties = modCharacter.CharacterProperties;
end

return ToolHandler;