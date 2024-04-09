local ToolHandler = {}

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local character = script.Parent.Parent.Parent;
local humanoid = character:WaitForChild("Humanoid");
local animator: Animator = humanoid:WaitForChild("Animator");
local player = game.Players.LocalPlayer;

--== Modules;
local modData = require(player:WaitForChild("DataModule"));
local modCharacter = modData:GetModCharacter();
local modInterface = modData:GetInterfaceModule();

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modFlashlight = require(script.Parent.Parent:WaitForChild("Flashlight"));
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);

--== Remotes;
local remotes = game.ReplicatedStorage.Remotes;
local remoteToolPrimaryFire = modRemotesManager:Get("ToolHandlerPrimaryFire");

--== Vars;
local mouseProperties = modCharacter.MouseProperties;
local characterProperties = modCharacter.CharacterProperties;

local itemPromptButton = modInterface.TouchControls:WaitForChild("ItemPrompt");
local touchItemPrompt = itemPromptButton:WaitForChild("Item");

local Equipped;
local animationFiles = {};

--== Script;

function ToolHandler:Equip(storageItem, toolModels)
	local itemId = storageItem.ItemId;
	local toolLib = modTools[itemId];
	local toolConfig = toolLib.NewToolLib();
	local itemLib = modItemsLibrary:Find(itemId);
	
	local toolModel = Equipped.RightHand.Prefab;
	local handle = toolModel and toolModel:WaitForChild("Handle") or nil;
	
	local useTimer = tick();
	
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
	
	if toolConfig.HideCrosshair ~= nil then
		characterProperties.HideCrosshair = toolConfig.HideCrosshair;
	else
		characterProperties.HideCrosshair = true;
	end
	if toolConfig.UseViewmodel == false then
		characterProperties.UseViewModel = false;
	end
	if toolConfig.CustomViewModel then
		characterProperties.CustomViewModel = toolConfig.CustomViewModel;
	end
	
	Equipped.RightHand.Unequip = function()
		if toolConfig.DisableMovement then
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
		if toolConfig.UseCooldown and tick()-useTimer <= toolConfig.UseCooldown then return end;
		useTimer = tick();
		
		toolConfig.IsActive = not toolConfig.IsActive;
		
		if isActive then
			toolConfig.IsActive = isActive;
		end
		
		--Debugger:Warn("animator", animator:GetPlayingAnimationTracks());
		if toolConfig.IsActive then
			if animations.Use then animations.Use:Play(); end
			
			if toolConfig.UseFOV then
				characterProperties.FieldOfView = toolConfig.UseFOV;
			end
		else
			if animations.Use then animations.Use:Stop(); end
			characterProperties.FieldOfView = nil;
		end
		if toolConfig.ClientPrimaryFire then
			remoteToolPrimaryFire:FireServer(storageItem.ID, toolConfig.IsActive, toolConfig:ClientPrimaryFire());
		else
			remoteToolPrimaryFire:FireServer(storageItem.ID, toolConfig.IsActive, ...);
		end
	end
	
	local function SecondaryFireRequest()
		if not characterProperties.CanAction then return end;
		if toolConfig.ClientSecondaryFire then
			toolConfig:ClientSecondaryFire();
		end
	end
	
	function Equipped.OnToolRender(delta: number)
		if toolConfig.OnClientToolRender then
			toolConfig.OnClientToolRender(toolConfig, Equipped, delta);
		end
	end
	
	function Equipped.ItemPromptRequest()
		if not characterProperties.CanAction then return end;
		if characterProperties.ActiveInteract ~= nil and characterProperties.ActiveInteract.CanInteract and characterProperties.ActiveInteract.Reachable then return end;
		if toolConfig.ClientItemPrompt then
			toolConfig:ClientItemPrompt();
		end
	end
	
	
	if toolConfig.DisableMovement then
		characterProperties.CanMove = false;
	end
	
	toolConfig.Player = player;
	toolConfig.Prefab = toolModel;
	toolConfig.Handle = handle;
	toolConfig.StorageItem = storageItem;
	toolConfig.PrimaryFireRequest = PrimaryFireRequest;
	toolConfig.SecondaryFireRequest = SecondaryFireRequest;
	
	if storageItem.MockItem then
		toolConfig.MockItem = true;
	end
	
	Equipped.RightHand["KeyFire"] = PrimaryFireRequest;
	Equipped.RightHand["KeyFocus"] = SecondaryFireRequest;
	Equipped.RightHand["KeyInteract"] = Equipped.ItemPromptRequest;
	
	Equipped.ModCharacter = modCharacter;
	Equipped.ToolConfig = toolConfig;
	
	if Equipped.ToolConfig then
		if Equipped.ToolConfig.ClientEquip then
			Equipped.ToolConfig:ClientEquip();
		end
		
		if Equipped.ToolConfig.ClientItemPrompt then
			if UserInputService.KeyboardEnabled then
				local hintString = Equipped.ToolConfig.ItemPromptHint or (" to toggle "..itemLib.Name.." menu.")
				hintString = "Press ["..modKeyBindsHandler:ToString("KeyInteract").."]"..hintString;
				modInterface:HintWarning(hintString, nil, Color3.fromRGB(255, 255, 255));
			end
			
			if UserInputService.TouchEnabled then
				touchItemPrompt.Image = itemLib.Icon;
				itemPromptButton.Visible = true;

				if modData.ItemPromptConn then modData.ItemPromptConn:Disconnect(); end
				modData.ItemPromptConn = itemPromptButton.MouseButton1Click:Connect(function()
					Equipped.ItemPromptRequest();
				end)
			end
		end
	end
end

function ToolHandler:Unequip(storageItem)
	itemPromptButton.Visible = false;
	
	modFlashlight:Destroy();
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
end

return ToolHandler;
