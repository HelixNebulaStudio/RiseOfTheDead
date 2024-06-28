local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local interactionRange = 15;
local interactRadialConfig = '{"version":1,"size":128,"count":256,"columns":8,"rows":8,"images":["rbxassetid://4744240077", "rbxassetid://4744242814", "rbxassetid://4744244749", "rbxassetid://4744244960"]}';

-- Variables;
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modEmotes = require(game.ReplicatedStorage.Library.EmotesLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local modRadialImage = require(game.ReplicatedStorage.Library.UI.RadialImage);

local camera = workspace.CurrentCamera;

local character = script.Parent;
local humanoid = script.Parent:WaitForChild("Humanoid");
local rootPart = character:WaitForChild("HumanoidRootPart");
local animator = humanoid:WaitForChild("Animator");

for a=0, 10 do
	if workspace:IsAncestorOf(animator) then
		break;
	else
		task.wait();
	end
end
if not workspace:IsAncestorOf(animator) then return end;

local modCharacter = modData:GetModCharacter();
local characterProperties = modCharacter.CharacterProperties;

local UserInputService = game:GetService("UserInputService");
local mouseEnabled = UserInputService.MouseEnabled;
local touchEnabled = UserInputService.TouchEnabled;
local keyboardEnabled = UserInputService.KeyboardEnabled;
local mousePosition = UserInputService:GetMouseLocation();

local modInteractable = require(game.ReplicatedStorage.Library.Interactables);
local interactablesFolder = workspace.Interactables;
local interactableObjects = interactablesFolder:GetChildren();


local remoteInteractionUpdate = modRemotesManager:Get("InteractionUpdate");

local hideIndicator = false;
local cooldownInteract = tick();
local cooldownDistanceCheck = tick();
local holdDuration = nil;
local oldIndicatorPosition = nil;
local ActivateInteract;

local interactAnimTracks = {};

local matchActive = false;
local matchExist = false;

local interactableAnimations = script:WaitForChild("Animations");
-- Script;
for a=1, #interactableObjects do if interactableObjects[a]:IsA("BasePart") then interactableObjects[a].Transparency = 1; interactableObjects[a].Locked = true; end; end;

-- !outline: function clearInteractAnimations()
local function clearInteractAnimations()
	for a=1, #interactAnimTracks do
		interactAnimTracks[a]:Stop();
		interactAnimTracks[a] = nil;
	end
end

local modInterface = modData:GetInterfaceModule();
modInterface.InteractScriptLoaded = nil;


-- !outline: function loadInterface()
local mainInterfaceUI, interactIndicator, touchButton, interactProcess, interactRadial;
local function loadInterface()
	local modInterface = modData:GetInterfaceModule();
	
	if modInterface.InteractScriptLoaded then return end;
	modInterface.InteractScriptLoaded = true;
	
	mainInterfaceUI = modInterface.MainInterface;
	interactIndicator = mainInterfaceUI:WaitForChild("InteractIndicator");
	touchButton = interactIndicator:WaitForChild("TouchButton");
	interactProcess = interactIndicator:WaitForChild("processBar");

	interactRadial = modRadialImage.new(interactRadialConfig, interactProcess);
	interactProcess.ImageColor3 = modBranchConfigs.CurrentBranch.Color;

	if not keyboardEnabled or touchEnabled then
		touchButton.Visible = true;
		touchButton.Active = true;

		touchButton.InputBegan:Connect(function(input, gameProcessed)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				characterProperties.InteractionActive = true;
			end
		end)
		touchButton.InputEnded:Connect(function(input, gameProcessed)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				characterProperties.InteractionActive = false;

				clearInteractAnimations();
			end
		end)

	end
end
--loadInterface();


-- !outline: function CheckEnabled()
local function CheckEnabled(required)
	if required and type(required) == "table" then
		if required.Type == modInteractable.Types.Dialogue and modConfigurations.DisableDialogue then
			return;
		end
	else
		if type(required) ~= "table" then
			Debugger:Warn("Invalid interactable module returns.");
		end
	end
	return required;
end


local raycastParams = RaycastParams.new();
raycastParams.FilterType = Enum.RaycastFilterType.Include;
raycastParams.IgnoreWater = true;
raycastParams.CollisionGroup = "Raycast";


-- !outline: function canInteract()
local function canInteract()
	local v = characterProperties.CanInteract;

	local modInterface = modData:GetInterfaceModule();
	if modInterface and modInterface.CanInteract == false then
		v = false;
	end
	
	return v;
end

local heartbeatSkip = tick();
local autoTriggerDelay = tick();
local maxDist = 32;
-- !outline: signal RunService.Heartbeat
RunService.Heartbeat:Connect(function(delta)
	loadInterface();
	
	local beatTick = tick();

	if heartbeatSkip > beatTick then return end;
	if Debugger.ClientFps <= 30 then
		heartbeatSkip = beatTick+delta;
	elseif Debugger.ClientFps <= 15 then
		heartbeatSkip = beatTick+(delta*2);
	end

	mousePosition = UserInputService:GetMouseLocation();
	
	if not hideIndicator and canInteract() and characterProperties.IsAlive then
		local pointRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y);
		if not mouseEnabled and touchEnabled then
			pointRay = camera:ViewportPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2);
		end
		
		local rayWhitelist = {workspace.Environment; workspace.Entity; workspace.Terrain; workspace:FindFirstChild("Characters")};
		if characterProperties.RayIgnoreInteractables ~= true then
			table.insert(rayWhitelist, workspace.Interactables);
		end
		
		raycastParams.FilterDescendantsInstances = rayWhitelist;
		local raycastResult = workspace:Raycast(pointRay.Origin, pointRay.Direction*maxDist, raycastParams)
		local rayHit, rayPoint, rayNormal, distance;
		
		if raycastResult then
			rayHit, rayPoint, rayNormal = raycastResult.Instance, raycastResult.Position, raycastResult.Normal;
			distance = localPlayer:DistanceFromCharacter(rayPoint);
		else
			rayPoint = pointRay.Origin + pointRay.Direction*maxDist;
			distance = math.huge;
		end
		
		if rayHit then
			characterProperties.InteractRayHit = rayHit;
			characterProperties.InteractAimPoint = rayPoint;
			characterProperties.InteractAimNormal = Vector3.new(
				math.clamp(rayNormal.X, -1, 1),
				math.clamp(rayNormal.Y, -1, 1),
				math.clamp(rayNormal.Z, -1, 1)
			);
		else
			characterProperties.InteractRayHit = nil;
			characterProperties.InteractAimPoint = pointRay.Origin;
			characterProperties.InteractAimNormal = nil;
		end
		characterProperties.InteractAimOrigin = pointRay.Origin;
		characterProperties.InteractAimDirection = pointRay.Direction;
		characterProperties.InteractDistance = distance;
		
		if rayHit ~= nil then
			local interactableModule;
			local skipUpdate = false;
			
			local function loadInteractable(interactData)
				local newInteraction = CheckEnabled(interactData);
				
				if interactableModule and interactableModule:GetAttribute("Disabled") == true then
					newInteraction = nil;
				end
				
				if characterProperties.ActiveInteract and characterProperties.ActiveInteract.CaptureHold and characterProperties.InteractionActive then
					skipUpdate = true;
					return;
				end
				
				if newInteraction then
					if characterProperties.ActiveInteract == nil or newInteraction.ID ~= characterProperties.ActiveInteract.ID then
						holdDuration = nil;
						characterProperties.InteractAlpha = 0;
						
						local dataMeta = getmetatable(newInteraction);
						dataMeta.CharacterModule = modCharacter;
						dataMeta.Humanoid = modCharacter.Humanoid;
						dataMeta.RootPart = modCharacter.RootPart;
						
						newInteraction.Script = interactableModule;
						newInteraction:SyncRequest();
						
						characterProperties.ActiveInteract = newInteraction;
						characterProperties.ActiveInteract.Object = rayHit;
						
						local screenPoint, _inFront = camera:WorldToViewportPoint(rayHit.Position);
						oldIndicatorPosition = Vector2.new(screenPoint.X, screenPoint.Y);
						
						if interactableModule and interactableModule.Parent ~= rayHit and interactableModule.Parent ~= nil then
							if characterProperties.ActiveInteract then
								if interactableModule.Parent:FindFirstChildWhichIsA("Humanoid") then
									
									characterProperties.ActiveInteract.Object = interactableModule.Parent:FindFirstChild("UpperTorso");

									if characterProperties.ActiveInteract.Object == nil then
										characterProperties.ActiveInteract.Object = rayHit.Parent.PrimaryPart;
									end
									if characterProperties.ActiveInteract.Object == nil then
										characterProperties.ActiveInteract.Object = rayHit; 
									end
									
								elseif rayHit.Parent:IsA("Model") and rayHit.Parent.PrimaryPart then
									characterProperties.ActiveInteract.Object = rayHit.Parent.PrimaryPart;
									
								else
									characterProperties.ActiveInteract.Object = rayHit;
									
								end
							end
						end
					end
				else
					characterProperties.ActiveInteract = nil;
				end
			end
			
			if skipUpdate == true then
				
			elseif characterProperties.ProxyInteractable then
				rayHit = characterProperties.ProxyInteractable.Object;
				loadInteractable(characterProperties.ProxyInteractable);
				
			else
				local found = false;
				if rayHit:FindFirstChild("Interactable") then
					interactableModule = rayHit.Interactable;
					
					loadInteractable(require(interactableModule));
					found = true;
					
				else
					if rayHit.Parent:FindFirstChild("Interactable") and rayHit.Parent.Interactable:IsA("ModuleScript") then
						interactableModule = rayHit.Parent.Interactable;
						
					elseif rayHit.Parent:GetAttribute("InteractableParent") then
						local model = rayHit.Parent;
						while model:GetAttribute("InteractableParent") do model = model.Parent; end
						
						if model.PrimaryPart and model:FindFirstChild("Interactable") and model.Interactable:IsA("ModuleScript") then
							interactableModule = model.Interactable;
							rayHit = model.PrimaryPart;
						end
						
					elseif rayHit.Parent:IsA("Accessory") and rayHit.Parent.Parent:FindFirstChild("Interactable") and rayHit.Parent.Parent.Interactable:IsA("ModuleScript") then
						interactableModule = rayHit.Parent.Parent.Interactable;
					end
					
					if interactableModule then
						loadInteractable(require(interactableModule));
						found = true;
					end
				end
				if not found and characterProperties.ActiveInteract ~= nil then
					if characterProperties.ActiveInteract.CanInteract == false 
						or characterProperties.ActiveInteract.Disabled 
						or characterProperties.ActiveInteract.IndicatorPresist ~= true then
						
						local clearInteract = true;
						if characterProperties.ActiveInteract.CaptureHold and characterProperties.InteractionActive then
							clearInteract = false;
						end
						
						if clearInteract then
							characterProperties.ActiveInteract = nil;
						end
					end
				end
			end
		end
		
		if characterProperties.ActiveInteract ~= nil and characterProperties.ActiveInteract.Object then
			local activeObj = characterProperties.ActiveInteract.Object;
			if characterProperties.ActiveInteract.ProxyObject then
				activeObj = characterProperties.ActiveInteract.ProxyObject;
			end

			local indicatorPos;
			if activeObj:IsA("PVInstance") then
				indicatorPos = activeObj:GetPivot().Position;
			elseif activeObj:IsA("Attachment") then
				indicatorPos = activeObj.WorldPosition;
			end
			if characterProperties.ActiveInteract.ProxyOffset then
				indicatorPos = indicatorPos +characterProperties.ActiveInteract.ProxyOffset;
			end
			
			if characterProperties.ActiveInteract.Distance == nil or (beatTick - cooldownDistanceCheck) > 0.1 then
				cooldownDistanceCheck = tick();
				characterProperties.ActiveInteract.Distance = localPlayer:DistanceFromCharacter(indicatorPos);
				characterProperties.ActiveInteract.Reachable = characterProperties.ActiveInteract.Distance <= (characterProperties.ActiveInteract.InteractableRange or interactionRange);
			end
			
			if characterProperties.ActiveInteract.Reachable then
				local screenPoint, inFront = camera:WorldToViewportPoint(indicatorPos);
				if inFront and characterProperties.ActiveInteract.ShowIndicator ~= false then
					
					if tick()-autoTriggerDelay >= 5 then
						characterProperties.ActiveInteract:Trigger();
					end
					if characterProperties.ActiveInteract == nil then return end;
					
					if characterProperties.ActiveInteract.Disabled == nil then
						local prefix = "";
						
						if characterProperties.ActiveInteract.CanInteract and characterProperties.ActiveInteract.InteractDuration then
							prefix = "[Hold] "
						end 
						
						if characterProperties.ActiveInteract.Type == "Hold" then
							interactIndicator.label.Text = "[Hold] "..(characterProperties.ActiveInteract.Label or "Interact");
						else
							interactIndicator.label.Text = prefix..(characterProperties.ActiveInteract.Label or "Interact");
						end
					end
					
					if characterProperties.ActiveInteract.Disabled then
						interactIndicator.button.Text = "";
						interactIndicator.Size = UDim2.new(0, 10, 0, 10);
						interactIndicator.label.Text = characterProperties.ActiveInteract.Disabled;
						
					elseif characterProperties.ActiveInteract.CanInteract == false then
						interactIndicator.button.Text = "";
						interactIndicator.Size = UDim2.new(0, 10, 0, 10);
					else
						interactIndicator.Size = UDim2.new(0, 50, 0, 50);
						if modCharacter.CharacterProperties.ControllerEnabled then
							interactIndicator.button.Text = "X";
							
						elseif keyboardEnabled then
							local keyString = tostring(modData.Settings["KeyInteract"] or "E");
							if #keyString >= 5 then
								keyString = string.gsub(keyString, "[^A-Z,0-9]", "")
							end
							interactIndicator.button.Text = keyString;
							
						elseif touchEnabled then
							interactIndicator.button.Text = "Tap";
							interactIndicator.Size = UDim2.new(0, 100, 0, 50);
							
						elseif mouseEnabled then
							interactIndicator.button.Text = "Click";
							interactIndicator.Size = UDim2.new(0, 100, 0, 50);
							
						end
					end
					
					
					if not touchEnabled or interactProcess.Visible == false then
						if oldIndicatorPosition == nil then oldIndicatorPosition = Vector2.new(screenPoint.X, screenPoint.Y); end;
						local lerpVecPos = Vector2.new(screenPoint.X, screenPoint.Y);
						if Debugger.ClientFps > 30 then
							lerpVecPos = oldIndicatorPosition:Lerp(Vector2.new(screenPoint.X, screenPoint.Y), 0.5);
						end
						oldIndicatorPosition = lerpVecPos;

						interactIndicator.Position = UDim2.new(0, lerpVecPos.X, 0, lerpVecPos.Y);
					end
					
					interactIndicator.Visible = true;
				else
					interactIndicator.Visible = false;
				end
			else
				interactIndicator.Visible = false;
				characterProperties.ClearInteractHold();
				if matchExist then
					matchExist = false;
					matchActive = false;
					remoteInteractionUpdate:FireServer(nil, nil, "stop")
				end
			end
		else
			interactIndicator.Visible = false;
		end
	else
		interactIndicator.Visible = false;
	end
	
	if characterProperties.ActiveInteract == nil then
		characterProperties.ClearInteractHold();
		if matchExist then
			matchExist = false;
			matchActive = false;
			remoteInteractionUpdate:FireServer(nil, nil, "stop")
		end
	else
		matchExist = true;
	end
	
	if characterProperties.InteractionActive then
		ActivateInteract(delta);
		
	else
		interactProcess.Visible = false;
		holdDuration = nil;
		characterProperties.InteractAlpha = 0;
		characterProperties.CharacterInteracting = false;
		
		if matchActive ~= characterProperties.InteractionActive then
			matchActive = characterProperties.InteractionActive;
			remoteInteractionUpdate:FireServer(nil, nil, "stop")
		end
	end;
end)


-- !outline: function characterProperties.ClearInteractHold()
characterProperties.ClearInteractHold = function()
	holdDuration = nil;
	characterProperties.InteractAlpha = 0;
	characterProperties.InteractGyro = nil;
	clearInteractAnimations();
end;


-- !outline: function ActivateInteract()
function ActivateInteract(delta)
	local inputTick = tick();
	
	local interactObject = characterProperties.ActiveInteract;
	if interactObject and interactObject.Disabled then return end;
	if canInteract() and interactObject ~= nil and (interactObject.Distance or math.huge) <= (interactObject.InteractableRange or interactionRange) then
		local function interact()
			cooldownInteract = inputTick;
			
			if interactObject ~= nil then
				hideIndicator = true;
				if interactObject:Interact() then
					characterProperties.ActiveInteract = nil;
				end;
				hideIndicator = false;
			end
		end
		
		if interactObject.CanInteract then
			if matchActive ~= characterProperties.InteractionActive then
				matchActive = characterProperties.InteractionActive;
				remoteInteractionUpdate:FireServer(interactObject.Script, interactObject.Object, "start")
			end
			
			local animationId = interactObject.Animation;
			if animationId == nil then
				if interactObject.Type == "Trigger" then
					if interactObject.InteractDuration and interactObject.InteractDuration >= 1 then
						animationId = "InspectCrate";
					else
						animationId = "Press";
					end
					
				end
				
			end
			
			if animationId then
				--if modCharacter.CurrentAnimation ~= animationId then
				--	playEmote(animationId);
				--end
				
				if #interactAnimTracks <= 0 then
					local animLib = modEmotes:Find(animationId);
					if animLib then
						table.insert(interactAnimTracks, animator:LoadAnimation(animLib.Animation));
					end;
					
					local interactAnimation = interactableAnimations:FindFirstChild(animationId);
					if interactAnimation then
						local interactableAnimator = interactObject.Object.Parent:FindFirstChild("Animator", true);
						if interactableAnimator then
							table.insert(interactAnimTracks, interactableAnimator:LoadAnimation(interactAnimation));
						end
					end
				end
			end
			
			
			local interactPoint = interactObject.Object:FindFirstChild("InteractPoint");
			if interactObject.Object.Name == "UpperTorso" then
				local newInteractionPoint = interactObject.Object.Parent:FindFirstChild("InteractPoint", true);
				if newInteractionPoint then
					interactPoint = newInteractionPoint
				end
			end
			if interactPoint then
				humanoid:MoveTo(interactPoint.WorldPosition + Vector3.new(0, math.random(1, 10)/1000, 0));
			end
			
			if interactObject.Type == "Hold" then
				interactProcess.Visible = true;
				interactRadial:UpdateLabel(1);

				for a=1, #interactAnimTracks do
					interactAnimTracks[a].TimePosition = math.clamp(interactAnimTracks[a].TimePosition + delta, 0, interactAnimTracks[a].Length-0.01);
				end
				return;
			end	
			
			if interactObject.InteractDuration then
				if interactPoint then
					local dist = (interactPoint.WorldPosition-rootPart.Position).Magnitude;
					if dist > 3 then
						characterProperties.ClearInteractHold();
						interactRadial:UpdateLabel(0);
						characterProperties.CharacterInteracting = false;
						return;
					end
					
					characterProperties.InteractGyro = interactPoint.WorldCFrame;
				end
				
				if animationId and modCharacter.EquippedItem and modCharacter.EquippedItem.ID then
					if interactObject.ItemRequired ~= modCharacter.EquippedItem.ItemId then
						modData.HandleTool("unequip", {Id=modCharacter.EquippedItem.ID;});
					end
				end
				
				if holdDuration == nil then
					holdDuration = inputTick;
					if interactObject.OnStartInteract then
						interactObject:OnStartInteract();
					end
				end;
				
				interactProcess.Visible = true;
				characterProperties.CharacterInteracting = true;
				local alpha = math.clamp(((tick() - holdDuration) or 0)/interactObject.InteractDuration, 0, 20);
				
				characterProperties.InteractAlpha = alpha;
				
				if alpha >= 0.05 then
					for a=1, #interactAnimTracks do
						local track = interactAnimTracks[a];
						if track.Length > 0 then
							if not track.IsPlaying then
								track:Play(nil, nil, 0);
							end
							track.TimePosition = math.clamp(alpha * track.Length, 0, track.Length-0.01);
						end
					end
				end
				
				if alpha >= 1 then
					interactRadial:UpdateLabel(1);
					holdDuration = nil;
					characterProperties.InteractionActive = false;
					characterProperties.RefreshTransparency = true;
					characterProperties.InteractAlpha = 0;
					interact();
				else
					interactRadial:UpdateLabel(alpha);
				end
				
			elseif (inputTick - cooldownInteract) > 0.5 then
				interact();
				
			end
		end
	end
end

function modData.InteractRequest(interactableModule, object)
	if interactableModule == nil then return end;
	
	local newInteraction = CheckEnabled(require(interactableModule));
	if newInteraction then
		newInteraction.Script = interactableModule;
		newInteraction.Humanoid = modCharacter.Humanoid;
		newInteraction.RootPart = modCharacter.RootPart;
		newInteraction.CharacterModule = modCharacter;
		newInteraction:Trigger();
		newInteraction.Object = object;
		newInteraction.IndicatorPresist = false;
		newInteraction:Interact();
	end
end

-- !outline: signal UserInputService.InputBegan
UserInputService.InputBegan:connect(function(inputObject, inputEvent)
	if UserInputService:GetFocusedTextBox() ~= nil then return end;
	if modKeyBindsHandler:Match(inputObject, "KeyInteract") then
		characterProperties.InteractionActive = true;
	end
	
	if modBranchConfigs.CurrentBranch.Name == "Dev" then
		if characterProperties.ActiveInteract and script:GetAttribute("Debug") == true then
			Debugger:Log("ActiveInteract: ", characterProperties.ActiveInteract)
		end
	end
end)

-- !outline: signal UserInputService.InputEnded
UserInputService.InputEnded:Connect(function(inputObject, inputEvent)
	--if UserInputService:GetFocusedTextBox() ~= nil then return end;
	if modKeyBindsHandler:Match(inputObject, "KeyInteract") then
		characterProperties.InteractionActive = false;
		clearInteractAnimations();
		characterProperties.ActiveInteract = nil;
		
		if humanoid.RootPart then
			humanoid:MoveTo(humanoid.RootPart.Position);
		end
	end
end)

-- !outline: modData.TouchInteract(touchPart: BasePart)
function modData.TouchInteract(touchPart: BasePart)
	if canInteract() and characterProperties.IsAlive then
		if touchPart.Parent == nil then return end;
		local objectModel = touchPart.Parent:IsA("Model") and touchPart.Parent or nil;
		local modelPrimary = objectModel and objectModel.PrimaryPart or nil;
		local interactModule = objectModel and objectModel:FindFirstChild("Interactable");

		if modelPrimary and interactModule and interactModule:IsA("ModuleScript") then
			local interactData = CheckEnabled(require(interactModule));

			if interactData == nil or interactData.TouchInteract ~= true then return end;
			if interactData.TouchPickUp == false then return end;
			local dTouchInteractAttribute = interactModule:GetAttribute("DisableTouchInteract");
			if dTouchInteractAttribute and modSyncTime.GetTime() < dTouchInteractAttribute then return end;

			if interactData.Type == "Pickup" and interactData.ForceTouchPickup ~= true then
				if modData.Settings and modData.Settings.AutoPickupMode == 2 then
					return;

				elseif modData.Settings and modData.Settings.AutoPickupMode == 1 then
					local pickUpEnabled = modData.PickupCache[interactData.ItemId];

					if pickUpEnabled ~= true then
						return;
					end

				else
					if interactData.TouchPickUp == false then
						return;
					end

				end
			end

			interactData.Script = interactModule;
			interactData.Object = modelPrimary;
			interactData.Humanoid = modCharacter.Humanoid;
			interactData.RootPart = modCharacter.RootPart;
			interactData.CharacterModule = modCharacter;
			interactData.IndicatorPresist = false;
			interactData:Interact();

			characterProperties.ActiveInteract = nil;
		end
	end
end

-- !outline: signal humanoid.Touched
humanoid.Touched:Connect(modData.TouchInteract)

local overlapInteractParam = OverlapParams.new();
overlapInteractParam.FilterDescendantsInstances = {workspace.Interactables};
overlapInteractParam.FilterType = Enum.RaycastFilterType.Include;
overlapInteractParam.MaxParts = 25;


local function handleInteractable(basePart)
	local rootBase = basePart;

	local interactModule = rootBase:FindFirstChild("Interactable");
	while interactModule == nil do
		rootBase = rootBase.Parent;
		interactModule = rootBase:FindFirstChild("Interactable");

		if workspace.Interactables:IsAncestorOf(rootBase) == false then break; end
		if rootBase.Parent == workspace then break; end
		if interactModule then break; end;
	end

	if interactModule == nil or not interactModule:IsA("ModuleScript") then return end;

	local interactData = require(interactModule);
	if interactData == nil or interactData.Trigger == nil then return end;

	local dataMeta = getmetatable(interactData);
	dataMeta.CharacterModule = modCharacter;
	dataMeta.Humanoid = modCharacter.Humanoid;
	dataMeta.RootPart = modCharacter.RootPart;

	interactData.Script = interactModule;
	if rootBase:IsA("Model") then
		interactData.Object = rootBase.PrimaryPart;
	else
		interactData.Object = rootBase;
	end
	
	interactData:Trigger();
end

-- !outline: signal modSyncTime.GetClock().ValueChanged
modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
	if not canInteract() then return end;
	
	if characterProperties.ActiveInteract ~= nil and (characterProperties.ActiveInteract.Distance or math.huge) <= (characterProperties.ActiveInteract.InteractableRange or interactionRange) then
		characterProperties.ActiveInteract:Trigger();
	end

	local hitList = workspace:GetPartBoundsInRadius(camera.CFrame.Position, 64, overlapInteractParam);
		
	for a=1, #hitList do
		local object = hitList[a] :: BasePart;

		task.spawn(function()
			handleInteractable(object);
		end)
	end
end)