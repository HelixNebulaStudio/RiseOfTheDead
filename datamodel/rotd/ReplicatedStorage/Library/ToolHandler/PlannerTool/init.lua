local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local modToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modBlueprintLibrary = shared.require(game.ReplicatedStorage.Library.BlueprintLibraryRotd);
local modToolsLibrary = shared.require(game.ReplicatedStorage.Library.ToolsLibrary);
local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local plannerInterfacePackage = shared.require(game.ReplicatedStorage.Library.InterfacesRotd.PlannerInterface);
local PLANNER_LIBRARY = plannerInterfacePackage.PlannerLibrary;

local COLOR_PLACEABLE, COLOR_INVALID = Color3.fromRGB(131, 255, 135), Color3.fromRGB(255, 90, 93);

local toolHandler: ToolHandler = modToolHandler.new();
--==

function toolHandler.onRequire()
	remoteEngineersPlanner = modRemotesManager:Get("EngineersPlanner");
	remoteBlueprintHandler = modRemotesManager:Get("BlueprintHandler");

	if RunService:IsServer() then
		local plansFolder = Instance.new("Folder");
		plansFolder.Name = "EngineersPlans";
		plansFolder.Parent = game.ReplicatedStorage;


		function remoteEngineersPlanner.OnServerInvoke(player, storageItem, action, ...)
			local profile = shared.modProfile:Get(player);
			local inventory = profile.ActiveInventory;
			
			storageItem = inventory:Find(storageItem.ID);
			if storageItem == nil then Debugger:Warn("Missing storageItem"); return; end;
			
			local playerClass: PlayerClass = shared.modPlayers.get(player);

			local toolHandler: ToolHandlerInstance = playerClass.WieldComp:GetToolHandler(storageItem.ID, storageItem.ItemId);
			if toolHandler == nil then Debugger:Warn("Missing toolHandler"); return; end;
			
			local returnPacket = {};
			
			if action == "unlock" then
				local selectItemId = ...;
				
				Debugger:Warn("Unlock selectItemId", selectItemId);
				if PLANNER_LIBRARY[selectItemId] == nil then
					Debugger:Warn("Invalid selected item", selectItemId);
					returnPacket.FailMsg = `Invalid selected item {selectItemId}`;
					return returnPacket;
				end

				local bpLib = modBlueprintLibrary.Get(selectItemId.."bp");
				if bpLib == nil then 
					Debugger:Warn("No bp"); 
					returnPacket.FailMsg = `Blueprint {selectItemId} does not exist.`;
					return returnPacket; 
				end;

				local total, itemList = inventory:ListQuantity(bpLib.Id, 1);
				
				if total <= 0 then
					returnPacket.FailMsg = `You do not have any {bpLib.Name} blueprint.`;
					return returnPacket;
				end;
				
				for a=1, #itemList do
					inventory:Remove(itemList[a].ID, itemList[a].Quantity);
					shared.Notify(player, bpLib.Name.." removed from your Inventory.", "Negative");
				end
				
				local unlocked = storageItem.Values.Unlocked;
				if storageItem.Values.Unlocked == nil then
					unlocked = {};
				end
				unlocked[selectItemId] = true;
				

				local rechargeTime = bpLib.PlannerRechargeTime or 60;
				local charges = storageItem.Values.Charges;
				if storageItem.Values.Charges == nil then
					charges = {};
				end
				charges[selectItemId] = workspace:GetServerTimeNow()-rechargeTime;
				
				storageItem:SetValues("Unlocked", unlocked);
				storageItem:SetValues("Charges", charges);
				storageItem:Sync({"Unlocked"; "Charges"});
				
				returnPacket.Success = true;
				returnPacket.Values = storageItem.Values;
				
				return returnPacket;
				
				
			elseif action == "place" then
				local selectItemId = ...;
				Debugger:Warn("Place selectItemId", selectItemId);

				local unlocked = storageItem.Values.Unlocked;
				local isUnlocked = unlocked and unlocked[selectItemId];
				if isUnlocked ~= true then Debugger:Warn("Is not unlocked", selectItemId); return end;
				
				local itemLib = modItemsLibrary:Find(selectItemId);
				local bpLib = modBlueprintLibrary.Get(selectItemId.."bp");
				
				local placeableToolPackage = modToolsLibrary.get(selectItemId);
				local placeableConfig = placeableToolPackage.Configurations;

				local prefab = placeableToolPackage.Prefab;
				local prefabSize = prefab:GetExtentsSize();
				
				local placementHighlight;
				
				local function createHighlight()
					placementHighlight = prefab:Clone();
					placementHighlight.PrimaryPart.Anchored = true;
					
					for _, obj in pairs(placementHighlight:GetDescendants()) do
						if obj:IsA("Decal") or obj:IsA("Texture") then
							obj:Destroy();
						end
					end
					for _, obj in pairs(placementHighlight:GetDescendants()) do
						if obj:IsA("BasePart") and obj.Transparency ~= 1 then
							if obj.ClassName == "MeshPart" then
								obj.TextureID = "";
							end
							local surfApp = obj:FindFirstChildWhichIsA("SurfaceAppearance");
							if surfApp then
								surfApp:Destroy();
							end
							obj.Transparency = (obj.Name == "Hitbox" or obj.Name == "Collider") and 1 or 0.5;
							obj.Color = Color3.fromRGB(128, 183, 255);
							obj.CanCollide = false;
						end
					end
				end
				createHighlight();
				
				
				local rootPart = playerClass.RootPart;
				local origin = rootPart.CFrame.p + rootPart.CFrame.LookVector*2.5;
				local ray = Ray.new(origin, Vector3.new(0, -8, 0));
				local hit, pos = workspace:FindPartOnRayWithWhitelist(ray, {
					workspace.Environment; workspace.Terrain
				});

				if hit then
					local placeCFrame = CFrame.new(pos) * rootPart.CFrame.Rotation * placeableConfig.PlaceOffset;
					
					local includeList = CollectionService:GetTagged("EngineersPlans");
					table.insert(includeList, workspace.Interactables);

					if placeableConfig.BuildAvoidTags then
						for _, tag in pairs(placeableConfig.BuildAvoidTags) do
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

					local placeSpacing = placeableConfig.PlaceSpacing or Vector3.new(0.2, 4, 0.2);
					local hits = workspace:GetPartBoundsInBox(placeCFrame, prefabSize + placeSpacing, overlapParams)

					if #hits > 0 then
						shared.Notify(player, "Could not place "..itemLib.Name..", try again.", "Negative");
						return
					end;

					local plannerInfo = PLANNER_LIBRARY[selectItemId];
					local charges = storageItem.Values.Charges;
					
					local liveTime = workspace:GetServerTimeNow();
					local rechargeTime = bpLib.PlannerRechargeTime or 60;
					local maxChargeTime = liveTime-plannerInfo.MaxCharges*rechargeTime;
					local amtCharge = math.clamp(math.floor((liveTime-charges[selectItemId])/rechargeTime), 0, plannerInfo.MaxCharges);

					if amtCharge <= 0 then
						shared.Notify(player, "Not charges for "..itemLib.Name..".", "Negative");
						return
					end;
					
					amtCharge = amtCharge -1;

					charges[selectItemId] = liveTime - rechargeTime*amtCharge;
					storageItem:SetValues("Charges", charges);
					storageItem:Sync({"Charges"});

					returnPacket.Success = true;
					
					local newPlansRenderer = script:WaitForChild("PlansRenderer"):Clone();
					newPlansRenderer.Parent = placementHighlight;
					
					placementHighlight:PivotTo(placeCFrame);
					placementHighlight:SetAttribute("EngineersPlans", true);
					placementHighlight:SetAttribute("Owner", player.Name);
					placementHighlight:SetAttribute("ItemId", selectItemId);
					placementHighlight:AddTag("EngineersPlans")
					placementHighlight.Parent = plansFolder;
					
					newPlansRenderer.Enabled = true;
					
					
				else
					shared.Notify(player, "Could not place "..itemLib.Name..", try again.", "Negative");
				end
				
				
			elseif action == "remove" then
				
				local planModel = ...;
				Debugger:Warn("Remove planModel", planModel);

				if planModel:GetAttribute("EngineersPlans") == nil then
					return;
				end
				if planModel:GetAttribute("Debounce") then return end;
				planModel:SetAttribute("Debounce", true);
				
				local planItemId = planModel:GetAttribute("ItemId");
				
				planModel:Destroy();
				
				local plannerInfo = PLANNER_LIBRARY[planItemId];
				local charges = storageItem.Values.Charges;

				local liveTime = workspace:GetServerTimeNow();
				local rechargeTime = 60;
				local maxChargeTime = liveTime-plannerInfo.MaxCharges*rechargeTime;
				local amtCharge = math.clamp(math.floor((liveTime-charges[planItemId])/rechargeTime), 0, plannerInfo.MaxCharges);

				amtCharge = math.clamp(amtCharge +1, 0, plannerInfo.MaxCharges);

				charges[planItemId] = liveTime - rechargeTime*amtCharge;
				storageItem:SetValues("Charges", charges);
				storageItem:Sync({"Charges"});
			
			elseif action == "build" then
				local planModel = ...;
				Debugger:Warn("build planModel", planModel);

				local placeCFrame = planModel:GetPivot();
				local planItemId = planModel:GetAttribute("ItemId");
				
				if planModel:GetAttribute("EngineersPlans") == nil then
					return;
				end
				
				local bpItemId = planItemId.."bp";
				
				local fulfillment = modBlueprintLibrary.CheckBlueprintFulfilment(player, bpItemId);
				if fulfillment == nil then
					shared.Notify(player, "Insufficient resources.", "Negative");
					return;
				end
				for _, r in pairs(fulfillment) do
					if not r.Fulfilled then
						shared.Notify(player, "Insufficient resources.", "Negative");
						return;
					end;
				end;
				

				if planModel:GetAttribute("Debounce") then return end;
				planModel:SetAttribute("Debounce", true);
				planModel:Destroy();
				
				local placeableToolPackage = modToolsLibrary.get(planItemId);
				local placeableConfig = placeableToolPackage.Configurations;
				
				local prefab = placeableToolPackage.Prefab;
				local prefabSize = prefab:GetExtentsSize();
				
				local includeList = CollectionService:GetTagged("EngineersPlans");
				table.insert(includeList, workspace.Interactables);

				if placeableConfig.BuildAvoidTags then
					for _, tag in pairs(placeableConfig.BuildAvoidTags) do
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

				local placeSpacing = placeableConfig.PlaceSpacing or Vector3.new(0.2, 4, 0.2);
				local hits = workspace:GetPartBoundsInBox(placeCFrame, prefabSize + placeSpacing, overlapParams)

				if #hits > 0 then
					shared.Notify(player, "The space is already occupied.", "Negative");
					return
				end;
				
				modBlueprintLibrary.ConsumeBlueprintCost(player, fulfillment);
				
				local newPrefab = prefab:Clone();
				newPrefab.PrimaryPart.Anchored = true;
				newPrefab:PivotTo(placeCFrame);
				newPrefab.Parent = workspace.Environment;

				for _, obj in pairs(newPrefab:GetDescendants()) do
					if obj:IsA("BasePart") then
						obj.CollisionGroup = "Structure";
					end
				end

				if placeableToolPackage.BuildStructure then
					placeableToolPackage.BuildStructure(newPrefab, {
						CharacterClass = playerClass;
					});
				end
			end
			
			return returnPacket;
		end


		game.Players.PlayerRemoving:Connect(function()
			local playerNames = {};
			for _, player in pairs(game.Players:GetPlayers()) do
				table.insert(playerNames, player.Name);
			end
			for _, planModel in pairs(CollectionService:GetTagged("EngineersPlans")) do
				if table.find(playerNames, planModel:GetAttribute("Owner")) ~= nil then continue end;
				
				game.Debris:AddItem(planModel, 0);
			end
		end)
	end
end

function toolHandler.Init(handler: ToolHandlerInstance)
	local equipmentClass: EquipmentClass = handler.EquipmentClass;
	local configurations: ConfigVariable = equipmentClass.Configurations;
	local properties: PropertiesVariable<{}> = equipmentClass.Properties;
		
	properties.IsActive = false;

	handler:LoadWieldConfig();
end

if RunService:IsClient() then -- MARK: Client
	local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	function toolHandler.ClientEquip(handler: ToolHandlerInstance)
		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);

		local modCharacter = modData:GetModCharacter();
		
		local mouseProperties = modCharacter.MouseProperties;
		local characterProperties = modCharacter.CharacterProperties;

		local toolPackage = handler.ToolPackage;
		local toolAnimator: ToolAnimator = handler.ToolAnimator;

		local equipmentClass: EquipmentClass = handler.EquipmentClass;
		local configurations: ConfigVariable = equipmentClass.Configurations;
		local properties: PropertiesVariable<{}> = equipmentClass.Properties;


		local storageItem: StorageItem = handler.StorageItem;
		local itemId = storageItem.ItemId;
		local itemLib = modItemsLibrary:Find(itemId);

		local animations = toolPackage.Animations;

		toolAnimator:LoadAnimations(animations, toolPackage.DefaultAnimatorState, handler.Prefabs);
		toolAnimator:Play("Core");

		local mainToolModel = handler.MainToolModel;
		local mainHandle = mainToolModel.PrimaryPart;

		if toolPackage.ToolWindow then
			local quickButton = modClientGuis.ActiveInterface:NewQuickButton(itemLib.Name, nil, itemLib.Icon);
			quickButton.Name = toolPackage.ToolWindow;
			quickButton.LayoutOrder = 999;
			quickButton:WaitForChild("BkFrame").Visible = true;
			modClientGuis.ActiveInterface:ConnectQuickButton(quickButton, "KeyInteract");
			
			handler.Garbage:Tag(function()
				quickButton:Destroy();
				modClientGuis.toggleWindow(toolPackage.ToolWindow, false);
			end);
		end
		

		local plansFolder = game.ReplicatedStorage:WaitForChild("EngineersPlans");
		local function loadPlans()
			local plans: {Model} = CollectionService:GetTagged("EngineersPlans");
			for _, planModel: Model in pairs(plans) do
				if planModel:GetAttribute("Owner") ~= localPlayer.Name then continue end;
				
				planModel.Parent = workspace.Entities;
			end
		end
		handler.Garbage:Tag(plansFolder.ChildAdded:Connect(loadPlans));
		handler.Garbage:Tag(plansFolder.ChildRemoved:Connect(loadPlans));
		loadPlans();


		local placementHighlight, highlightDescendants, prefabSize;
		local placeableToolPackage;
		local isPlaceable = false;

		local activeItemId;

		properties.OnChanged:Connect(function(k, v)
			if k == "BuildSelectId" then
				activeItemId = v;
				
				placeableToolPackage = nil;
				if placementHighlight then
					placementHighlight:Destroy();
					placementHighlight = nil;
					highlightDescendants = nil;
				end

				Debugger:Warn(`Select {activeItemId}`);
			end
		end)

		local function setHighlightColor(color)
			if highlightDescendants == nil then return end;

			for _, obj in pairs(highlightDescendants) do
				if not obj:IsA("BasePart") or obj.Transparency == 1 then continue end;
				
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
			setHighlightColor(isPlaceable and COLOR_PLACEABLE or COLOR_INVALID);
		end
				
		local buildInteractProxy = modInteractables.Trigger(nil, "Build"); -- \nMetal 1000\nWood 1000\n$10000
		
		local placeDebounce = tick();
		local highlightPlan = false;
		local lastSelectedPlanModel = nil;
		RunService:BindToRenderStep(script.Name, Enum.RenderPriority.Character.Value, function()
			if not workspace:IsAncestorOf(mainHandle) or handler.EquipmentClass.Enabled == false then
				RunService:UnbindFromRenderStep(script.Name);
				return;
			end

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
			
			if hitPart and (hitPart.Position-mainHandle.Position).Magnitude <= 8 then
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
					
					if buildInteractProxy.LastCostCheck == nil 
					or tick() > buildInteractProxy.LastCostCheck 
					or lastSelectedPlanModel ~= planItemId then

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
									local itemLib = modItemsLibrary:Find(costInfo.ItemId);
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
					oPlanModel:SetAttribute("Color", oPlanModel == planModel and COLOR_INVALID or nil);
				end

				buildInteractProxy.CanInteract = true;
				buildInteractProxy.Part = planModel.PrimaryPart;
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

			if placeableToolPackage == nil then
				placeableToolPackage = modToolsLibrary.get(activeItemId);
			end

			local placeableConfig = placeableToolPackage.Configurations;

			local rootPart = playerClass.RootPart;
			if placementHighlight == nil then
				local prefab = placeableToolPackage.Prefab;
				createHighlight(prefab);
				prefabSize = prefab:GetExtentsSize();
			end
			
			if rootPart and placementHighlight and placementHighlight.PrimaryPart then
				local origin = rootPart.CFrame.p + rootPart.CFrame.LookVector*2.5;
				local ray = Ray.new(origin, Vector3.new(0, -8, 0));
				local hit, pos = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment; workspace.Terrain;});

				local placeCFrame = CFrame.new(pos) * rootPart.CFrame.Rotation * placeableConfig.PlaceOffset;
				placementHighlight:PivotTo(placeCFrame);
				placementHighlight.Parent = workspace.CurrentCamera;

				local includeList = CollectionService:GetTagged("EngineersPlans");
				table.insert(includeList, workspace.Interactables);

				if placeableConfig.BuildAvoidTags then
					for _, tag in pairs(placeableConfig.BuildAvoidTags) do
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

				local placeSpacing = placeableConfig.PlaceSpacing or Vector3.new(0.2, 4, 0.2);
				local hits = workspace:GetPartBoundsInBox(placeCFrame, prefabSize + placeSpacing, overlapParams);

				if (#hits > 0 or not hit) and isPlaceable then
					isPlaceable = false;
					setHighlightColor(COLOR_INVALID);
				elseif #hits == 0 and hit and not isPlaceable then
					isPlaceable = true;
					setHighlightColor(COLOR_PLACEABLE);
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

	function toolHandler.ClientUnequip(handler: ToolHandlerInstance)
		local equipmentClass: EquipmentClass = handler.EquipmentClass;
		local configurations: ConfigVariable = equipmentClass.Configurations;
		local properties: PropertiesVariable<{}> = equipmentClass.Properties;

		properties.IsActive = false;
		properties.BuildSelectId = nil;
	end


elseif RunService:IsServer() then -- MARK: Server



end

return toolHandler;