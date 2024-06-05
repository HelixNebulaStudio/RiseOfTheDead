local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

--== Modules;
local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

local modTools = require(game.ReplicatedStorage.Library.Tools);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);
local modBlueprintLibrary = require(game.ReplicatedStorage.Library.BlueprintLibrary);
local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);

--== Remotes;
local remoteEngineersPlanner = modRemotesManager:Get("EngineersPlanner");
local remoteBlueprintHandler = modRemotesManager:Get("BlueprintHandler");

--== Vars;
local ToolHandler = {};
local Equipped;

local colorPlaceable, colorInvalid = Color3.fromRGB(131, 255, 135), Color3.fromRGB(255, 90, 93);
--== Script;

function ToolHandler:Equip(storageItem, toolModels)
	local character = localPlayer.Character;
	local modInterface = modData:GetInterfaceModule();
	local modCharacter = modData:GetModCharacter();
	local mouseProperties = modCharacter.MouseProperties;
	local characterProperties = modCharacter.CharacterProperties;

	local humanoid: Humanoid = character:WaitForChild("Humanoid");
	local animator: Animator = humanoid:WaitForChild("Animator") :: Animator;

	local itemId = storageItem.ItemId;
	local itemLib = modItemsLibrary:Find(itemId);
	
	local toolLib = modTools[itemId];
	local toolConfig = toolLib.NewToolLib();
	
	local toolModel = Equipped.RightHand.Prefab;
	local handle = toolModel and toolModel:WaitForChild("Handle") or nil;

	local animationFiles = {};
	local useTimer = tick();
	--
	
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
		--	remoteToolPrimaryFire:FireServer(storageItem.ID, toolConfig.IsActive, toolConfig:ClientPrimaryFire());
		--else
		--	remoteToolPrimaryFire:FireServer(storageItem.ID, toolConfig.IsActive, ...);
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
	
	function toolConfig:ClientItemPrompt()
		modInterface:ToggleWindow("EngineerPlannerWindow", nil, toolConfig);
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
	
	toolConfig.Player = localPlayer;
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
		
		--function Equipped.ToolConfig:OnInputEvent(inputData)
		--	if inputData.KeyIds and inputData.KeyIds.KeyFocus then
		--		if inputData.InputType == "Begin" then
		--			modInterface:OpenWindow("EngineerPlannerWindow", toolConfig);
		--		end
		--	end

		--	if inputData.InputType ~= "Begin" then return end;
		--end
	end
	
	
	
	--==
	local plansFolder = game.ReplicatedStorage:WaitForChild("EngineersPlans");
	
	local unequipped = false;
	local function loadPlans()
		if unequipped then return end;
		local plans: {Model} = CollectionService:GetTagged("EngineersPlans");
		for _, planModel: Model in pairs(plans) do
			if planModel:GetAttribute("Owner") ~= localPlayer.Name then continue end;
			
			planModel.Parent = workspace.Entities;
		end
	end
	local planAddConn = plansFolder.ChildAdded:Connect(loadPlans);
	local planRemoveConn =plansFolder.ChildRemoved:Connect(loadPlans);
	loadPlans();
	
	
	local prefabsItems = game.ReplicatedStorage:WaitForChild("Prefabs"):WaitForChild("Items");
	local placementHighlight, highlightDescendants, prefabSize;
	local placableToolInfo, placableToolConfig;
	local isPlaceable = false;

	Equipped.RightHand.Unequip = function()
		local itemPromptButton = modInterface.TouchControls:WaitForChild("ItemPrompt");
		itemPromptButton.Visible = false;

		modInterface:CloseWindow("EngineerPlannerWindow");
		characterProperties.HideCrosshair = false;

		characterProperties.ProxyInteractable = nil;
		
		if placementHighlight then placementHighlight:Destroy(); placementHighlight = nil; end;
		highlightDescendants = nil;
		placableToolInfo, placableToolConfig = nil, nil;
		
		planAddConn:Disconnect();
		planRemoveConn:Disconnect();
		
		unequipped = true;
		local plans: {Model} = CollectionService:GetTagged("EngineersPlans");
		for _, planModel: Model in pairs(plans) do
			planModel.Parent = plansFolder;
		end
		
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
	
	local activeItemId;
	function toolConfig:Select(selectItemId)
		activeItemId = selectItemId;
		
		placableToolInfo = nil;
		placableToolConfig = nil;
		if placementHighlight then
			placementHighlight:Destroy();
			placementHighlight = nil;
			highlightDescendants = nil;
		end
	end
	
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
				obj.CanCollide = false;
				obj.Transparency = (obj.Name == "Hitbox" or obj.Name == "Collider") and 1 or 0.5;
				obj.Color = color;
			end
		end
	end

	local function createHighlight(prefab)
		placementHighlight = prefab:Clone();
		delay(120, function()
			if placementHighlight then
				placementHighlight:Destroy();
				placementHighlight = nil;
			end
		end)
		placementHighlight.PrimaryPart.Anchored = true;
		for _, obj in pairs(placementHighlight:GetDescendants()) do
			if obj:IsA("Decal") or obj:IsA("Texture") then
				obj:Destroy();
			elseif obj:IsA("BasePart") then
				obj.CanCollide = false;
			end
		end
		highlightDescendants = placementHighlight:GetDescendants();
		setHighlightColor(isPlaceable and colorPlaceable or colorInvalid);
	end
	
	local buildInteractProxy = modInteractables.Trigger(nil, "Build"); -- \nMetal 1000\nWood 1000\n$10000
	
	local placeDebounce = tick();
	local highlightPlan = false;
	local lastSelectedPlanModel = nil;
	RunService:BindToRenderStep(script.Name, Enum.RenderPriority.Character.Value, function()
		local mousePosition = UserInputService:GetMouseLocation();
		local pointRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y);
		if not UserInputService.MouseEnabled and UserInputService.TouchEnabled then
			pointRay = camera:ViewportPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2);
		end
		
		local planModels = CollectionService:GetTagged("EngineersPlans");

		local raycastParams = RaycastParams.new();
		raycastParams.FilterType = Enum.RaycastFilterType.Include;
		raycastParams.IgnoreWater = true;
		raycastParams.CollisionGroup = "Raycast";
		raycastParams.FilterDescendantsInstances = planModels;
		
		local raycastResult = workspace:Raycast(pointRay.Origin, pointRay.Direction*64, raycastParams);
		local hitPart = raycastResult and raycastResult.Instance;
		
		if hitPart and (hitPart.Position-handle.Position).Magnitude <= 8 then
			if placementHighlight then
				placementHighlight:Destroy();
				placementHighlight = nil;
			end
			
			local planModel = hitPart;
			
			repeat
				planModel = planModel.Parent;
				if planModel == nil or planModel == workspace.Debris or planModel == game.ReplicatedStorage or planModel == game then
					break;
				end
			until planModel:GetAttribute("EngineersPlans");
			
			if planModel == nil or planModel:GetAttribute("EngineersPlans") ~= true then return end;
			
			local planItemId = planModel:GetAttribute("ItemId");
			
			if highlightPlan == false then
				local bpLib = modBlueprintLibrary.Get(planItemId.."bp");
				
				local requireStrList = {};
				local requirements = bpLib.Requirements;
				
				if buildInteractProxy.LastCostCheck == nil or tick() > buildInteractProxy.LastCostCheck or lastSelectedPlanModel ~= planItemId then
					buildInteractProxy.LastCostCheck = tick()+5;
					lastSelectedPlanModel = planItemId;
					buildInteractProxy.Label = "Build\nLoading";
					local rPacket = remoteBlueprintHandler:InvokeServer("check", {ItemId=bpLib.Id;});

					if rPacket.Success then
						local fulfillment = rPacket.Fulfillment;
						for a=1, #requirements do
							local requires = fulfillment[a].Requires or 0;
							local amount = requirements[a].Amount or 1;
							
							local costInfo = requirements[a];
							local fulfilled = fulfillment[a].Fulfilled;
							
							if costInfo.Type == "Item" then
								local itemLib = modItemLibrary:Find(costInfo.ItemId);
								local costStr = ("$Requires/$Amount $Name"):gsub("$Requires", amount-requires)
									:gsub("$Amount", amount):gsub("$Name", itemLib.Name);
								

								table.insert(requireStrList, fulfilled
									and modRichFormatter.SuccessText(costStr)
									or modRichFormatter.FailText(costStr)
								);
								
							elseif costInfo.Type == "Stat" then
								if costInfo.Name == "Money" then
									table.insert(requireStrList, 9, fulfilled
										and modRichFormatter.SuccessText("$"..costInfo.Amount)
										or modRichFormatter.FailText("$"..costInfo.Amount)
									);
								else
									table.insert(requireStrList, fulfilled
										and modRichFormatter.SuccessText(costInfo.Name..":"..costInfo.Amount)
										or modRichFormatter.FailText(costInfo.Name..":"..costInfo.Amount)
									);
								end
								
							else
								table.insert(requireStrList, 99, fulfilled
									and modRichFormatter.SuccessText(costInfo.Name..":"..costInfo.Amount)
									or modRichFormatter.FailText(costInfo.Name..":"..costInfo.Amount)
								);
								
							end
						end
					end
					
					buildInteractProxy.Label = "Build\n"..table.concat(requireStrList, "\n");
				end
				
				
			end
			highlightPlan = true;
			
			for a=1, #planModels do
				local oPlanModel = planModels[a];
				oPlanModel:SetAttribute("Color", oPlanModel == planModel and colorInvalid or nil);
			end

			buildInteractProxy.CanInteract = true;
			buildInteractProxy.Object = planModel.PrimaryPart;
			buildInteractProxy.ProxyOffset = planModel:GetExtentsSize() * Vector3.new(0, 0.4, 0);
			characterProperties.ProxyInteractable = buildInteractProxy;
			
			function buildInteractProxy:OnInteracted(library)
				task.spawn(function()
					buildInteractProxy.CanInteract = false;
					local _returnPacket = remoteEngineersPlanner:InvokeServer(storageItem, "build", planModel);
					buildInteractProxy.CanInteract = true;
				end)
			end
			
			if mouseProperties.Mouse1Down and characterProperties.CanAction and tick()-placeDebounce > 0.2 then
				placeDebounce = tick();
				local _returnPacket = remoteEngineersPlanner:InvokeServer(storageItem, "remove", planModel);
			end
			return;
			
		elseif highlightPlan then
			characterProperties.ProxyInteractable = nil;
			highlightPlan = false;

			for a=1, #planModels do
				local oPlanModel = planModels[a];
				oPlanModel:SetAttribute("Color", nil);
			end
		end
		
		
		if activeItemId == nil then return end;

		if placableToolConfig == nil then
			placableToolInfo = modTools[activeItemId];
			placableToolConfig = placableToolInfo.NewToolLib();
		end
		
		local rootPart = humanoid.RootPart;
		if placementHighlight == nil then
			local prefab = typeof(placableToolConfig.Prefab) == "string" and prefabsItems[placableToolConfig.Prefab] or placableToolConfig.Prefab;
			createHighlight(prefab);
			prefabSize = prefab:GetExtentsSize();
		end
		
		if rootPart and placementHighlight and placementHighlight.PrimaryPart then
			local origin = rootPart.CFrame.p + rootPart.CFrame.LookVector*2.5;
			local ray = Ray.new(origin, Vector3.new(0, -8, 0));
			local hit, pos = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment; workspace.Terrain;});

			local placeCFrame = CFrame.new(pos) * rootPart.CFrame.Rotation * placableToolConfig.PlaceOffset;
			placementHighlight:PivotTo(placeCFrame);
			placementHighlight.Parent = workspace.CurrentCamera;

			local includeList = CollectionService:GetTagged("EngineersPlans");
			table.insert(includeList, workspace.Interactables);

			if placableToolConfig.BuildAvoidTags then
				for _, tag in pairs(placableToolConfig.BuildAvoidTags) do
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

			local placeSpacing = placableToolConfig.PlaceSpacing or Vector3.new(0.2, 4, 0.2);
			local hits = workspace:GetPartBoundsInBox(placeCFrame, prefabSize + placeSpacing, overlapParams);

			if (#hits > 0 or not hit) and isPlaceable then
				isPlaceable = false;
				setHighlightColor(colorInvalid);
			elseif #hits == 0 and hit and not isPlaceable then
				isPlaceable = true;
				setHighlightColor(colorPlaceable);
			end
		end
		
		if mouseProperties.Mouse1Down then
			Debugger:Warn("isPlaceable", isPlaceable);
		end
		if mouseProperties.Mouse1Down and characterProperties.CanAction and isPlaceable and tick()-placeDebounce > 0.2 then
			placeDebounce = tick();
			local _returnPacket = remoteEngineersPlanner:InvokeServer(storageItem, "place", activeItemId);
		end
	end)
end

function ToolHandler:Unequip(storageItem)
	RunService:UnbindFromRenderStep(script.Name);
	modData.UpdateProgressionBar();
	
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