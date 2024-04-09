local ToolHandler = {}

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local character = script.Parent.Parent.Parent;
local humanoid = character:WaitForChild("Humanoid");
local animator = humanoid:WaitForChild("Animator");
local player = game.Players.LocalPlayer;

--== Modules;
local modData = require(player:WaitForChild("DataModule"));
local modCharacter = modData:GetModCharacter();
local modInterface = modData:GetInterfaceModule();

local modFlashlight = require(script.Parent.Parent:WaitForChild("Flashlight"));

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

--== Remotes;
local remotes = game.ReplicatedStorage.Remotes;
local remotePrimaryFire = modRemotesManager:Get("ToolHandlerPrimaryFire");

--== Vars;
local mouseProperties = modCharacter.MouseProperties;
local characterProperties = modCharacter.CharacterProperties;

local Equipped;
local animationFiles = {};

local colorPlaceable, colorInvalid = Color3.fromRGB(131, 255, 135), Color3.fromRGB(255, 90, 93);
--== Script;

function ToolHandler:Equip(storageItem, toolModels)
	local prefabsItems = game.ReplicatedStorage.Prefabs.Items;
	
	modData.UpdateProgressionBar(0, "Building");
	
	local itemId = storageItem.ItemId;
	local toolLib = modTools[itemId];
	local configurations = toolLib.NewToolLib();
	
	local prefab = typeof(configurations.Prefab) == "string" and prefabsItems[configurations.Prefab] or configurations.Prefab;
	local prefabSize = prefab:GetExtentsSize();
	local placementHighlight, highlightDescendants;
	local isPlaceable = false;
	
	local function setHighlightColor(color)
		if highlightDescendants == nil then return end;
		for _, obj in pairs(highlightDescendants) do
			if obj:IsA("BasePart") and obj.Transparency ~= 1 then
				if obj.ClassName == "MeshPart" then
					obj.TextureID = "";
				end
				local surfApp = obj:FindFirstChildWhichIsA("SurfaceAppearance");
				if surfApp then
					surfApp:Destroy();
				end
				obj.Transparency = (obj.Name == "Hitbox" or obj.Name == "Collider") and 1 or 0.5;
				obj.Color = color;
			end
		end
	end
	
	local function createHighlight()
		placementHighlight = prefab:Clone();
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
		setHighlightColor(colorPlaceable);
	end
	
	local startTick, progressBarTick;
	
	local function updateProgressionBar(p)
		p = p or 0;
		if progressBarTick == nil or tick()-progressBarTick > 0.1 then
			progressBarTick = tick();
			modData.UpdateProgressionBar(p, "Building");
		end
	end
	
	local function reset()
		startTick = nil;
		progressBarTick = nil;
		updateProgressionBar();
	end
	
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
	characterProperties.HideCrosshair = true;
	if configurations.UseViewmodel == false then
		characterProperties.UseViewModel = false;
	end
	
	Equipped.RightHand.Unequip = function()
		if placementHighlight then placementHighlight:Destroy(); placementHighlight = nil; end;
		highlightDescendants = nil;
		for key, _ in pairs(animations) do
			animations[key]:Stop();
		end
		modCharacter.EquippedTool = nil;
		characterProperties.UseViewModel = true;
		characterProperties.Joints.WaistY = 0;
	end
	
	RunService:BindToRenderStep("BuildTool", Enum.RenderPriority.Character.Value, function()
		local rootPart = humanoid.RootPart;
		if placementHighlight == nil then createHighlight(); end
		
		if rootPart and placementHighlight and placementHighlight.PrimaryPart then
			local origin = rootPart.CFrame.p + rootPart.CFrame.LookVector*2.5;
			local ray = Ray.new(origin, Vector3.new(0, -8, 0));
			local hit, pos = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment; workspace.Terrain;});
			
			local placeCFrame = CFrame.new(pos) * rootPart.CFrame.Rotation * configurations.PlaceOffset;
			placementHighlight:PivotTo(placeCFrame);
			placementHighlight.Parent = workspace.CurrentCamera;
			
			local includeList = CollectionService:GetTagged("EngineersPlans");
			table.insert(includeList, workspace.Interactables);

			if configurations.BuildAvoidTags then
				for _, tag in pairs(configurations.BuildAvoidTags) do
					local taggedList = CollectionService:GetTagged(tag);
					for a=1, #taggedList do
						table.insert(includeList, taggedList[a]);
					end
				end
			end

			local overlapParams = OverlapParams.new();
			overlapParams.FilterType = Enum.RaycastFilterType.Include;
			overlapParams.FilterDescendantsInstances = includeList;
			overlapParams.MaxParts = 1;
			
			local placeSpacing = configurations.PlaceSpacing or Vector3.new(0.2, 4, 0.2);
			local hits = workspace:GetPartBoundsInBox(placeCFrame, prefabSize + placeSpacing, overlapParams)
			--local hits = workspace:FindPartsInRegion3WithWhiteList(region, {workspace.Interactables}, 1);
			
			if (#hits > 0 or not hit) and isPlaceable then
				isPlaceable = false;
				setHighlightColor(colorInvalid);
			elseif #hits == 0 and hit and not isPlaceable then
				isPlaceable = true;
				setHighlightColor(colorPlaceable);
			end
		end
		
		if mouseProperties.Mouse1Down and characterProperties.CanAction and isPlaceable then
			if not animations["Placing"].IsPlaying then
				animations["Placing"]:Play();
				animations["Placing"]:AdjustSpeed(animations["Placing"].Length/configurations.BuildDuration);
			end
			
			if startTick == nil then
				startTick = tick();
				remotePrimaryFire:FireServer(storageItem.ID, 1);
			else
				local progress = (tick()-startTick)/configurations.BuildDuration;
				updateProgressionBar(progress);
				if progress >= 1 then
					mouseProperties.Mouse1Down = false;
					reset();
					remotePrimaryFire:FireServer(storageItem.ID, 2);
					
					storageItem = modData.GetItemById(storageItem.ID);
					if storageItem == nil or storageItem.Quantity <= 1 then
						ToolHandler:Unequip(storageItem);
					end
				end
			end
			characterProperties.Joints.WaistY = 0;
		else
			characterProperties.Joints.WaistY = configurations.WaistRotation;
			animations["Placing"]:Stop();
			reset();
		end
	end);
end

function ToolHandler:Unequip(storageItem)
	RunService:UnbindFromRenderStep("BuildTool");
	RunService.RenderStepped:Wait();
	modFlashlight:Destroy();
	modData.UpdateProgressionBar();
	characterProperties.HideCrosshair = false;
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