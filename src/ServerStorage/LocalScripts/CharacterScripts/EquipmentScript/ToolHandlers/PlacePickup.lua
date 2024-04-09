local ToolHandler = {}

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local character = script.Parent.Parent.Parent;
local humanoid = character:WaitForChild("Humanoid");
local animator = humanoid:WaitForChild("Animator");
local player = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local deg90 = math.pi/2;
local rotations = 0;
local tilt = 0;
--== Modules;
local modData = require(player:WaitForChild("DataModule"));
local modCharacter = modData:GetModCharacter();
local modInterface = modData:GetInterfaceModule();

local modFlashlight = require(script.Parent.Parent:WaitForChild("Flashlight"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);

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

local itemPromptConn;
--== Script;

function ToolHandler:Equip(storageItem, toolModels)
	local itemId = storageItem.ItemId;
	local toolLib = modTools[itemId];
	local toolConfig = toolLib.NewToolLib();
	local itemLib = modItemsLibrary:Find(itemId);
	
	local itemPrefabs = game.ReplicatedStorage.Prefabs.Items;
	
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
		
		--animations[key].Priority = toolLib.Animations[key].Priority or Enum.AnimationPriority.Movement;
		if key ~= "Core" then
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
	
	local function PrimaryFireRequest(isActive, ...)
		if not characterProperties.CanAction then return end;
		if toolConfig.UseCooldown and tick()-useTimer <= toolConfig.UseCooldown then return end;
		useTimer = tick();
		
		toolConfig.IsActive = not toolConfig.IsActive;
		
		if isActive then
			toolConfig.IsActive = isActive;
		end
		
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
	
	Equipped.RightHand["KeyFire"] = PrimaryFireRequest;
	Equipped.RightHand["KeyFocus"] = SecondaryFireRequest;
	Equipped.RightHand["KeyInteract"] = Equipped.ItemPromptRequest;
	
	Equipped.ToolConfig = toolConfig;
	
	if Equipped.ToolConfig then
		rotations = 0;
		tilt = 0;
		
		function Equipped.ToolConfig:OnInputEvent(inputData)
			if inputData.InputType ~= "Begin" then return end;
			
			if inputData.KeyCode == Enum.KeyCode.R then
				rotations = rotations +1;
			elseif inputData.KeyCode == Enum.KeyCode.T then
				tilt = tilt +1;
			end
		end
		
		
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

				if itemPromptConn then itemPromptConn:Disconnect(); end
				itemPromptConn = itemPromptButton.MouseButton1Click:Connect(function()
					Equipped.ItemPromptRequest();
				end)
			end
		end
	end
	
	local itemValues = storageItem.Values;
	local prefabId = itemValues.PickUpItemId;
	
	if prefabId == nil then return end;
	local placementPrefab = itemPrefabs:FindFirstChild(prefabId);
	if placementPrefab == nil then return end;

	local colorPlaceable, colorInvalid = Color3.fromRGB(131, 255, 135), Color3.fromRGB(255, 90, 93);
	local placementHighlight, highlightDescendants;
	
	local function setHighlightColor(color)
		if highlightDescendants == nil then return end;
		for _, obj in pairs(highlightDescendants) do
			if obj:IsA("BasePart") then
				if obj.ClassName == "MeshPart" then
					obj.TextureID = "";
				end
				local surfApp = obj:FindFirstChildWhichIsA("SurfaceAppearance");
				if surfApp then
					surfApp:Destroy();
				end
				obj.Anchored = true;
				obj.CanCollide = false;
				obj.Transparency = obj.Name == "Hitbox" and 1 or 0.5;
				obj.Color = color;
			end
		end
	end
	
	local function clearHighlight()
		characterProperties.ProxyInteractable = nil;
		
		if placementHighlight then
			placementHighlight:Destroy(); 
			placementHighlight = nil; 
		end;
	end
	local function createHighlight()
		placementHighlight = placementPrefab:Clone();
		
		delay(60, function()
			if placementHighlight then
				placementHighlight:Destroy();
				placementHighlight = nil;
			end
		end)
		placementHighlight.PrimaryPart.Anchored = true;
		
		for _, obj in pairs(placementHighlight:GetDescendants()) do
			if obj:IsA("Decal") or obj:IsA("Texture") then
				obj:Destroy();
			end
		end
		highlightDescendants = placementHighlight:GetDescendants();
		
		characterProperties.ProxyInteractable = modInteractables.PickUpPlaceable(nil, storageItem.ID);
		characterProperties.ProxyInteractable.Object = placementHighlight.PrimaryPart;
		
		setHighlightColor(colorPlaceable);
	end
	
	Equipped.RightHand.Unequip = function()
		if toolConfig.DisableMovement then
			characterProperties.CanMove = true;
		end
		characterProperties.UseViewModel = true;
		characterProperties.CustomViewModel = nil;
		characterProperties.FieldOfView = nil;
		characterProperties.RayIgnoreInteractables = false;
		clearHighlight();
		for key, _ in pairs(animations) do
			animations[key]:Stop();
		end
		modCharacter.EquippedTool = nil;
		characterProperties.Joints.WaistY = 0;
		if itemPromptConn then itemPromptConn:Disconnect(); end
	end
	
	RunService:BindToRenderStep(script.Name, Enum.RenderPriority.Character.Value, function()
		local targetRayHit = characterProperties.InteractRayHit;
		local targetPoint = characterProperties.InteractAimPoint;
		local targetNormal = characterProperties.InteractAimNormal;
		
		if targetPoint and humanoid.RootPart then
			local rootPartPosition = humanoid.RootPart.Position;
			
			if placementHighlight == nil then
				createHighlight();
				
				placementHighlight.Parent = camera;
			end
			
			if placementHighlight then
				local cframe = CFrame.new(targetPoint, targetPoint + targetNormal) * CFrame.Angles(0, deg90, 0) * CFrame.Angles(0, rotations*deg90, tilt*deg90);
				
				local camLookVector = camera.CFrame.LookVector;
				cframe = cframe * CFrame.Angles(0, math.atan2(camLookVector.X, camLookVector.Z) - deg90, 0);
				placementHighlight:SetPrimaryPartCFrame(cframe);
				
				local isPlaceable = true;
				if targetRayHit == nil or not targetRayHit.Anchored then
					isPlaceable = false;
				end;
				
				if (targetPoint-rootPartPosition).Magnitude >= 15 then
					isPlaceable = false;
				end
				
				local groundAngle = math.deg(math.acos(Vector3.new(0, 1, 0):Dot(targetNormal)));
				
				local placeLimits =  toolConfig.PlaceLimits or {};
				placeLimits.MinUpAngle = placeLimits.MinUpAngle or 0;
				placeLimits.MaxUpAngle = placeLimits.MaxUpAngle or 20;
				
				if groundAngle < placeLimits.MinUpAngle or groundAngle > placeLimits.MaxUpAngle then
					--isPlaceable = false;
				end
				
				if isPlaceable then
					characterProperties.ProxyInteractable.CanInteract = true;
					characterProperties.ProxyInteractable.Label = nil;
					
					setHighlightColor(colorPlaceable);
					
				else
					characterProperties.ProxyInteractable.CanInteract = false;
					characterProperties.ProxyInteractable.Label = "Can't Place Here";
					
					setHighlightColor(colorInvalid);
				end
			end
		else
			clearHighlight();
		end
	end);
end

function ToolHandler:Unequip(storageItem)
	RunService:UnbindFromRenderStep(script.Name);
	RunService.RenderStepped:Wait();
	
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