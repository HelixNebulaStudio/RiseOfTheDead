--== Variables;
local localPlayer = game.Players.LocalPlayer;
local currentCamera = workspace.CurrentCamera;
local character = script.Parent;

local rootPart: BasePart = character:WaitForChild("HumanoidRootPart");
rootPart.Anchored = true;

localPlayer.PlayerScripts:ClearComputerCameraMovementModes();
localPlayer.PlayerScripts:ClearComputerMovementModes();

repeat task.wait() until #character:GetChildren() >= 17;

local humanoid = character:WaitForChild("Humanoid") :: Humanoid;
local head = character:WaitForChild("Head");
local upperTorso = character:WaitForChild("UpperTorso");
local animator = humanoid:WaitForChild("Animator");

local collisionRootPart = character:WaitForChild("CollisionRootPart");
collisionRootPart.Transparency = 1;
collisionRootPart.Name = "CollisionRootPart";
collisionRootPart.CollisionGroup = "Players";

local collisionRootMotor = rootPart:WaitForChild("CollisionRootPart");

collisionRootPart:GetPropertyChangedSignal("CanCollide"):Connect(function()
	collisionRootPart.CanCollide = true;
end)

rootPart.Anchored = false;

local walkSurfaceTag = Instance.new("StringValue"); walkSurfaceTag.Name = "WalkingSurface"; walkSurfaceTag.Parent = head;
local UserGameSettings = UserSettings():GetService("UserGameSettings");

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modSettings = localPlayer:FindFirstChild("SettingsModule") ~= nil and require(localPlayer.SettingsModule :: ModuleScript) or nil;
local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();

local modCameraGraphics = require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modLayeredVariable = require(game.ReplicatedStorage.Library.LayeredVariable);
local modSpectateManager = require(game.ReplicatedStorage.Library.SpectateManager);

local modRaycastUtil = require(game.ReplicatedStorage.Library.Util.RaycastUtil);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);
local modBuffer = require(game.ReplicatedStorage.Library.Util.Buffer);
Debugger.AwaitShared("modPlayers");

-- Flags;
modCharacter.DeadlockMovement = true;

local classPlayer = shared.modPlayers.Get(localPlayer);

local rootRigAttachment = rootPart:WaitForChild("RootRigAttachment");

local alignRotation = Instance.new("AlignOrientation");
alignRotation.Name = "BodyOrientation";
alignRotation.ReactionTorqueEnabled = true;
alignRotation.Enabled = false;
alignRotation.Mode = Enum.OrientationAlignmentMode.OneAttachment;
alignRotation.Attachment0 = rootRigAttachment;
alignRotation.Responsiveness = 100;
alignRotation.Parent = rootPart;

local animations = {};

local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local SoundService = game:GetService("SoundService");
local HapticService = game:GetService("HapticService")
local isVibrationSupported = HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1);

local characterProperties = modCharacter.CharacterProperties;
local mouseProperties = modCharacter.MouseProperties;
local playerSettings = modCharacter.Settings;

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local remoteCharacterRemote = modRemotesManager:Get("CharacterRemote");
local remoteCharacterInteractions = modRemotesManager:Get("CharacterInteractions");

local rbxPlayerModule = require(localPlayer.PlayerScripts.PlayerModule) :: any;

local remotes = game.ReplicatedStorage:FindFirstChild("Remotes");
local remoteCameraShakeAndZoom = remotes and remotes:FindFirstChild("CameraShakeAndZoom");

local motorUpdateCooldown = tick()-1;
local halfPi = math.pi/2;

local touchEnabled = UserInputService.TouchEnabled;
local oldCameraCFrame = currentCamera.CFrame;
local oldCamOffsetX = 0;
local oldCamOffsetY = 0;
local cameraOriginOffset = Vector3.new();
local crouchCooldown = tick()-1;

local slideDirection = Vector3.new();
local slideForce = Instance.new("BodyVelocity"); slideForce.MaxForce = Vector3.new(); slideForce.Parent = rootPart;
local slideCooldown = tick()-5;
local oldSlideMomentum = 0;
local slopeUpFriction = 2;
local slopeDownFriction = 6;

local heartbeatSecTick = tick()-1;

local footAttachment = Instance.new("Attachment", rootPart); footAttachment.Position = Vector3.new(0, -3, 0);
local dustParticle = script:WaitForChild("DustParticle"); dustParticle = dustParticle:Clone(); dustParticle.Parent = footAttachment;
local slideSound = head:FindFirstChild("BodySlide");

local minZoomLevel = 4;
local maxZoomLevel = 20;
local additionalZoom = 0;
local lastFOV = 70;
local prevHipHeight, prevViewModelHeight = 0, 0;
local prevViewModel = characterProperties.DefaultViewModel;
local shakeAndZoomVars = { canOverrideShakeAndZoom = true; shakingAndZooming = false; breakShakingAndZooming = false;};
local mouseEnabled = UserInputService.MouseEnabled;
local previouslyEquipped, prevCharInteracting = false, false;
local touchInputVariables = {lastTouch=tick();};

local currentThirdPerson = true;
local xLeftDeltaAddition, xRightDeltaAddition = false, false;

local mathAtan2 = math.atan2; local mathClamp = math.clamp; local newNoise = math.noise; local random = Random.new();
local deg60 = math.pi/3;
local deg45 = math.pi/4;

local environmentOnly = {workspace:WaitForChild("Environment"); workspace.Terrain};
local environmentCollidable = {workspace:FindFirstChild("Environment"); workspace:FindFirstChild("Clips"); workspace:FindFirstChild("Interactables"); workspace:FindFirstChild("Entity"); workspace.Terrain};
local isCharCamEnabled = false; 

local EditModeTag = false;

local CameraSubject = {IsClientSubject=true; Character=character; RootPart=rootPart; Head=head;};
local Cache = {
	JumpPressCount = 0;
	OldTerrainWaterTransparency = workspace.Terrain.WaterTransparency;
	AntiGravityForce = nil;
	ViewModelErr = nil;
	OldState = nil;
	CameraSubjectUpdated = nil;

	CrouchCheckCooldown = tick();

	NeckC0 = CFrame.new();
	WaistC0 = CFrame.new();
};

local CollisionModel={
	Default={C0=CFrame.new(0, 1, 0); Size=Vector3.new(2, 3.8, 1);};
	Crouch={C0=CFrame.new(0, 0.2, -0.5); Size=Vector3.new(2, 1.5, 2.4);};
	Wounded={C0=CFrame.new(0, -0.5, -1.2); Size=Vector3.new(2, 2, 2.6);};
	Swimming={C0=CFrame.new(0, 0.8, 0); Size=Vector3.new(2, 5, 1);};
	AntiGravity={C0=CFrame.new(0, 1.6, 0); Size=Vector3.new(2, 5, 1.5);};
}
--== Script;
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false);
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false);
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false);
SoundService:SetListener(Enum.ListenerType.ObjectCFrame, rootPart);
UserGameSettings.Changed:Connect(function() mouseProperties.DefaultSensitivity = UserGameSettings.MouseSensitivity; end)
local modKeyBindsHandler = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("KeyBindsHandler"));

modCharacter.Humanoid = humanoid;
modCharacter.Player = localPlayer;
modCharacter.PlayerGui = localPlayer.PlayerGui;
modCharacter.Head = head;
modCharacter.RootPart = rootPart;

mouseProperties.DefaultSensitivity = UserGameSettings.MouseSensitivity;

if localPlayer:GetAttribute("hm_1") then
	characterProperties.DefaultWalkSpeed = 16;
	characterProperties.DefaultSwimSpeed = 10;
	characterProperties.DefaultSprintSpeed = 20;
end

characterProperties.WalkSpeed = modLayeredVariable.new(characterProperties.DefaultWalkSpeed);
characterProperties.JumpPower = modLayeredVariable.new(characterProperties.DefaultJumpPower);
characterProperties.SpeedMulti = modLayeredVariable.new(1);

characterProperties.AmbientReverb = modLayeredVariable.new(Enum.ReverbType.NoReverb);
characterProperties.SwimSpeed = characterProperties.DefaultSwimSpeed;
characterProperties.SprintSpeed = characterProperties.DefaultSprintSpeed;

local charBodyForce = Instance.new("VectorForce");
charBodyForce.Name = "BodyForce";
charBodyForce.ApplyAtCenterOfMass = true;
charBodyForce.RelativeTo = Enum.ActuatorRelativeTo.World;
charBodyForce.Attachment0 = rootPart:WaitForChild("RootRigAttachment");
charBodyForce.Enabled = false;
charBodyForce.Parent = rootPart;

characterProperties.BodyForce = modLayeredVariable.new();

local modInterface
--
modCharacter.TouchButtons.SpaceActionButton = modLayeredVariable.new(false);
modCharacter.TouchButtons.CtrlActionButton = modLayeredVariable.new(false);

characterProperties.HumanStates = {};
for _, v in pairs(Enum.HumanoidStateType:GetEnumItems()) do
	if v == Enum.HumanoidStateType.Dead
		or v == Enum.HumanoidStateType.None then 
		continue 
	end;
	characterProperties.HumanStates[v] = humanoid:GetStateEnabled(v);
end

humanoid.StateEnabledChanged:Connect(function(state, isEnabled)
	if characterProperties.HumanStates[state] == nil then return end;
	if isEnabled == characterProperties.HumanStates[state] then return end;
	humanoid:SetStateEnabled(state, characterProperties.HumanStates[state] == true);
end)


local updateCharacterTransparency = function() end;

local function onHumanoidStateChanged(oldState, newState)
	characterProperties.State = newState;

	if newState == Enum.HumanoidStateType.Swimming then
		characterProperties.IsSwimming = true;
		Cache.LastSwimming = tick();
	else
		if Cache.LastSwimming == nil or tick()-Cache.LastSwimming >= 0.3 then
			characterProperties.IsSwimming = false;
		end
	end
	
	if newState == Enum.HumanoidStateType.FallingDown and classPlayer.Properties.Ragdoll ~= 1 then
		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll);
	end
	if newState == Enum.HumanoidStateType.Ragdoll and classPlayer.Properties.Ragdoll ~= 1 then
		characterProperties.HumanStates[Enum.HumanoidStateType.GettingUp] = false;
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false);
	end

	characterProperties.IsRagdoll = newState == Enum.HumanoidStateType.Ragdoll 
		or newState == Enum.HumanoidStateType.GettingUp 
		or newState == Enum.HumanoidStateType.FallingDown
		or newState == Enum.HumanoidStateType.PlatformStanding;

	if newState == Enum.HumanoidStateType.Swimming
		or newState == Enum.HumanoidStateType.Climbing
		or newState == Enum.HumanoidStateType.PlatformStanding
		or newState == Enum.HumanoidStateType.Seated
		or newState == Enum.HumanoidStateType.Ragdoll then -- Can't crouch 
		characterProperties.CanCrouch = false;
	else
		characterProperties.CanCrouch = true;
	end

	if newState == Enum.HumanoidStateType.Swimming then
		remoteCharacterRemote:FireServer(4, true);
		modCharacter.TouchButtons.SpaceActionButton:Set("swimming", true, 2);
		modCharacter.TouchButtons.CtrlActionButton:Set("swimming", true, 2);

	else
		Cache.StopSwimmingTimer = tick();
		modCharacter.TouchButtons.SpaceActionButton:Remove("swimming");
		modCharacter.TouchButtons.CtrlActionButton:Remove("swimming");

	end

	if newState == Enum.HumanoidStateType.Climbing then
		remoteCharacterRemote:FireServer(3, true);
	else
		remoteCharacterRemote:FireServer(3, false);
	end
end


function onCameraSubjectUpdate()
	local subject = currentCamera.CameraSubject;
	Debugger:Warn("CameraSubject changed", subject);
	
	if modInterface then modInterface:ToggleGameBlinds(false, 0.25); end
	task.wait(0.25);
	characterProperties.RefreshTransparency = true;

	if subject and subject:IsA("Humanoid") then
		if subject == humanoid then
			CameraSubject = {IsClientSubject=true; Character=character; RootPart=rootPart; Head=head};
			SoundService:SetListener(Enum.ListenerType.ObjectCFrame, rootPart);	

		else
			local subjectModel = subject.Parent;
			local subjectRootPart = subjectModel:FindFirstChild("HumanoidRootPart");
			if subjectRootPart == nil then return end;
			
			local subjectHead = subjectModel:FindFirstChild("Head");
			SoundService:SetListener(Enum.ListenerType.ObjectCFrame, subjectRootPart);

			CameraSubject = {IsClientSubject=false; Character=subjectModel; RootPart=subjectRootPart; Head=subjectHead};

			pcall(function()
				subjectModel["RightHand"]:SetAttribute("CustomTransparency", 0);
				subjectModel["RightLowerArm"]:SetAttribute("CustomTransparency", 0);
				subjectModel["RightUpperArm"]:SetAttribute("CustomTransparency", 0);
				subjectModel["LeftHand"]:SetAttribute("CustomTransparency", 0);
				subjectModel["LeftLowerArm"]:SetAttribute("CustomTransparency", 0);
				subjectModel["LeftUpperArm"]:SetAttribute("CustomTransparency", 0);
			end)
			updateCharacterTransparency();

		end

	elseif subject and subject:IsA("VehicleSeat") then
		local _occupant = subject.Occupant;

		local vehiclePrefab = nil;
		if subject.Parent:FindFirstChild("Vehicle") and subject.Parent.Vehicle:IsA("ModuleScript") then
			vehiclePrefab = subject.Parent;
		elseif subject.Parent.Parent:FindFirstChild("Vehicle") and subject.Parent.Parent.Vehicle:IsA("ModuleScript") then
			vehiclePrefab = subject.Parent.Parent;
		end

		CameraSubject = {IsClientSubject=true; Vehicle=vehiclePrefab; Character=character; RootPart=rootPart; Head=head};
		SoundService:SetListener(Enum.ListenerType.ObjectCFrame, rootPart);	

	else
		CameraSubject = {};
	end
	
	if modInterface then modInterface:ToggleGameBlinds(true, 0.25); end
	Cache.CameraSubjectUpdated = true;
end

currentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(onCameraSubjectUpdate);
onCameraSubjectUpdate();


local function getCharacterMass()
	local mass = 0;
	for _, child in pairs(character:GetDescendants()) do
		if child:IsA("BasePart") and child.Parent.ClassName ~= "Accessory" then
			mass = mass + child:GetMass();
		end
	end
	return mass;
end

local function setAlignRot(data)
	local enabled = data.Enabled;
	local cframe = data.CFrame;

	if characterProperties.InteractGyro and characterProperties.InteractAlpha > 0 then
		local dist = (characterProperties.InteractGyro.Position-rootPart.Position).Magnitude;
		local d = 1-math.clamp((dist/12), 0, 1);
		
		if d > 0 then
			cframe = characterProperties.InteractGyro;
			enabled = true;
		else
			characterProperties.InteractGyro = nil;
		end
	else
		if data.CFrame then
			cframe = data.CFrame;
		end
		if data.Enabled then
			enabled = data.Enabled;
		end
	end
	
	if cframe ~= nil then
		alignRotation.CFrame = cframe;
	end
	if enabled ~= nil then
		alignRotation.Enabled = enabled;
	end
end

local function toggleCameraMode(value)
	if characterProperties.ThirdPersonCamera == value then return end;
	if value ~= nil then characterProperties.ThirdPersonCamera = value end;
	local cameraPoint = currentCamera.CFrame.lookVector;
	mouseProperties.X = mathAtan2(-cameraPoint.X, -cameraPoint.Z);
	mouseProperties.RawX = mouseProperties.X;
	mouseProperties.Y = math.atan(cameraPoint.Y);
	mouseProperties.RawY = mouseProperties.Y;
	
	if not characterProperties.IsEquipped then
		UserInputService.MouseIconEnabled = not mouseProperties.MouseLocked;
	end
	humanoid.AutoRotate = true;
	
	setAlignRot{
		Enabled = false;
	}
	if not characterProperties.ThirdPersonCamera then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
	end
end

local checkCounter = 0;
local function crouchToggleCheck(rootPoint, uncrouch)
	checkCounter = checkCounter +1;

	local upCollisionRay = Ray.new(rootPoint.p, rootPoint.upVector*4);
	local upCollisionHit, upHitPos = workspace:FindPartOnRayWithWhitelist(upCollisionRay, environmentOnly, true);

	local upGap = (upHitPos.Y-rootPoint.p.Y);
	
	if upGap <= 3.5 and characterProperties.CanCrouch and characterProperties.IsAlive then --2.6
		characterProperties.IsCrouching = true;
		
	else
		if characterProperties.CanCrouch == false then
			characterProperties.IsCrouching = false;
		elseif uncrouch and not characterProperties.CrouchKeyDown then
			characterProperties.IsCrouching = false;
		end
	end
	return upCollisionHit, upHitPos;
end

local function ToggleBodypartTransparency(bodyParts, hide, includeArms)
	if character:GetAttribute("VisibleArms") == true then
		includeArms = false;
	end
	local isInvisible = character:GetAttribute("IsInvisible") == true;
	if isInvisible then return end;
	
	local EquippedTools = nil;
	
	for a=1, #bodyParts do
		local toolModel = bodyParts[a];
		if toolModel:IsA("Model") and toolModel:GetAttribute("Equipped") ~= nil then
			if EquippedTools == nil then EquippedTools = {} end;
			EquippedTools[toolModel] = true;
			
			if toolModel:GetAttribute("Equipped") == true then
				includeArms = false;
				toolModel:SetAttribute("FirstPersonVisible", 2);
				
			else
				toolModel:SetAttribute("FirstPersonVisible", nil);
				
			end
		end
	end
	
	local overlapBodyParts = {};
	for a=1, #bodyParts do
		local object = bodyParts[a];
		
		local fpVisible;
		local scanObj = object;
		
		while scanObj:IsDescendantOf(character) do
			fpVisible = scanObj:GetAttribute("FirstPersonVisible");
			if fpVisible == nil then
				scanObj = scanObj.Parent;
			else
				break;
			end
		end
		
		if fpVisible == 1 then --invisible when arms are invis;
			fpVisible = not includeArms;
			
		elseif fpVisible == 2 then --Never go invisible, never set DefaultTransparency
			fpVisible = true;
			
		else
			fpVisible = false;
			
		end
		
		if object:GetAttribute("CustomTransparency") then
			-- Do nothing;
		elseif object:IsA("Accessory") and object:GetAttribute("HideBodyPart") then
			local overlapPart = character:FindFirstChild(object:GetAttribute("HideBodyPart"));
			if overlapPart then
				table.insert(overlapBodyParts, overlapPart);
			end
			
		elseif object:IsA("BasePart") or object:IsA("Texture") or object:IsA("Decal") then
			local savedTransparency = object:GetAttribute("ActiveTransparency") or object:GetAttribute("DefaultTransparency");
			
			if hide and fpVisible == false then
				if savedTransparency == nil then
					object:SetAttribute("DefaultTransparency", object.Transparency);
				end
				object.Transparency = 1;
				
			else
				local toggleClothing = object:GetAttribute("ToggleClothing");
				if toggleClothing == false then
					if savedTransparency == nil then
						object:SetAttribute("DefaultTransparency", object.Transparency);
					end
					object.Transparency = 1;
					
				elseif savedTransparency then
					object.Transparency = savedTransparency;
					
				end
			end
			if object:IsA("BasePart") then
				object.CastShadow = not hide;
				object.LocalTransparencyModifier = 0;
				
			end
			
		elseif object:IsA("Fire") or object:IsA("ParticleEmitter") or object:IsA("Smoke") then
			
			local insideTool = false;
			
			for equippedTool, _ in pairs(EquippedTools or {}) do
				if object:IsDescendantOf(equippedTool) then
					insideTool = true;
					break;
				end
			end
			
			if not insideTool then
				if object:GetAttribute("FPIgnore") ~= true and object.Enabled ~= not hide then
					object.Enabled = not hide;
					
					if object:IsA("ParticleEmitter") then
						object:Clear();
					end
				end
			end

		elseif object:IsA("RopeConstraint") and object:GetAttribute("FPIgnore") ~= true then
			object.Visible = not hide;
			
		elseif object.Name == "NameDisplay" then
			object.Enabled = not hide;
			
			
		end
		
	end
	
	for a=1, #overlapBodyParts do
		if overlapBodyParts[a]:IsA("BasePart") then
			overlapBodyParts[a].Transparency = 1;
		end
	end
end

local function crouchRequest(value)
	if value then
		characterProperties.CrouchKeyDown = true;
		crouchCooldown = tick();

		if (characterProperties.IsSprinting and humanoid.WalkSpeed > characterProperties.WalkingSpeed+1) 
			and not characterProperties.IsWalking and not characterProperties.IsSliding and (tick()-slideCooldown)>0.7
			and not characterProperties.IsWounded then
			-- MARK: StartSlide;

			if slideSound then
				slideSound.PlaybackSpeed = random:NextNumber(1.2, 1.5);
				slideSound.Volume = 0.15;
				slideSound:Play();
			else
				slideSound = head:FindFirstChild("BodySlide");
			end
			dustParticle.Enabled = true;

			characterProperties.IsSliding = true;
			slideDirection = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z).Unit;
			oldSlideMomentum = characterProperties.SlideSpeed;
			slideForce.Velocity = slideDirection*oldSlideMomentum;

		end
		characterProperties.IsCrouching = true;
		
	else
		characterProperties.CrouchKeyDown = false;
		
	end
end


local mainInterface, interfaceModule, specFrame, notifyFrame, deathScreen, gameBlinds;
local function loadInterface()
	modInterface = modData:GetInterfaceModule();

	if modInterface.CharacterScriptLoaded then return end;
	modInterface.CharacterScriptLoaded = true;
	
	mainInterface = modInterface.MainInterface;
	interfaceModule = mainInterface:WaitForChild("InterfaceModule");
	specFrame = mainInterface:WaitForChild("SpectatorMenu");
	gameBlinds = mainInterface:WaitForChild("GameBlinds");
	notifyFrame = mainInterface:WaitForChild("NotificationBoard");
	deathScreen = mainInterface:WaitForChild("DeathScreen");
	
	if touchEnabled then
		warn("Touch input is enabled.");
		mainInterface.TouchControls.Visible = true;

		mainInterface.TouchControls.PrimaryFire.MouseButton1Down:Connect(function()
			mouseProperties.Mouse1Down = true;
			if script.Parent:FindFirstChild("EquipmentScript") then
				script.Parent.EquipmentScript.CharacterInput:Fire("KeyFire");
			end
		end)
		mainInterface.TouchControls.PrimaryFire.MouseButton1Up:Connect(function()
			mouseProperties.Mouse1Down = false;
		end)

		mainInterface.TouchControls.Focus.MouseButton1Down:Connect(function()
			mouseProperties.Mouse2Down = not mouseProperties.Mouse2Down;
			if script.Parent:FindFirstChild("EquipmentScript") then
				script.Parent.EquipmentScript.CharacterInput:Fire("KeyFocus");
			end
		end)

		mainInterface.TouchControls.Reload.MouseButton1Down:Connect(function()
			if script.Parent:FindFirstChild("EquipmentScript") then
				script.Parent.EquipmentScript.CharacterInput:Fire("KeyReload");
			end
		end)

		mainInterface.TouchControls.Crouch.MouseButton1Down:Connect(function()
			if characterProperties.IsAlive and characterProperties.CanMove and (tick()-crouchCooldown) > 0.1 then
				if characterProperties.CanCrouch then
					crouchRequest(not characterProperties.CrouchKeyDown);
				else
					crouchRequest(false);
				end
			end
		end)
		mainInterface.TouchControls.Crouch.MouseButton1Up:Connect(function()
			if modData:IsMobile() then return end;
			characterProperties.CrouchKeyDown = false;
		end)

		mainInterface.TouchControls.Sprint.MouseButton1Click:Connect(function()
			if characterProperties.IsAlive and characterProperties.CanMove and characterProperties.CanSprint and not humanoid.Sit and not humanoid.PlatformStand then
				characterProperties.SprintKeyDown = not characterProperties.SprintKeyDown;
			else
				characterProperties.SprintKeyDown = false;
			end
		end)
		mainInterface.TouchControls.Camera.MouseButton1Click:Connect(function()
			if characterProperties.ZoomLevel+2 >= maxZoomLevel then
				characterProperties.ZoomLevel = 2;
			else
				characterProperties.ZoomLevel = characterProperties.ZoomLevel +2;
			end
		end)

		modCharacter.TouchButtons.SpaceActionButton.Changed:Connect(function()
			mainInterface.TouchControls.SpaceActionButton.Visible = modCharacter.TouchButtons.SpaceActionButton:Get();
			
		end)
		mainInterface.TouchControls.SpaceActionButton.MouseButton1Down:Connect(function()
			characterProperties.ActionKeySpaceDown = true;
			Cache.JumpPressCount = Cache.JumpPressCount +1;
		end)
		mainInterface.TouchControls.SpaceActionButton.MouseButton1Up:Connect(function()
			characterProperties.ActionKeySpaceDown = false;
		end)

		modCharacter.TouchButtons.CtrlActionButton.Changed:Connect(function()
			mainInterface.TouchControls.CtrlActionButton.Visible = modCharacter.TouchButtons.CtrlActionButton:Get();
			
		end)
		mainInterface.TouchControls.CtrlActionButton.MouseButton1Down:Connect(function()
			characterProperties.ActionKeyCtrlDown = true;
		end)
		mainInterface.TouchControls.CtrlActionButton.MouseButton1Up:Connect(function()
			characterProperties.ActionKeyCtrlDown = false;
		end)
		UserInputService.TouchMoved:Connect(function(inputObject, gameProcessedEvent)
			if gameProcessedEvent then return end
			mouseProperties.X = mouseProperties.X + (-inputObject.Delta.x/200* mouseProperties.Sensitivity);
			mouseProperties.Y = mouseProperties.Y + (-inputObject.Delta.y/300* mouseProperties.Sensitivity);
			mouseProperties.Y = mathClamp(mouseProperties.Y, -1.553, 1.553);
		end)
	end
	
end

UserInputService.InputBegan:connect(function(inputObject, gameProcessedEvent)
	if UserInputService:GetFocusedTextBox() ~= nil then return end;
	if not gameProcessedEvent then
		if modKeyBindsHandler:Match(inputObject, "KeyFire") then
			mouseProperties.Mouse1Down = true;
			
		elseif modKeyBindsHandler:Match(inputObject, "KeyFocus") then
			
			if character:FindFirstChild("EditMode") then
				EditModeTag = true;
			else
				EditModeTag = false;
			end
			
			if modData.Settings.ToggleAimMode == 1 then
				mouseProperties.Mouse2Down = not mouseProperties.Mouse2Down;
			else
				mouseProperties.Mouse2Down = true;
			end
			
		end
		if inputObject.UserInputType == Enum.UserInputType.MouseButton3 or inputObject.KeyCode == Enum.KeyCode.P then
			if mouseProperties.CanManualLockMouse then
				mouseProperties.MouseLocked = not mouseProperties.MouseLocked;
				mainInterface.MouseLockHint.Visible = not mouseProperties.MouseLocked;
			else
				mainInterface.MouseLockHint.Visible = false;
			end
		end
	end
	
	if modKeyBindsHandler:Match(inputObject, "KeyCamSide") then
		characterProperties.LeftSideCamera = not characterProperties.LeftSideCamera;
	end
	
	if inputObject.KeyCode == Enum.KeyCode.Equals or inputObject.KeyCode == Enum.KeyCode.KeypadPlus then
		characterProperties.ZoomLevel = mathClamp(characterProperties.ZoomLevel + 2, 2, maxZoomLevel);
	elseif inputObject.KeyCode == Enum.KeyCode.Minus or inputObject.KeyCode == Enum.KeyCode.KeypadMinus then
		characterProperties.ZoomLevel = mathClamp(characterProperties.ZoomLevel - 2, 2, maxZoomLevel);
	end
	
	if inputObject.KeyCode == Enum.KeyCode.Left then xLeftDeltaAddition = true; end
	if inputObject.KeyCode == Enum.KeyCode.Right then xRightDeltaAddition = true; end
	
	if modKeyBindsHandler:Match(inputObject, "KeySprint") and characterProperties.IsAlive and characterProperties.CanMove and characterProperties.CanSprint and not humanoid.Sit and not humanoid.PlatformStand then
		characterProperties.SprintKeyDown = true;
		characterProperties.IsSprinting = true;
	end
	
	if modKeyBindsHandler:Match(inputObject, "KeyWalk") and characterProperties.IsAlive and characterProperties.CanMove and not humanoid.Sit and not humanoid.PlatformStand then
		characterProperties.WalkKeyDown = true;
		characterProperties.IsWalking = true;
	end

	if modKeyBindsHandler:Match(inputObject, "KeyJump") then
		characterProperties.ActionKeySpaceDown = true;
		Cache.JumpPressCount = Cache.JumpPressCount +1;
	end
	
	if modKeyBindsHandler:Match(inputObject, "KeyCrouch") then
		characterProperties.ActionKeyCtrlDown = true;
		if characterProperties.IsAlive and characterProperties.CanMove and characterProperties.CanCrouch and (tick()-crouchCooldown) > 0.1 then
			crouchRequest(not characterProperties.CrouchKeyDown);
		end
		task.spawn(function()
			remoteCharacterInteractions:InvokeServer("eject");
		end)
	end
	if touchEnabled then
		if inputObject.UserInputType == Enum.UserInputType.Touch then
			if (tick() - touchInputVariables.lastTouch) < 0.1 then
				-- Double tap;
			end
			touchInputVariables.lastTouch = tick();
		end
	end
	if inputObject.KeyCode == Enum.KeyCode.DPadDown then
		if characterProperties.ZoomLevel+2 >= maxZoomLevel then
			characterProperties.ZoomLevel = 2;
		else
			characterProperties.ZoomLevel = characterProperties.ZoomLevel +2;
		end
	end
	
	if characterProperties.IsSpectating 
		and (inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch) then
		
		Debugger:Warn("Switch spectate");
		modSpectateManager:SetSpectate();
	end
end)

local mouseNoise = 0;
local gamepadDelta = Vector2.new();
UserInputService.InputChanged:Connect(function(inputObject, gameProcessedEvent)
	if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
		mouseProperties.X = mouseProperties.X < -math.pi and math.pi or mouseProperties.X > math.pi and -math.pi or mouseProperties.X;
		
		local sen = mouseProperties.Sensitivity;
		if mouseProperties.MovementNoise == true then
			mouseNoise = mouseNoise + 1/60;
			sen = sen * (newNoise(tick(), mouseNoise)*2);
		end
		
		if characterProperties.FreecamState ~= 2 then
			mouseProperties.X = mouseProperties.X + (-inputObject.Delta.x/200*sen);
			mouseProperties.Y = mouseProperties.Y + (-inputObject.Delta.y/300*sen);
			mouseProperties.Y = mathClamp(mouseProperties.Y, -1.553, 1.553);
		end
	end
	if inputObject.UserInputType == Enum.UserInputType.MouseWheel and not gameProcessedEvent then
		characterProperties.ZoomLevel = mathClamp(characterProperties.ZoomLevel - 2*inputObject.Position.Z, 2, maxZoomLevel);
	end
	if inputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
		local inputVector = Vector2.new(inputObject.Position.X, -inputObject.Position.Y);
		if inputVector.magnitude > 0.2 then
			gamepadDelta = inputVector;
		else
			gamepadDelta = Vector2.new();
		end
	end
end)

local function bindGamepadMovement(gamepadId)
	characterProperties.ControllerEnabled = true;
	RunService:BindToRenderStep(tostring(gamepadId), Enum.RenderPriority.Input.Value, function()
		mouseProperties.X = mouseProperties.X < -math.pi and math.pi or mouseProperties.X > math.pi and -math.pi or mouseProperties.X;
		mouseProperties.X = mouseProperties.X + (-gamepadDelta.X/(mouseProperties.Mouse1Down and 40 or 10)* mouseProperties.Sensitivity);
		mouseProperties.Y = mouseProperties.Y + (-gamepadDelta.Y/(mouseProperties.Mouse1Down and 60 or 15)* mouseProperties.Sensitivity);
		mouseProperties.Y = mathClamp(mouseProperties.Y, -1.553, 1.553);
	end)
end

for _, gamepadId in pairs(UserInputService:GetConnectedGamepads()) do bindGamepadMovement(gamepadId) end;
UserInputService.GamepadConnected:Connect(bindGamepadMovement);
UserInputService.GamepadDisconnected:Connect(function(gamepadId) RunService:UnbindFromRenderStep(tostring(gamepadId)) end);

UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
	if modKeyBindsHandler:Match(inputObject, "KeyFire") then
		mouseProperties.Mouse1Down = false;
	end
	if modKeyBindsHandler:Match(inputObject, "KeyFocus") then
		if modData.Settings.ToggleAimMode == 1 then
		else
			mouseProperties.Mouse2Down = false;
		end
	end
	
	if modKeyBindsHandler:Match(inputObject, "KeySprint") then --  or inputObject.KeyCode == Enum.KeyCode.ButtonL3
		characterProperties.SprintKeyDown = false;
	end
	
	if modKeyBindsHandler:Match(inputObject, "KeyWalk") then --  or inputObject.KeyCode == Enum.KeyCode.ButtonL3
		characterProperties.WalkKeyDown = false;
	end
	
	if inputObject.KeyCode == Enum.KeyCode.Left then xLeftDeltaAddition = false; end
	if inputObject.KeyCode == Enum.KeyCode.Right then xRightDeltaAddition = false; end

	if modKeyBindsHandler:Match(inputObject, "KeyCrouch") then -- or inputObject.KeyCode == Enum.KeyCode.ButtonR3
		characterProperties.ActionKeyCtrlDown = false;
		if modData.Settings.ToggleCrouch == 1 then
		else
			characterProperties.CrouchKeyDown = false;
			if (tick()-crouchCooldown)>0.2 then
				crouchToggleCheck(rootPart.CFrame, true);
			else
				delay(0.2, function() crouchToggleCheck(rootPart.CFrame, true) end);
			end
		end
	end
	if modKeyBindsHandler:Match(inputObject, "KeyJump") then
		characterProperties.ActionKeySpaceDown = false;
	end
end)

local function characterMoving(speed)
	local _state = humanoid:GetState();
	characterProperties.MoveSpeed = speed;
	characterProperties.IsMoving = speed > 1;

	if not characterProperties.IsMoving then
		characterProperties.IsSprinting = false;
		characterProperties.IsWalking = false;
		
	elseif characterProperties.CanMove and characterProperties.SprintKeyDown then
		characterProperties.IsSprinting = true;
		
	end
	
	if characterProperties.CanMove and characterProperties.WalkKeyDown then
		characterProperties.IsWalking = true;
		
	end
	
	
	if not characterProperties.IsWounded then
		if animations["woundedWalk"].IsPlaying then
			animations["woundedWalk"]:Stop();
		end
		if animations["woundedIdle"].IsPlaying then
			animations["woundedIdle"]:Stop();
		end
	end
	if characterProperties.IsWounded then
		if animations["crouchIdle"].IsPlaying then
			animations["crouchIdle"]:Stop();
		end
		if animations["crouchWalk"].IsPlaying then
			animations["crouchWalk"]:Stop();
		end
		
		if speed > 0 then
			if not animations["woundedWalk"].IsPlaying then
				animations["woundedWalk"]:Play();
			end
			animations["woundedWalk"]:AdjustSpeed(humanoid.WalkSpeed/5);
		else
			if animations["woundedWalk"].IsPlaying then
				animations["woundedWalk"]:Stop();
			end
		end
		
	elseif characterProperties.IsCrouching then
		if speed > 0 and not characterProperties.IsSliding and not characterProperties.IsRagdoll then
			
			if animations["crouchIdle"].IsPlaying then
				animations["crouchIdle"]:Stop();
			end
			if not animations["crouchWalk"].IsPlaying then
				animations["crouchWalk"]:Play();
			end
			
			animations["crouchWalk"]:AdjustSpeed(humanoid.WalkSpeed/14);
			
		else
			if animations["crouchWalk"].IsPlaying then
				animations["crouchWalk"]:Stop();
			end
		end
	else
		if animations["crouchWalk"].IsPlaying then
			animations["crouchWalk"]:Stop();
		end
	end
end

-- MARK: stopSliding
function stopSliding(delayTime)
	Cache.lastSlide = nil;
	characterProperties.IsSliding = false;
	if slideSound then
		spawn(function() 
			repeat 
				slideSound.Volume = slideSound.Volume - 0.05 
			until slideSound.Volume <= 0 or not wait(1/60);
		end)
	end
	dustParticle.Enabled = false;
	if animations["slide"] then animations["slide"]:Stop(); end
	slideCooldown = tick();

	task.spawn(function()
		for a=0, (delayTime or 0), 1/15 do
			local slopeDot = slideDirection:Dot(characterProperties.GroundNormal);

			if slopeDot <= 0.1 then
				oldSlideMomentum = oldSlideMomentum - math.max(math.abs(slopeDot), 0.3) *(slopeUpFriction*4);
			end
			slideForce.Velocity = slideDirection*math.max(oldSlideMomentum, 0);

			task.wait(1/15);
		end
		
		slideForce.MaxForce = Vector3.new(0, 0, 0);
		characterProperties.SlideVelocity = Vector3.zero;
		
		setAlignRot{
			Enabled=false;
		};
		characterMoving(1.1);
	end)
	
	if modData:IsMobile() then
		characterProperties.CrouchKeyDown = false;
	end
end

function CameraShakeAndZoom(shakeStrength, zoomStrength, duration, smoothing, disallowOverride)
	if not shakeAndZoomVars.canOverrideShakeAndZoom and shakeAndZoomVars.shakingAndZooming then return end;
	shakeAndZoomVars.shakingAndZooming = true;
	shakeAndZoomVars.breakShakingAndZooming = true;
	delay(0.1, function() shakeAndZoomVars.breakShakingAndZooming = false end);
	repeat RunService.RenderStepped:Wait(); until not shakeAndZoomVars.breakShakingAndZooming; 
	if disallowOverride then shakeAndZoomVars.canOverrideShakeAndZoom = false; else shakeAndZoomVars.canOverrideShakeAndZoom = true; end;
	if smoothing == nil then smoothing = 0.05 end;
	local halfDuration = duration/2;
	spawn(function()
		local oldZoom = additionalZoom;
		local oldShakeOffset = Vector3.new();
		local startTick = tick();
		local tickX = random:NextNumber(-1, 1);
		local tickY = random:NextNumber(-1, 1);
		if isVibrationSupported then
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, zoomStrength);
		end
		repeat
			local lerpAlpha = (math.clamp((tick() - startTick), 0, halfDuration)/halfDuration);
			additionalZoom = modMath.Lerp(oldZoom, zoomStrength, 0.2);
			oldZoom = additionalZoom;
			local offset = Vector3.new(newNoise(tickX, 0), newNoise(0, tickY), 0)*0.5*shakeStrength*(1-lerpAlpha);
			cameraOriginOffset = offset;
			oldShakeOffset = cameraOriginOffset;
			local deltaTime = RunService.RenderStepped:Wait();
			tickX = tickX+(deltaTime*10);
			tickY = tickY+(deltaTime*10);
		until (tick() - startTick) > halfDuration or shakeAndZoomVars.breakShakingAndZooming;
		startTick = tick();
		repeat
			local lerpAlpha = (math.clamp((tick() - startTick), 0, halfDuration)/halfDuration);
			additionalZoom = modMath.Lerp(oldZoom, 0, 0.05);
			oldZoom = additionalZoom;
			cameraOriginOffset = oldShakeOffset:lerp(Vector3.new(), lerpAlpha);
			oldShakeOffset = cameraOriginOffset;
			RunService.RenderStepped:Wait();
		until (tick() - startTick) > halfDuration or shakeAndZoomVars.breakShakingAndZooming;
		if isVibrationSupported then
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0);
		end
		cameraOriginOffset = Vector3.new();
		shakeAndZoomVars.shakingAndZooming = false;
		shakeAndZoomVars.breakShakingAndZooming = false;
	end)
end


modCharacter.UpdateWalkSpeed = function()
	if not characterProperties.IsAlive then return end;
	if characterProperties.CanMoveFreeCam == false then
		humanoid.JumpPower = 0;
		humanoid.WalkSpeed = 0;
		
	elseif characterProperties.CanMove then
		local speedTable = characterProperties.WalkSpeed:GetTable();
		local speed = speedTable and speedTable.Value or nil;
		local speedMulti = characterProperties.SpeedMulti:Get();

		humanoid.WalkSpeed = math.clamp(speed * speedMulti, 0, 300);
		humanoid.JumpPower = math.clamp(characterProperties.JumpPower:Get(), 0, 65);
		
		if speedTable.Id == "forceWalkspeed" and speed <= 0 then
			humanoid.JumpPower = 0;
		end
		
	else
		humanoid.JumpPower = 0;
		humanoid.WalkSpeed = 0;
		
	end;
	
	if humanoid.JumpPower <= 0 then
		characterProperties.HumanStates[Enum.HumanoidStateType.Jumping] = false;
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false);
	else
		characterProperties.HumanStates[Enum.HumanoidStateType.Jumping] = true;
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true);
	end
end

localPlayer.CameraMinZoomDistance = minZoomLevel-1;
localPlayer.CameraMaxZoomDistance = maxZoomLevel;
localPlayer.PlayerGui:SetTopbarTransparency(1);
modCharacter.StopSliding = stopSliding;
modCharacter.CameraShakeAndZoom = CameraShakeAndZoom;
modCharacter.Mass = getCharacterMass();

local charAnims = script:WaitForChild("Animations");

for a=0, 10 do
	if workspace:IsAncestorOf(animator) then
		break;
	else
		task.wait();
	end
end
if not workspace:IsAncestorOf(animator) then return end;


for _, animation in pairs(charAnims:GetChildren()) do
	local track = animator:LoadAnimation(animation);
	animations[animation.Name] = track;
	--animations[animation.Name].Priority = Enum.AnimationPriority.Idle;
end
charAnims.ChildAdded:Connect(function(child)
	local track = animator:LoadAnimation(child);
	animations[child.Name] = track;
end)

for key, value in pairs(modSettings ~= nil and modSettings or {}) do
	if playerSettings[key] ~= nil then
		playerSettings[key] = modSettings[key];
	end
end

local rootPoint = CFrame.new();
local startChar = game.StarterPlayer:WaitForChild("StarterCharacter");
local originaldata = {
	NeckC0=startChar.Head.Neck.C0;
	NeckC1=startChar.Head.Neck.C1;
	RightShoulderC0=startChar.RightUpperArm.RightShoulder.C0;
	RightShoulderC1=startChar.RightUpperArm.RightShoulder.C1;
	LeftShoulderC0=startChar.LeftUpperArm.LeftShoulder.C0;
	LeftShoulderC1=startChar.LeftUpperArm.LeftShoulder.C1;
	WaistC0=startChar.UpperTorso.Waist.C0;
	WaistC1=startChar.UpperTorso.Waist.C1;
	WaistX=0;
	LeftHipC0=startChar.LeftUpperLeg.LeftHip.C0;
	RightHipC0=startChar.RightUpperLeg.RightHip.C0;
};
local prevdata = {}; for k, v in pairs(originaldata) do prevdata[k] = v end;

local zoom = characterProperties.ZoomLevel or 8;

local crosshairGui = {
	zoomSize=UDim2.new(0, 4, 0, 4);
	zoomPosition=UDim2.new(0.5, 0, 0.5, 0); -- -20
	defaultSize=UDim2.new(0, 6, 0, 6);
	defaultPosition=UDim2.new(0.5, 0, 0.5, 0);---21
	easingDirection=Enum.EasingDirection.In;
	easingStyle=Enum.EasingStyle.Linear;
}

toggleCameraMode();


RunService:BindToRenderStep("OffCamRender", Enum.RenderPriority.Input.Value, function(delta)
	local activeCameraLayer = modCameraGraphics.RenderLayers:GetTable();
	
	if activeCameraLayer.Id == "freecam" then
		pcall(function()
			character.LeftUpperArm.LeftShoulder.C0 = originaldata.LeftShoulderC0;
			character.RightUpperArm.RightShoulder.C0 = originaldata.RightShoulderC0;
		end)

		if characterProperties.FreecamState == 1 then
			rootPoint = CFrame.new(CameraSubject.RootPart.CFrame.p) * CFrame.Angles(0, (mouseProperties.X + mouseProperties.XAngOffset), 0);
			
			setAlignRot{
				Enabled=true;
				CFrame=rootPoint;
			};
		end
		
		return;
	elseif activeCameraLayer.Id ~= "default" then
		if characterProperties.FirstPersonCamera then
			pcall(function()
				character.LeftUpperArm.LeftShoulder.C0 = originaldata.LeftShoulderC0;
				character.RightUpperArm.RightShoulder.C0 = originaldata.RightShoulderC0;
			end)
		end
		
		return;
	end
end)

local vpWtY = 0;
local upRayHit, upRayEnd;
local function renderStepped(camera, deltaTime)
	local renderTick = tick();
	if not workspace:IsAncestorOf(character) then return; end
	characterProperties.IsSpectating = (not CameraSubject.IsClientSubject or (not game.Players.CharacterAutoLoads and not characterProperties.IsAlive)) and modConfigurations.SpectateEnabled;

	rootPoint = CFrame.new(CameraSubject.RootPart.CFrame.Position) * CFrame.Angles(0, (mouseProperties.X + mouseProperties.XAngOffset), 0); --Yaw <>
	zoom = characterProperties.ZoomLevel or 8;

	if CameraSubject.RootPart == nil then return; end;
	if characterProperties.CharacterCameraEnabled == false then 
		pcall(function()
			character.LeftUpperArm.LeftShoulder.C0 = originaldata.LeftShoulderC0;
			character.RightUpperArm.RightShoulder.C0 = originaldata.RightShoulderC0;
		end)
		
		return;
	end;

	if specFrame and specFrame.Parent ~= nil then
		specFrame.Visible = characterProperties.IsSpectating;

		local specLabel = specFrame.SpectatingLabel;
		specLabel.Text = "Spectating: "..(camera.CameraSubject and camera.CameraSubject.Parent.Name or "Nothing");
	end


	if mouseProperties.Mouse2Down and characterProperties.CanMove then
		--== Character;
		if CameraSubject.IsClientSubject then
			characterProperties.IsFocused = true;

			if mouseProperties.MouseLocked then
				humanoid.AutoRotate = false;
				if characterProperties.IsSwimming or Cache.AntiGravityForce then
					setAlignRot{
						Enabled=true;
						CFrame=camera.CFrame;
					};

				elseif not humanoid.Sit and not humanoid.PlatformStand then -- and not humanoid.Jump
					setAlignRot{
						Enabled=true;
						CFrame=rootPoint;
					};

				end
			end
		end

		--== Camera;
		if not EditModeTag then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition;
		end
		--== Gui;
		if mainInterface and mainInterface.Parent and mainInterface.Crosshair then
			mainInterface.Crosshair:TweenSizeAndPosition(crosshairGui.zoomSize, crosshairGui.zoomPosition, crosshairGui.easingDirection, crosshairGui.easingStyle, 0.1, false);	
		end

	else
		--== Gui;
		if mainInterface and mainInterface.Parent and mainInterface.Crosshair then
			mainInterface.Crosshair:TweenSizeAndPosition(crosshairGui.defaultSize, crosshairGui.defaultPosition, crosshairGui.easingDirection, crosshairGui.easingStyle, 0.1, false);	
		end
		--== Camera;

		if CameraSubject.IsClientSubject then
			if characterProperties.CanMove then
				if characterProperties.BodyLockToCam then 
					humanoid.AutoRotate = false;

					setAlignRot{
						CFrame=rootPoint;
					};
					if not humanoid.Sit and not humanoid.PlatformStand and not humanoid.Jump then
						setAlignRot{
							Enabled=true;
						};

					end

				else
					-- if modData:IsMobile() and characterProperties.IsSliding then
					-- 	humanoid.AutoRotate = false;
					-- 	setAlignRot{
					-- 		CFrame=rootPoint;
					-- 		Enabled=true;
					-- 	};
	
					-- else
	
					-- end
					humanoid.AutoRotate = true;
					setAlignRot{
						Enabled=false;
					};

				end
			end
			characterProperties.IsFocused = false;
		end
	end
	camera.FieldOfView = modMath.Lerp(lastFOV, characterProperties.FieldOfView or characterProperties.BaseFieldOfView, 0.2);
	lastFOV = camera.FieldOfView;

	local defaultSensitivity = mouseProperties.DefaultSensitivity;
	if modData:IsMobile() then
		defaultSensitivity = defaultSensitivity * 2;
	end

	local zoomSensitivityDiff = camera.FieldOfView / characterProperties.BaseFieldOfView;
	mouseProperties.Sensitivity = defaultSensitivity * zoomSensitivityDiff;

	
	if characterProperties.IsSliding then
		if characterProperties.CrouchKeyDown == false or humanoid:GetState() == Enum.HumanoidStateType.Swimming then
			stopSliding();
		end

		if characterProperties.ThirdPersonCamera then -- and not modData:IsMobile()
			local mouseMoveDelta = UserInputService:GetMouseDelta();

			local inputVector = rbxPlayerModule:GetControls():GetMoveVector();
			local rootFaceCf = CFrame.new(rootPart.CFrame.Position, rootPart.CFrame.Position+slideDirection);

			if inputVector.X ~= 0 or inputVector.Z ~= 0 then
				local localInputDir = CFrame.lookAt(currentCamera.CFrame.Position, currentCamera.CFrame:ToWorldSpace(CFrame.new(inputVector)).Position);
				rootFaceCf = rootFaceCf:Lerp(
					localInputDir,
					modData:IsMobile() and 0.5 or 0.1);
			end

			setAlignRot{
				CFrame = rootFaceCf * CFrame.Angles(0, math.rad(-mouseMoveDelta.X/(modData:IsMobile() and 1 or 1.9)), 0);
				Enabled=true;
			};
		end
	end

	if xLeftDeltaAddition and not xRightDeltaAddition then
		local add = math.rad(3);
		if mouseProperties.MovementNoise == true then
			mouseNoise = mouseNoise + 1/60;
			add = math.rad(3) * (newNoise(tick(), mouseNoise)*2);
		end

		mouseProperties.X = mouseProperties.X < -math.pi and math.pi or mouseProperties.X > math.pi and -math.pi or mouseProperties.X;
		mouseProperties.X = mouseProperties.X + add;
	end;
	if xRightDeltaAddition and not xLeftDeltaAddition then
		local add = math.rad(3);
		if mouseProperties.MovementNoise == true then
			mouseNoise = mouseNoise + 1/60;
			add = add * (newNoise(tick(), mouseNoise)*2);
		end

		mouseProperties.X = mouseProperties.X < -math.pi and math.pi or mouseProperties.X > math.pi and -math.pi or mouseProperties.X;
		mouseProperties.X = mouseProperties.X - add;
	end;

	local upOffset = 4;
	local upCollisionRay = Ray.new(rootPoint.Position, Vector3.new(0, upOffset, 0));

	if renderTick > Cache.CrouchCheckCooldown then
		Cache.CrouchCheckCooldown = renderTick + 0.2;
		upRayHit, upRayEnd = crouchToggleCheck(rootPart.CFrame, true);
	end

	if characterProperties.ThirdPersonCamera then
		characterProperties.BaseFieldOfView = 70;
		local newCamOffsetX = oldCamOffsetX;
		local sideOffsets = 3.5;
		local originCollisionRay = Ray.new(rootPoint.p, rootPoint.rightVector* (characterProperties.LeftSideCamera and -sideOffsets or sideOffsets));

		local originRayHit, originRayEnd;
		if modData:IsMobile() then
		else
			originRayHit, originRayEnd = workspace:FindPartOnRayWithWhitelist(originCollisionRay, environmentOnly, true);
		end
		 
		newCamOffsetX = originRayHit ~= nil and ((originRayEnd-originCollisionRay.Origin)/(originCollisionRay.Direction.unit)).X or sideOffsets;
		if oldCamOffsetX < newCamOffsetX then newCamOffsetX = modMath.Lerp(oldCamOffsetX, newCamOffsetX, 0.2); end
		oldCamOffsetX = newCamOffsetX;

		local newCamOffsetY = oldCamOffsetY;
		newCamOffsetY = upRayHit ~= nil and (((upRayEnd-upCollisionRay.Origin)/(upCollisionRay.Direction.unit)).Y-0.2) or upOffset;

		if characterProperties.IsCrouching or characterProperties.IsWounded then
			newCamOffsetY = newCamOffsetY-2.5; -- 3 old tp cam height
		elseif characterProperties.IsSliding then
			newCamOffsetY = newCamOffsetY-2.5;
		end

		if modData:IsMobile() then
		else
			newCamOffsetY = modMath.Lerp(oldCamOffsetY, newCamOffsetY, 0.2);
		end
		
		oldCamOffsetY = newCamOffsetY;

		local originOffset = cameraOriginOffset;
		local tempzoom = zoom-additionalZoom;
		local cameraHeight = math.clamp(newCamOffsetY, 1, 4);


		local focusCf = rootPoint 
			* CFrame.Angles(0, 0, (mouseProperties.Z - mouseProperties.ZAngOffset))
			* CFrame.new(characterProperties.LeftSideCamera and Vector3.new(-newCamOffsetX+1, cameraHeight, 0) or Vector3.new(newCamOffsetX-1, cameraHeight, 0)) 
			* CFrame.Angles((mouseProperties.Y + mouseProperties.YAngOffset),0, 0);

		if characterProperties.IsRagdoll and not characterProperties.CanAction then
			focusCf = focusCf * rootPart.CFrame.Rotation;

		end

		camera.Focus = focusCf;
		camera.CFrame = camera.Focus * CFrame.new(originOffset.X, originOffset.Y, tempzoom);

		local zoomCutoff = 0;
		if modData:IsMobile() then
		else
			zoomCutoff = camera:GetLargestCutoffDistance({CameraSubject.RootPart.Parent; CameraSubject.Vehicle;});
		end
		
		local newZoom = tempzoom-zoomCutoff;
		local newCameraCFrame = camera.Focus * CFrame.new(originOffset.X, originOffset.Y, newZoom);

		camera.CFrame = mouseProperties.CameraSmoothing == 0 and newCameraCFrame or oldCameraCFrame:lerp(newCameraCFrame, mouseProperties.CameraSmoothing);
		oldCameraCFrame = camera.CFrame;

		pcall(function()
			character.LeftUpperArm.LeftShoulder.C0 = originaldata.LeftShoulderC0;
			character.RightUpperArm.RightShoulder.C0 = originaldata.RightShoulderC0;

		end)

	elseif characterProperties.FirstPersonCamera then
		if CameraSubject.IsClientSubject and characterProperties.CanMove and characterProperties.IsAlive == true then

			if not characterProperties.IsSwimming 
				and not characterProperties.IsRagdoll 
				and humanoid.Sit ~= true 
				and characterProperties.InteractionActive == false
			then

				rootPart.CFrame = rootPoint;
			end
			characterProperties.BaseFieldOfView = 75;

			local hipHeight = 0;
			if characterProperties.IsCrouching or characterProperties.IsWounded then
				hipHeight = 2;
			elseif characterProperties.IsSliding then
				hipHeight = 2.5;
			end

			hipHeight = modMath.Lerp(prevHipHeight, hipHeight, 0.2);
			prevHipHeight = hipHeight;

			local cameraCFrame = rootPoint;

			if characterProperties.IsSwimming  then
				cameraCFrame = CFrame.new(collisionRootPart.CFrame.p + (collisionRootPart.CFrame.UpVector * collisionRootPart.Size.Y/2)) 
					* CFrame.Angles(0, (mouseProperties.X + mouseProperties.XAngOffset), 0);
			end

			cameraCFrame = cameraCFrame * CFrame.Angles(0, 0, (mouseProperties.Z - mouseProperties.ZAngOffset));	--Roll
			if not characterProperties.IsSwimming then
				cameraCFrame = cameraCFrame * CFrame.new(0, 2.4+0.6-prevHipHeight, 0)
			end

			cameraCFrame = cameraCFrame * CFrame.Angles((mouseProperties.Y + mouseProperties.YAngOffset)-(characterProperties.Joints.WaistX*0.01), 0, 0) --Pitch

			if characterProperties.IsRagdoll and not characterProperties.CanAction then
				cameraCFrame = cameraCFrame * head.CFrame.Rotation;

			end

			camera.CFrame = cameraCFrame * CFrame.new(cameraOriginOffset.X/2, cameraOriginOffset.Y/2, 0);
			camera.Focus = oldCameraCFrame;
			oldCameraCFrame = camera.CFrame;

			local s, e = pcall(function()
				local waistY = characterProperties.CanMove and characterProperties.Joints.WaistY or 0;
				if rootPart:GetAttribute("WaistY") then
					waistY = math.rad(rootPart:GetAttribute("WaistY") :: number);
				end
				local swayY = ((math.sin(tick())/2-0.5)/50 * characterProperties.SwayYStrength);

				local viewModel = characterProperties.UseViewModel and characterProperties.ViewModel or nil;

				if viewModel == nil and characterProperties.CustomViewModel then
					viewModel = character:GetAttribute("CustomViewModel") or characterProperties.CustomViewModel;
				end
				if viewModel == nil then
					viewModel = CFrame.new(0, -1, 0);
				end

				-- Having an attachment on the weapon for ADS does not work because of attachment cframe moving when adjusting pivot cframe.
				local viewModelWaistY = 0;

				local toolModule = modCharacter.EquippedToolModule;
				if toolModule and toolModule.Configurations then
					if characterProperties.AimDownSights then
						--Debugger:Warn("toolModule.Configurations.AimDownViewModel", toolModule.Configurations.AimDownViewModel);
						if toolModule.Configurations.AimDownViewModel then
							viewModel = toolModule.Configurations.AimDownViewModel;
						end
						if modCharacter.DevViewModel then
							viewModel = modCharacter.DevViewModel;
						end
						
					else
						if modCharacter.DevViewModel then
							viewModel = viewModel * modCharacter.DevViewModel;
						elseif toolModule.Configurations.HipFireViewModel then
							viewModel = viewModel * toolModule.Configurations.HipFireViewModel;
						end

						if toolModule.Class == "Weapon" then
							viewModelWaistY = vpWtY/10;
						else
							viewModelWaistY = vpWtY;
						end

					end
				end
			
				characterProperties.ViewModelPivot = viewModel
					* CFrame.Angles(characterProperties.ViewModelSwayPitch, -waistY+viewModelWaistY+characterProperties.ViewModelSwayYaw, characterProperties.ViewModelSwayRoll)
					+ Vector3.new(characterProperties.ViewModelSwayX, swayY + characterProperties.ViewModelSwayY, 0) 
					+ viewModel:VectorToObjectSpace(rootPart.CFrame:VectorToObjectSpace(rootPart.AssemblyLinearVelocity/200*characterProperties.VelocitySrength));


				if modData:IsMobile() then
					prevViewModel = characterProperties.ViewModelPivot;
				else
					prevViewModel = prevViewModel:lerp(characterProperties.ViewModelPivot, 0.2);
				end
				local viewModelPivot = cameraCFrame * prevViewModel;
				
				character.RightUpperArm.RightShoulder.C0 = upperTorso.CFrame:ToObjectSpace(viewModelPivot * CFrame.new(1.25, 0, 0));
				character.LeftUpperArm.LeftShoulder.C0 = upperTorso.CFrame:ToObjectSpace(viewModelPivot * CFrame.new(-1.25, 0, 0));

			end)
			if not s then
				if Cache.ViewModelErr == nil or tick()-Cache.ViewModelErr >= 0.5 then
					Cache.ViewModelErr = tick();
					Debugger:Warn("ViewModelErr",e);
				end
			end

		else --Spectating Mode
			if CameraSubject.IsClientSubject and characterProperties.EyeSightAttachment ~= nil then
				rootPart.CFrame = rootPoint;
				camera.CFrame = characterProperties.EyeSightAttachment.WorldCFrame * CFrame.new(cameraOriginOffset.X/5, cameraOriginOffset.Y/5, 0);
				camera.Focus = oldCameraCFrame;
				oldCameraCFrame = camera.CFrame;
				--if characterProperties.EyeSightAttachment ~= nil then
				--end

			else
				if CameraSubject.Head then
					
					characterProperties.BaseFieldOfView = 75;
					camera.CFrame = characterProperties.FirstPersonCamCFrame or CameraSubject.Head.CFrame * CFrame.new(cameraOriginOffset.X/5, cameraOriginOffset.Y/5, 0);
					camera.Focus = oldCameraCFrame;
					oldCameraCFrame = camera.CFrame;
				end
			end
		end
	end

	local mouseDelta = UserInputService:GetMouseDelta();

	local swayRatio = characterProperties.MoveSpeed/20 * (characterProperties.IsFocused and 0.1 or 1);
	characterProperties.ViewModelSwayY = swayRatio* math.sin(tick()*(characterProperties.IsWalking and 10 or 20))/20;
	characterProperties.ViewModelSwayX = swayRatio* math.sin(tick()*(characterProperties.IsWalking and 5 or 10))/10;

	characterProperties.ViewModelSwayRoll = math.rad(math.clamp(-mouseDelta.X * (characterProperties.IsFocused and 0 or 0.5), -2.5, 2.5));
	characterProperties.ViewModelSwayPitch = math.rad(math.clamp(mouseDelta.Y * (characterProperties.IsFocused and 0.05 or 0.5), -5, 5));
	characterProperties.ViewModelSwayYaw = math.rad(math.clamp(mouseDelta.X * (characterProperties.IsFocused and 0.05 or 0.5), -2.5, 2.5));

	characterProperties.ViewModelSwayX = modMath.Lerp(characterProperties.ViewModelSwayX, 0, 0.1);
	characterProperties.ViewModelSwayY = modMath.Lerp(characterProperties.ViewModelSwayY, 0, 0.1);
	characterProperties.ViewModelSwayRoll = modMath.Lerp(characterProperties.ViewModelSwayRoll, 0, 0.1);
	characterProperties.ViewModelSwayPitch = modMath.Lerp(characterProperties.ViewModelSwayPitch, 0, 0.1);
	characterProperties.ViewModelSwayYaw = modMath.Lerp(characterProperties.ViewModelSwayYaw, 0, 0.1);
	
end 

modCameraGraphics:Bind("default", {
	RenderStepped = renderStepped;
	CameraType = Enum.CameraType.Scriptable;
});


local dynamicPlatformCframe, dynamicPlatformModel;
local lastPlatformChange = tick();
local platformChange, groundChange;

local groundRayParam = RaycastParams.new();
groundRayParam.IgnoreWater = true;
groundRayParam.FilterType = Enum.RaycastFilterType.Include;

local function resetCameraEffects()
	if modData.Blur then
		modData.Blur.Size = 2;
	end
end
resetCameraEffects();

RunService.Stepped:Connect(function(total, delta)
	characterProperties.IsAlive = character:GetAttribute("IsAlive") == true;

	local rootCframe = rootPart.CFrame;
	
	if characterProperties.IsAlive then
		local activeBodyForce = characterProperties.BodyForce:Get();
		if activeBodyForce then
			charBodyForce.Enabled = true;
			charBodyForce.Force = activeBodyForce + Vector3.new(0, workspace.Gravity * rootPart.AssemblyMass, 0);
		else
			charBodyForce.Enabled = false;
		end
	else
		charBodyForce.Enabled = false;
	end

	local rayDir = Vector3.new(0, -16, 0);
	
	local feetY = rootCframe.p.Y-2
	
	groundRayParam.FilterDescendantsInstances = environmentCollidable;
	
	local groundResult: RaycastResult = nil;
	local groundHit = nil;
	local closestDist = math.huge;

	if modData:IsMobile() then
		local hitResult = workspace:Raycast(rootPart.Position, rayDir, groundRayParam);
		if hitResult and hitResult.Instance then
			groundResult = hitResult;

			groundHit = hitResult.Instance;
			closestDist = hitResult.Distance;
		end

	else
		local results = modRaycastUtil.EdgeCast(rootPart, rayDir, groundRayParam);
		
		for a=1, #results do
			local pos = results[a].Position;
			local yDist = math.abs(pos.Y - feetY)
			
			if yDist < closestDist then
				groundResult = results[a];
				closestDist = yDist;
			end
		end
		
		groundHit = #results > 0 and groundResult.Instance or nil;
	end
	
	characterProperties.GroundObject = groundHit;
	if groundHit and closestDist > 3 then
		characterProperties.GroundObject = nil;
	end
	
	if groundResult then
		characterProperties.GroundPoint = Vector3.new(rootPart.Position.X, groundResult.Position.Y, rootPart.Position.Z);
		characterProperties.GroundNormal = groundResult.Normal;
	else
		characterProperties.GroundPoint = nil;
		characterProperties.GroundNormal = Vector3.yAxis;
	end
	
	if groundHit and not groundHit:IsA("Terrain") then
		local rootModel = groundHit.Parent;

		while rootModel:GetAttribute("DynamicPlatform") == nil do
			rootModel = rootModel.Parent;
			if rootModel == workspace then break; end
		end

		if rootModel:GetAttribute("DynamicPlatform") then
			local modelCf = rootModel:GetPivot();
			
			if dynamicPlatformCframe == nil or dynamicPlatformModel ~= rootModel then
				dynamicPlatformCframe = modelCf;
			end
			
			dynamicPlatformModel = rootModel;
			lastPlatformChange = tick();
		end
	end
	
	if (tick()-lastPlatformChange) > 0.3 then
		dynamicPlatformCframe = nil;
		dynamicPlatformModel = nil;
		characterProperties.DynamicPlatformVelocity = Vector3.zero;
		
	else
		if dynamicPlatformModel and dynamicPlatformCframe and dynamicPlatformModel:IsDescendantOf(workspace) then
			local newCf = dynamicPlatformModel:GetPivot();
			local cfChange = newCf * dynamicPlatformCframe:Inverse();
			
			local xC = math.atan2(-cfChange.LookVector.Z, cfChange.LookVector.X) - halfPi;
			mouseProperties.X = mouseProperties.X + xC;
			
			dynamicPlatformCframe = newCf;
			
			if dynamicPlatformModel and dynamicPlatformModel.PrimaryPart and dynamicPlatformModel.PrimaryPart.Anchored then
				rootPart.CFrame = cfChange * rootCframe;
			elseif humanoid.FloorMaterial == Enum.Material.Air or humanoid.Jump == true then
				rootPart.CFrame = cfChange * rootCframe;
			end
			
			characterProperties.DynamicPlatformVelocity = (rootCframe.Position - rootPart.CFrame.Position);
		end
		
	end
	
	if platformChange ~= dynamicPlatformModel and groundChange ~= characterProperties.GroundObject then
		platformChange = dynamicPlatformModel;
		groundChange = characterProperties.GroundObject;
		
		remoteCharacterRemote:FireServer(2, {dynamicPlatformModel, characterProperties.GroundObject});
		
	elseif platformChange ~= dynamicPlatformModel then
		platformChange = dynamicPlatformModel;
		
		remoteCharacterRemote:FireServer(2, {dynamicPlatformModel, characterProperties.GroundObject});
		
	elseif groundChange ~= characterProperties.GroundObject then
		groundChange = characterProperties.GroundObject;
		
		remoteCharacterRemote:FireServer(2, {dynamicPlatformModel, characterProperties.GroundObject});
		
	end
	
	
	if classPlayer and classPlayer.Properties then
		characterProperties.UnderwaterVision = classPlayer:GetBodyEquipment("UnderwaterVision") or 0.01;
		characterProperties.SwimSpeed = classPlayer:GetBodyEquipment("SwimmingSpeed") or characterProperties.DefaultSwimSpeed;
		characterProperties.SprintSpeed = classPlayer:GetBodyEquipment("SprintingSpeed") or characterProperties.DefaultSprintSpeed;
		
		local isKnockedOut = classPlayer.Properties.KnockedOut ~= nil;
		if isKnockedOut then
			if characterProperties.IsKnockedOut ~= isKnockedOut then
				characterProperties.IsKnockedOut = isKnockedOut;
				
				if modData.Blur then
					modData.Blur.Size = 10;
				end


				modCameraGraphics.Saturation:Set("knockedout", -1, 3);
				modCameraGraphics.Brightness:Set("knockedout", -0.1, 3);
				modCameraGraphics.Contrast:Set("knockedout", 0.1, 3);
				
				characterMoving(0);
			end
			
		else
			if characterProperties.IsKnockedOut ~= isKnockedOut then
				characterProperties.IsKnockedOut = isKnockedOut;

				modCameraGraphics.Saturation:Remove("knockedout", -1, 3);
				modCameraGraphics.Brightness:Remove("knockedout", -0.1, 3);
				modCameraGraphics.Contrast:Remove("knockedout", 0.1, 3);
				
				characterMoving(0);
			end
			
		end
	end 
	
	local s = pcall(function()
		local camPos = currentCamera.CFrame.Position;
		local readTerrain = (workspace.Terrain:ReadVoxels(Region3.new(camPos, camPos):ExpandToGrid(4), 4));
		local terrainMat = readTerrain[1] and readTerrain[1][1] and readTerrain[1][1][1];
		if terrainMat and terrainMat == Enum.Material.Water then
			characterProperties.CamUnderwater = true;
		else
			characterProperties.CamUnderwater = false;
		end
	end)
	if not s then
		characterProperties.CamUnderwater = false;
	end
	--Anim debug
	--local animationTracks = animator:GetPlayingAnimationTracks();
	--local animationNames = {};
	--for k,v in pairs(animationTracks) do
	--	animationNames[tostring(k)] = tostring(v);
	--end
	--Debugger:Display(animationNames);
end)

local lastMovablePos = rootPart.CFrame;
local unstuckPos = rootPart.CFrame;
local ragdollActive = true;

Cache.OneSecTick = tick();
Cache.LowestFps = math.huge;

local stepBuffer = 0;
-- MARK: PreSimulation;
RunService.PreSimulation:Connect(function(step)
	if not characterProperties.IsAlive then return end;

	if stepBuffer >0 then 
		stepBuffer = math.max(stepBuffer-1, 0); 

		if characterProperties.AllowLerpBody then
			pcall(function()
				local neckTransform = head.Neck.Transform;
				local waistTransform: CFrame = character.UpperTorso.Waist.Transform;

				if characterProperties.IsSliding then
					-- sliding
					waistTransform = CFrame.new();
					
				elseif characterProperties.IsCrouching then
					-- crouching
					waistTransform = CFrame.new();
				end

				head.Neck.Transform = neckTransform * Cache.NeckC0;
				character.UpperTorso.Waist.Transform = waistTransform * Cache.WaistC0;
			end)
		end

		return; 
	end;

	local motionStepBuffer = modData:GetSetting("MotionStepBuffer");
	if motionStepBuffer and motionStepBuffer > 1 then
		stepBuffer = motionStepBuffer;
		step = step *motionStepBuffer;
	end

	local beatTick = tick();
	local submitMotorUpdates = (beatTick-motorUpdateCooldown) > 0.5 and characterProperties.IsAlive;
	
	local bodyBuffer = submitMotorUpdates and buffer.create(12) or nil;

	if characterProperties.AllowLerpBody then
		local lerpS, lerpE = pcall(function()
			local neckTransform = head.Neck.Transform;
			local waistTransform = character.UpperTorso.Waist.Transform;
			local _, wtY, _ = waistTransform:ToEulerAnglesXYZ();
			vpWtY = wtY;

			local waistC0 = {X=0; Y=0; Z=0;};
			local waistC1 = {X=0; Y=0; Z=0;};

			local cameraDirection = rootPart.CFrame:VectorToObjectSpace(currentCamera.CFrame.lookVector)
			local camLookYaw = mathAtan2(cameraDirection.X, -cameraDirection.Z); 
			if camLookYaw > 2 or camLookYaw < -2 then 
				camLookYaw = mathAtan2(cameraDirection.X, cameraDirection.Z) 
			end;
			local neckPitchOffset = -0.2;
			
			local waistY = characterProperties.CanMove and characterProperties.Joints.WaistY or 0;
			
			local mouseY = (mouseProperties.Y + mouseProperties.YAngOffset);
			if not characterProperties.CanMove then 
				mouseY = -0.12;
			end;
			
			if characterProperties.IsEquipped and characterProperties.ThirdPersonCamera then
				local toolModule = modCharacter.EquippedToolModule;

				if toolModule and toolModule.Configurations and toolModule.Configurations.ThirdPersonWaistOffset then
					waistY = waistY + toolModule.Configurations.ThirdPersonWaistOffset * (characterProperties.LeftSideCamera and -1 or 1);
				end
				
				local waistZ = characterProperties.CanMove and characterProperties.Joints.WaistZ or 0;
				waistC0.Z = waistZ;
			end
			
			local rootCFrame = rootPart.CFrame;
			local wallCollisionRay, wallRayHit, wallRayEnd;
			if modData:IsMobile() or Debugger.ClientFps <= 30 then

			else
				wallCollisionRay = Ray.new(rootCFrame.Position, rootCFrame.LookVector * (mouseY >0 and -6 or 6));
				wallRayHit, wallRayEnd = workspace:FindPartOnRayWithWhitelist(wallCollisionRay, environmentOnly, true);
			end

			if wallRayHit then
				local dist = (wallRayEnd-rootCFrame.Position).Magnitude;
				
				local rotRatio = dist/6;
				mouseY = mouseY * rotRatio;
			end
			
			if characterProperties.FirstPersonCamera and not characterProperties.CanMove then
				camLookYaw = 0;
			end
			if characterProperties.IsSwimming then
				mouseY = 0;
			end

			if characterProperties.IsRagdoll and not Cache.AntiGravityForce then
				-- ragdolling
				
			elseif characterProperties.IsWounded then
				-- crawling
				
			elseif characterProperties.IsSliding then
				-- sliding
				waistC1.X = deg60;
				waistC1.Y = waistY - wtY;
				waistTransform = CFrame.new();
				
			elseif characterProperties.IsCrouching then
				-- crouching
				waistC1.X = characterProperties.IsEquipped and 0 or deg45;
				waistC1.Y = waistY - wtY;

				waistC0.X = mathClamp(mouseY, -0.7, 0.7);

				waistTransform = CFrame.new();
				neckPitchOffset = characterProperties.IsEquipped and 0 or -deg45;


			else 
				-- idle
				waistC1.Y = waistY;
				waistC0.X = mathClamp(mouseY, -1, 1.1);

			end
			if humanoid.PlatformStand == true then
				waistC1.Y = waistY;
			end
			-- WaistY = Left/Right
			-- WaistX = Front/Back
			
			local waistC0Cf = CFrame.Angles(waistC0.X, 0, 0);
			local waistC1Cf = CFrame.Angles(0, waistC1.Y, 0) * CFrame.Angles(waistC1.X, 0, 0);

			if submitMotorUpdates then
				buffer.writei16(bodyBuffer, 0, math.round(waistC0.X*100));
				buffer.writei16(bodyBuffer, 2, math.round(waistC0.Z*100));
				buffer.writei16(bodyBuffer, 4, math.round(waistC1.Y*100));
				buffer.writei16(bodyBuffer, 6, math.round(waistC1.X*100));
			end
			
			if character.UpperTorso.Waist then
				if characterProperties.FirstPersonCamera and not characterProperties.IsRagdoll then
					-- First Person & not ragdoll
					prevdata.WaistC1 = prevdata.WaistC1:lerp(CFrame.new(originaldata.WaistC1.p) * waistC1Cf, 0.1);

					local viewModelHeight = modMath.Lerp(prevViewModelHeight, characterProperties.IsSliding and 2.1 or characterProperties.IsCrouching and 1.1 or -0.4, 0.15);
					prevViewModelHeight = viewModelHeight;
					
					local waistToCamCFrame = (rootPart.CFrame * CFrame.new(0, -viewModelHeight, 0)):ToObjectSpace(
						CFrame.new(character.LowerTorso.CFrame.p)* CFrame.new(originaldata.WaistC1.p) -- math.rad(rootPart.Orientation.Y)  * CFrame.Angles(0, wtY, 0) 
					);
					if characterProperties.IsWounded then
						character.UpperTorso.Waist.C1 = waistToCamCFrame;
						
					else
						character.UpperTorso.Waist.C1 = waistToCamCFrame;
						character.UpperTorso.Waist.Transform = waistC0Cf;

					end
					
				else
					-- Third Person Mode

					-- Apply C1
					character.UpperTorso.Waist.C1 = prevdata.WaistC1:lerp(CFrame.new(originaldata.WaistC1.p) * waistC1Cf, 0.1);
					prevdata.WaistC1 = character.UpperTorso.Waist.C1;
					
					-- Apply C0
					Cache.WaistC0 = (Cache.WaistC0 or waistC0Cf):Lerp(waistC0Cf, 0.1);
					character.UpperTorso.Waist.Transform = waistTransform * (Cache.WaistC0 * CFrame.Angles(0, 0, waistC0.Z));

				end
			end
			
			local neckC0 = {X=0; Y=0; Z=0;};
			local neckC1 = {X=0; Y=0; Z=0;};

			neckC0.Y = math.clamp(-camLookYaw +waistY, -1, 1);
			neckC1.X = math.clamp(-mouseY, -0.5, 0.4) + neckPitchOffset;

			local neckC0Cf = CFrame.Angles(0, neckC0.Y, 0);
			local neckC1Cf = CFrame.Angles(neckC1.X, wtY, 0);
			
			if submitMotorUpdates then
				buffer.writei16(bodyBuffer, 8, math.round(neckC0.Y*100));
				buffer.writei16(bodyBuffer, 10, math.round(neckC1.X*100));
			end

			if character.Head then
				-- Apply C1
				head.Neck.C1 = prevdata.NeckC1:lerp(CFrame.new(originaldata.NeckC1.p) * neckC1Cf, 0.1);
				prevdata.NeckC1 = head.Neck.C1;

				-- Apply C0
				Cache.NeckC0 = (Cache.NeckC0 or neckC0Cf):Lerp(neckC0Cf, 0.1);
				head.Neck.Transform = neckTransform * Cache.NeckC0;
				
			end
		end)

		if not lerpS and RunService:IsStudio() then 
			warn(lerpE) 
		end;

	else
		character.UpperTorso.Waist.C1 = originaldata.WaistC1;
		if character.Head then
			head.Neck.C0 = originaldata.NeckC0;
		end
	end
	
	if submitMotorUpdates then
		motorUpdateCooldown = beatTick;
		
		local tickFps = Debugger.ClientFps;
		local newLowestFps = nil;
		if tickFps < Cache.LowestFps then
			Cache.LowestFps = tickFps;
			newLowestFps = tickFps;
		end
		Cache.AvgFps = math.round(((Cache.AvgFps or tickFps) + tickFps)/2);
	
		remoteCharacterRemote:FireServer(1, {
			LowestFps=newLowestFps;
			AvgFps=Cache.AvgFps;
			B=bodyBuffer;
		})
	end
	
end)

-- MARK: PostSimulation;
RunService.PostSimulation:Connect(function(step)
	local beatTick = tick();
	loadInterface();
	if modCharacter.CharacterProperties.CharacterCameraEnabled ~= isCharCamEnabled then
		isCharCamEnabled = modCharacter.CharacterProperties.CharacterCameraEnabled;
		characterProperties.RefreshTransparency = true;
	end
	
	mouseProperties.XAngOffset = modMath.Lerp(mouseProperties.XAngOffset, 0,  math.clamp( (mouseProperties.XAngOffset/1)*0.3 , 0.05, 0.3) );
	mouseProperties.YAngOffset = modMath.Lerp(mouseProperties.YAngOffset, 0, math.clamp( (mouseProperties.YAngOffset/1)*0.3 , 0.05, 0.3) );
	mouseProperties.ZAngOffset = modMath.Lerp(mouseProperties.ZAngOffset, 0, math.clamp( (mouseProperties.ZAngOffset/1)*0.3 , 0.05, 0.3) );
	if math.abs(mouseProperties.XAngOffset) < 0.001 then mouseProperties.XAngOffset = 0 end;
	if math.abs(mouseProperties.YAngOffset) < 0.001 then mouseProperties.YAngOffset = 0 end;
	if math.abs(mouseProperties.ZAngOffset) < 0.001 then mouseProperties.ZAngOffset = 0 end;
	
	mouseProperties.FlinchInacc = modMath.Lerp(mouseProperties.FlinchInacc, 0, 0.05);
	if math.abs(mouseProperties.FlinchInacc) < 0.1 then mouseProperties.FlinchInacc = 0 end;
	
	
	local motorHeadA = character.LowerTorso.CFrame 
		* CFrame.new(0, 0.38, 0)
		* character.UpperTorso.Waist.C0 
		* Cache.WaistC0;
	local motorHeadB = character.UpperTorso.Waist.C1:Inverse() 
		* character.Head.Neck.C0 
		* Cache.NeckC0
		* character.Head.Neck.C1:Inverse();
	characterProperties.MotorHeadCFrameA = motorHeadA;
	characterProperties.MotorHeadCFrameB = motorHeadB;


	if beatTick-Cache.OneSecTick >= 1 then
		Cache.OneSecTick = beatTick;
		
		local newState = humanoid:GetState();
		if Cache.OldState == nil then
			Cache.OldState = newState;
		end
		onHumanoidStateChanged(Cache.OldState, newState);
		Cache.OldState = newState;
	end
	
	if not characterProperties.IsAlive then
		if mouseProperties.Mouse2Down then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
			
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
			mouseProperties.MouseLocked = false;
		end
		
	elseif EditModeTag and mouseProperties.Mouse2Down then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
		
	elseif mouseProperties.MouseLocked or mouseProperties.Mouse2Down then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
		
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
		
	end
	
	if Cache.StopSwimmingTimer then
		if beatTick-Cache.StopSwimmingTimer >= 0.6 then
			if characterProperties.IsSwimming ~= true then -- no longer swimming
				remoteCharacterRemote:FireServer(4, false);
				Cache.StopSwimmingTimer = nil;
			end
		end
	end
	
	if mainInterface and mainInterface.Parent then
		if not mouseProperties.MouseLocked and mouseProperties.Mouse2Down then
			mainInterface.Crosshair.Visible = true;
			UserInputService.MouseIconEnabled = false;
			
		elseif not mouseProperties.MouseLocked then
			UserInputService.MouseIconEnabled = true;
			mainInterface.Crosshair.Visible = false;
			
		elseif characterProperties.IsEquipped then
				mainInterface.Crosshair.Visible = not characterProperties.HideCrosshair;
			
			if not mouseProperties.MouseLocked then
				UserInputService.MouseIconEnabled = true;
			else
				UserInputService.MouseIconEnabled = false;
			end
			
		else
			mainInterface.Crosshair.Visible = true;
			UserInputService.MouseIconEnabled = false;
			
		end
	end
	
	
	if not characterProperties.CanMove then
		stopSliding();
		characterProperties.IsCrouching = false;
		characterProperties.IsWalking = false;
		characterProperties.IsSprinting = false;
	end

	if Cache.CameraSubjectUpdated then
		Cache.CameraSubjectUpdated = nil;
		
		if CameraSubject.IsClientSubject then
			modCameraGraphics.Saturation:Remove("spectate");
			modCameraGraphics.TintColor:Remove("spectate");

		else
			modCameraGraphics.Saturation:Set("spectate", -0.5, 2);
			modCameraGraphics.TintColor:Set("spectate", Color3.fromRGB(255, 224, 224), 2);

		end
	end

	if CameraSubject.IsClientSubject then
		mouseProperties.Focus = currentCamera.Focus;
		local mousePosition = UserInputService:GetMouseLocation();
		
		if characterProperties.IsEquipped then
			local pointRay = currentCamera:ViewportPointToRay(currentCamera.ViewportSize.X/2, currentCamera.ViewportSize.Y/2);
			mouseProperties.Direction = pointRay.Direction;
			
		elseif not mouseEnabled or mouseProperties.MouseLocked then
			--pointRay = camera:ViewportPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2);
			mouseProperties.Direction = (mouseProperties.Focus.p - currentCamera.CFrame.p).unit;
			
		else
			local pointRay = currentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y);
			local _, rayPoint = workspace:FindPartOnRayWithWhitelist(Ray.new(pointRay.Origin, pointRay.Direction*128), environmentOnly, true);
			mouseProperties.Direction = (rayPoint - mouseProperties.Focus.p).unit;
			
		end

		if characterProperties.ActionKeySpaceDown or humanoid.Jump == true then
			characterProperties.HumanStates[Enum.HumanoidStateType.GettingUp] = true;
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true);
			if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
		
		characterProperties.PlayerVelocity = rootPart.AssemblyLinearVelocity.Magnitude;

		if characterProperties.PlayerVelocity >= 100 then
			remoteCharacterRemote:FireServer(5, characterProperties.PlayerVelocity);
		end
		
		local collisionModelId = "Default";

		if characterProperties.IsRagdoll then
			animations["crouchIdle"]:Stop();
			animations["woundedIdle"]:Stop();
			animations["crouchWalk"]:Stop();
			animations["woundedWalk"]:Stop();
			if characterProperties.IsSliding then
				stopSliding();
			end
			
		elseif characterProperties.IsWounded then
			
			if not animations["woundedWalk"].IsPlaying then
				animations["woundedIdle"]:Play();
			end

			characterProperties.WalkSpeed:Set("default", modMath.Lerp(characterProperties.NewWalkSpeed, characterProperties.WoundedSpeed, 0.6));
			characterProperties.NewWalkSpeed = humanoid.WalkSpeed;
			collisionModelId = "Wounded";
			if characterProperties.IsSliding then
				stopSliding();
			end
			
		elseif characterProperties.IsSliding then -- MARK: PostSimulation IsSliding
			if animations["slide"] then animations["slide"]:Play(); end
			characterProperties.WalkSpeed:Set("default", 0);
			
			if not humanoid.Sit and not humanoid.PlatformStand and not humanoid.Jump then
				slideForce.MaxForce = Vector3.new(40000, 0, 40000);
				
				local rootLookVector = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z).Unit;
				local newSlideDirection = rootLookVector;
				
				local slideMomentum = oldSlideMomentum;

				local slopeDot = newSlideDirection:Dot(characterProperties.GroundNormal);

				if slopeDot > 0.1 then
					slideMomentum = math.min(slideMomentum + slopeDot/slopeDownFriction, characterProperties.SlideSpeed*1.5);
				else
					slideMomentum = slideMomentum - math.max(math.abs(slopeDot), 0.25) *slopeUpFriction;
				end

				slideForce.Velocity = newSlideDirection*math.max(slideMomentum, 0);
				slideDirection = newSlideDirection;

				oldSlideMomentum = slideMomentum;
				
				if Cache.lastSlide == nil then
					Cache.lastSlide = beatTick;
				end
			end
			characterProperties.SlideVelocity = slideForce.Velocity;
			
			if characterProperties.State == Enum.HumanoidStateType.FallingDown
				or Cache.lastSlide == nil
				or (rootPart.AssemblyLinearVelocity*Vector3.new(1, 0, 1)).Magnitude <= 5 
				or humanoid.Sit 
				or humanoid.PlatformStand 
				or not characterProperties.IsAlive then

				stopSliding();
			end
			
			collisionModelId = "Crouch";
			
		elseif characterProperties.IsSwimming then
			
			animations["crouchIdle"]:Stop();
			animations["crouchWalk"]:Stop();
			characterProperties.IsCrouching = false;
			
			characterProperties.WalkSpeed:Set("default", modMath.Lerp(characterProperties.NewWalkSpeed, characterProperties.SwimSpeed, 0.6));
			characterProperties.NewWalkSpeed = humanoid.WalkSpeed;
			collisionModelId = "Swimming";
			
		else
			animations["woundedIdle"]:Stop();
			
			if characterProperties.CustomWalkSpeed then
				characterProperties.WalkSpeed:Set("custom", modMath.Lerp(characterProperties.NewWalkSpeed, characterProperties.CustomWalkSpeed, 0.6), 1);
				characterProperties.NewWalkSpeed = humanoid.WalkSpeed;
				animations["crouchIdle"]:Stop();
			else
				characterProperties.WalkSpeed:Remove("custom");
			end
			
			local adsMulti = characterProperties.AdsWalkSpeedMultiplier or 1;
			
			if characterProperties.IsCrouching then
				collisionModelId = "Crouch";
				characterProperties.WalkSpeed:Set("default", modMath.Lerp(characterProperties.NewWalkSpeed, characterProperties.CrouchSpeed * adsMulti, 0.6));
				characterProperties.NewWalkSpeed = humanoid.WalkSpeed;
				if not characterProperties.CrouchKeyDown then crouchToggleCheck(rootPart.CFrame, true); end
				
				if not animations["crouchWalk"].IsPlaying then
					animations["crouchIdle"]:Play();
				end
				
			elseif characterProperties.IsWalking then
				characterProperties.WalkSpeed:Set("default", modMath.Lerp(characterProperties.NewWalkSpeed, characterProperties.WalkingSpeed * adsMulti, 0.6));
				characterProperties.NewWalkSpeed = humanoid.WalkSpeed;
				animations["crouchIdle"]:Stop();
				animations["crouchWalk"]:Stop();
				
			elseif characterProperties.IsSprinting then
				characterProperties.WalkSpeed:Set("default", modMath.Lerp(characterProperties.NewWalkSpeed, characterProperties.SprintSpeed * adsMulti, 0.6));
				characterProperties.NewWalkSpeed = humanoid.WalkSpeed;
				animations["crouchIdle"]:Stop();
				animations["crouchWalk"]:Stop();
				
			else
				characterProperties.WalkSpeed:Set("default", modMath.Lerp(characterProperties.NewWalkSpeed, characterProperties.DefaultWalkSpeed * adsMulti, 0.6));
				characterProperties.NewWalkSpeed = humanoid.WalkSpeed;
				animations["crouchIdle"]:Stop();
				animations["crouchWalk"]:Stop();
			end
		end
		
		if characterProperties.IsSwimming then
			local _swimSpeed = (characterProperties.SwimSpeed or 12);
			if not characterProperties.ActionKeySpaceDown and characterProperties.ActionKeyCtrlDown and rootPart.AssemblyLinearVelocity.Y > -12 then
				rootPart:ApplyImpulse(Vector3.new(0, -25, 0));
				
			end
			
			if characterProperties.HeadUnderwater then
				if not characterProperties.ActionKeyCtrlDown and characterProperties.ActionKeySpaceDown and rootPart.AssemblyLinearVelocity.Y < 12 then
					rootPart:ApplyImpulse(Vector3.new(0, 25, 0));
				end
				
				if characterProperties.ActionKeySpaceDown then
					Cache.ActiveJumpPressCount = Cache.JumpPressCount;
				end
				
				characterProperties.JumpPower:Set("swimming", 0, 2);
				
			else
				if Cache.ActiveJumpPressCount == nil or Cache.JumpPressCount > Cache.ActiveJumpPressCount then
					characterProperties.JumpPower:Set("swimming", 60, 2);
				end
				
			end
			
			if classPlayer:GetBodyEquipment("FloatOnWater") == true then
				rootPart.CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.5, 1, 0.3, 1);
			else
				rootPart.CustomPhysicalProperties = PhysicalProperties.new(1.1, 0.5, 1, 0.3, 1);
			end
		else
			rootPart.CustomPhysicalProperties = PhysicalProperties.new(1.1, 0.5, 1, 0.3, 1);
			characterProperties.JumpPower:Remove("swimming");
		end
		
		if Cache.AntiGravityForce then
			collisionModelId = "AntiGravity";
		end
		if characterProperties.IsAlive then
			local collisionModel = CollisionModel[collisionModelId];
			
			local collisionSize = character:GetAttribute("CollisionSize") or collisionModel.Size;
			local collisionC0 = character:GetAttribute("CollisionC0") and CFrame.new(character:GetAttribute("CollisionC0")) or collisionModel.C0;
			
			collisionRootPart.Size = collisionSize;
			collisionRootMotor.C0 = collisionC0;
			-- collisionRootPart.Size = collisionRootPart.Size:Lerp(collisionSize, 0.5);
			-- collisionRootMotor.C0 = collisionRootMotor.C0:Lerp(collisionC0, 0.5);
			
		else
			collisionRootPart.Size = Vector3.new(2, 2, 1);
			
		end
		
		modCharacter.UpdateWalkSpeed();

		if characterProperties.Ragdoll == true then
			if ragdollActive == false then
				ragdollActive = true;
			end
			
		else
			if ragdollActive == true then
				ragdollActive = false;
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp);
			end

		end
		
	end
	
	if CameraSubject.Character then
		if zoom < minZoomLevel then
			if currentThirdPerson then
				characterProperties.ThirdPersonCamera = false;
				characterProperties.FirstPersonCamera = true;
				characterProperties.BodyLockToCam = true;
				
				local bodyParts = CameraSubject.Character:GetDescendants();
				
				if characterProperties.IsEquipped or characterProperties.CharacterInteracting then
					ToggleBodypartTransparency(bodyParts, true, false);
				else
					ToggleBodypartTransparency(bodyParts, true, true);
				end
				currentThirdPerson = false;
				localPlayer:SetAttribute("IsFirstPerson", true);

				if characterProperties.IsAlive then
					character.UpperTorso.Waist.C1 = originaldata.WaistC1;
					if character.Head then
						head.Neck.C0 = originaldata.NeckC0;
					end
					
				end;
				
			end
		else
			if not currentThirdPerson then
				characterProperties.ThirdPersonCamera = true;
				characterProperties.FirstPersonCamera = false;
				characterProperties.BodyLockToCam = false;
				local bodyParts = CameraSubject.Character:GetDescendants();
				ToggleBodypartTransparency(bodyParts, false, false);
				currentThirdPerson = true;
				localPlayer:SetAttribute("IsFirstPerson", false);
			end
		end;
		
		if previouslyEquipped ~= characterProperties.IsEquipped 
			or prevCharInteracting ~= characterProperties.CharacterInteracting
			or characterProperties.RefreshTransparency then
			
			local bodyParts = CameraSubject.Character:GetDescendants();
			if characterProperties.FirstPersonCamera and isCharCamEnabled then
				if characterProperties.IsEquipped or characterProperties.CharacterInteracting then
					ToggleBodypartTransparency(bodyParts, true);
				else
					ToggleBodypartTransparency(bodyParts, true, true);
				end
			else
				ToggleBodypartTransparency(bodyParts, false);
				characterProperties.BodyLockToCam = false;
			end
			
			characterProperties.RefreshTransparency = false;
			previouslyEquipped = characterProperties.IsEquipped;
			prevCharInteracting = characterProperties.CharacterInteracting;
		end
	end
	
	if characterProperties.IsSwimming then
		local s = pcall(function()
			local headPos = head.Position + Vector3.new(0, 1, 0);
			local readTerrain = (workspace.Terrain:ReadVoxels(Region3.new(headPos, headPos):ExpandToGrid(4), 4));
			local terrainMat = readTerrain[1] and readTerrain[1][1] and readTerrain[1][1][1];
			if terrainMat and terrainMat == Enum.Material.Water then
				characterProperties.HeadUnderwater = true;
			else
				characterProperties.HeadUnderwater = false;
			end
		end)
		if not s then
			characterProperties.HeadUnderwater = false;
		end
		
		if characterProperties.HeadUnderwater then
			game.SoundService.AmbientReverb = Enum.ReverbType.UnderWater;
			if workspace.Terrain:GetAttribute("DefaultWaterTransparency") == nil then
				workspace.Terrain:SetAttribute("DefaultWaterTransparency", workspace.Terrain.WaterTransparency);
			end
			
			workspace.Terrain.WaterTransparency = modMath.Lerp(Cache.OldTerrainWaterTransparency, characterProperties.UnderwaterVision or 0.01, 0.1);
			Cache.OldTerrainWaterTransparency = workspace.Terrain.WaterTransparency;
			
		else
			game.SoundService.AmbientReverb = characterProperties.AmbientReverb:Get();
			
			workspace.Terrain.WaterTransparency = modMath.Lerp(Cache.OldTerrainWaterTransparency, workspace.Terrain:GetAttribute("DefaultWaterTransparency") or 0.3, 0.1);
			Cache.OldTerrainWaterTransparency = workspace.Terrain.WaterTransparency;
			
		end
	else
		game.SoundService.AmbientReverb = characterProperties.AmbientReverb:Get();

		if Cache.OldTerrainWaterTransparency then
			workspace.Terrain.WaterTransparency = modMath.Lerp(Cache.OldTerrainWaterTransparency, workspace.Terrain:GetAttribute("DefaultWaterTransparency") or 0.3, 0.1);
			Cache.OldTerrainWaterTransparency = workspace.Terrain.WaterTransparency;
			
		end
		
	end

	local floorPart = characterProperties.GroundObject;
	if floorPart then
		local surfaceType = floorPart:GetAttribute("SurfaceType")
		
		walkSurfaceTag.Value = surfaceType or "";
		
		if surfaceType == "Slippery" then
			local vec = Vector3.new(math.sin(beatTick), 0, math.cos(beatTick)) * 200;
			
			rootPart:ApplyImpulse(vec);
		end
		
	else
		walkSurfaceTag.Value = "";
	end
	
	if beatTick-heartbeatSecTick >= 1 then
		heartbeatSecTick = beatTick;
		
		if (rootPart.CFrame.Position-lastMovablePos.p).Magnitude >= 16 then
			unstuckPos = lastMovablePos;
			lastMovablePos = rootPart.CFrame;
			
			if modData.UnstuckCharacter == nil then
				modData.UnstuckCharacter = function()
					rootPart.CFrame = unstuckPos;
				end
			end
		end
	end
	
	if Cache.AntiGravityForce then
		local gravity = Cache.AntiGravityForce:GetAttribute("Gravity") or workspace.Gravity;
		Cache.AntiGravityForce.Force = (Vector3.yAxis * gravity * rootPart:GetMass());
	end
	
	if touchEnabled and mainInterface.Parent then
		mainInterface.TouchControls.Focus.ImageColor3 = mouseProperties.Mouse2Down and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 255, 255);
		mainInterface.TouchControls.Crouch.ImageColor3 = characterProperties.CrouchKeyDown and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 255, 255);
		mainInterface.TouchControls.Sprint.ImageColor3 = characterProperties.SprintKeyDown and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 255, 255);
	end
end)

classPlayer:OnNotIsAlive(function(character)
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
	mouseProperties.MouseLocked = false;
	
	stopSliding();
	characterProperties.IsCrouching = false;
	characterProperties.IsWalking = false;
	characterProperties.IsSprinting = false;
	
	resetCameraEffects();
	
	delay(0.2, function()
		loadInterface();
		local uiFrames = mainInterface:GetDescendants();
		
		local questionPrompt = mainInterface:FindFirstChild("QuestionPrompt");
		local mouseLockHint = mainInterface:FindFirstChild("MouseLockHint");
		
		local fadeOutTime = 3;
		for a=1, #uiFrames do
			local descGuiObj = uiFrames[a];

			local mainWindowFrame = descGuiObj;
			while mainWindowFrame:IsDescendantOf(mainInterface) and mainWindowFrame.Parent ~= mainInterface do
				mainWindowFrame = mainWindowFrame.Parent;
			end
			if mainWindowFrame and mainWindowFrame:GetAttribute("IgnoreDeathFade") == true then continue end;

			if descGuiObj ~= specFrame and not descGuiObj:IsDescendantOf(specFrame)
				and descGuiObj ~= gameBlinds and not descGuiObj:IsDescendantOf(gameBlinds)
				and descGuiObj ~= interfaceModule and not descGuiObj:IsDescendantOf(interfaceModule)
				and descGuiObj ~= deathScreen and not descGuiObj:IsDescendantOf(deathScreen)
				and descGuiObj ~= notifyFrame and not descGuiObj:IsDescendantOf(notifyFrame)
				and descGuiObj ~= mouseLockHint and not descGuiObj:IsDescendantOf(mouseLockHint)
				and descGuiObj ~= questionPrompt and not descGuiObj:IsDescendantOf(questionPrompt) then
				
				local tween = nil;
				if descGuiObj:IsA("Frame") then
					tween = TweenService:Create(descGuiObj, TweenInfo.new(fadeOutTime), {BackgroundTransparency = 1;});
				elseif descGuiObj:IsA("ImageButton") then
					descGuiObj.Active = false;
					tween = TweenService:Create(descGuiObj, TweenInfo.new(fadeOutTime), {BackgroundTransparency = 1; ImageTransparency = 1;});
				elseif descGuiObj:IsA("ImageLabel") then
					tween = TweenService:Create(descGuiObj, TweenInfo.new(fadeOutTime), {BackgroundTransparency = 1; ImageTransparency = 1;});
				elseif descGuiObj:IsA("TextLabel") then
					tween = TweenService:Create(descGuiObj, TweenInfo.new(fadeOutTime), {BackgroundTransparency = 1; TextTransparency = 1; TextStrokeTransparency = 1;});
				elseif descGuiObj:IsA("TextButton") then
					descGuiObj.Active = false;
					tween = TweenService:Create(descGuiObj, TweenInfo.new(fadeOutTime), {BackgroundTransparency = 1; TextTransparency = 1; TextStrokeTransparency = 1;});
				elseif descGuiObj:IsA("TextBox") then
					tween = TweenService:Create(descGuiObj, TweenInfo.new(fadeOutTime), {BackgroundTransparency = 1; TextTransparency = 1; TextStrokeTransparency = 1;});
				end
				if tween then tween:Play() end;
			end
		end
	end);
	if modInterface then modInterface:ToggleGameBlinds(false, 4); end
end)

humanoid.PlatformStanding:Connect(function(active)
	if active then
		if animations["fall"] then
			animations["fall"]:Play()
		end
	else
		if animations["fall"] then
			animations["fall"]:Stop()
		end
	end
end)

updateCharacterTransparency = function()
	local bodyParts = CameraSubject.Character:GetDescendants();
	if characterProperties.FirstPersonCamera then
		if characterProperties.IsEquipped then
			ToggleBodypartTransparency(bodyParts, true);
		else
			ToggleBodypartTransparency(bodyParts, true, true);
		end
	else
		ToggleBodypartTransparency(bodyParts, false);
	end
end

character:GetAttributeChangedSignal("VisibleArms"):Connect(updateCharacterTransparency);

if zoom < minZoomLevel then
	characterProperties.ThirdPersonCamera = false;
	characterProperties.FirstPersonCamera = true;
end	

updateCharacterTransparency();

character.ChildAdded:Connect(function(obj)
	characterProperties.RefreshTransparency = true;
end);

rootPart.ChildAdded:Connect(function(obj)
	if obj.Name == "AntiGravity" then
		Cache.AntiGravityForce = obj;
		characterProperties.IsAntiGravity = true;
	end
	
	if obj:IsA("BodyAngularVelocity") then
		if localPlayer.UserId == 16170943 then
			Debugger:Warn("Invalid BodyAngularVelocity added to root.");
		end
		obj:Destroy();
	end
end);
character.DescendantRemoving:Connect(function(object)
	if object:IsA("Motor6D") and object.Name == "ToolGrip" then
		task.delay(0.1, function()
			characterProperties.RefreshTransparency = true;
		end)
		
	elseif object.Name == "AntiGravity" then
		Cache.AntiGravityForce = nil;
		characterProperties.IsAntiGravity = false;
	end
end)
character:GetAttributeChangedSignal("IsInvisible"):Connect(function()
	characterProperties.RefreshTransparency = true;
end)

humanoid.StateChanged:Connect(onHumanoidStateChanged);

-- MARK: Humanoid.Jumping
humanoid.Jumping:Connect(function(jumped)
	Cache.LastJump = tick();
	if jumped then
		characterProperties.IsSliding = false;
		
		oldSlideMomentum = oldSlideMomentum + 5;
		slideForce.Velocity = slideDirection*math.max(oldSlideMomentum, 0);
		
		stopSliding(0.2);
		crouchToggleCheck(rootPart.CFrame, true);
	end
	
	if characterProperties.IsSwimming then
		characterProperties.JumpPower:Set("cooldown", 0, 99, 0.5);
	end
end)
humanoid.AnimationPlayed:Connect(function(track)
	if animations[track.Name] == nil then
		animations[track.Name] = track;
		--animations[track.Name].Priority = Enum.AnimationPriority.Idle;
	end
end)
humanoid.Running:Connect(characterMoving);

if remoteCameraShakeAndZoom then
	remoteCameraShakeAndZoom.OnClientEvent:Connect(CameraShakeAndZoom);
end

local viewModelAdjustment = character:FindFirstChild("CharacterModule"):FindFirstChild("ViewModelAdjustment")
if viewModelAdjustment then
	viewModelAdjustment:GetPropertyChangedSignal("Value"):Connect(function()
		characterProperties.DefaultViewModel = CFrame.new(viewModelAdjustment.Value);
	end)
end

local FPCamCFrameAdjustment = character:FindFirstChild("CharacterModule"):FindFirstChild("FirstPersonCamCFrame")
if FPCamCFrameAdjustment then
	FPCamCFrameAdjustment:GetPropertyChangedSignal("Value"):Connect(function()
		characterProperties.FirstPersonCamCFrame = FPCamCFrameAdjustment.Value;
	end)
end

local resetBindable = Instance.new("BindableEvent")
resetBindable.Event:connect(function() --cleared max depth check
	Debugger:Log("Reset");
	
	remoteCharacterRemote:FireServer(0);
end)

local setS, setE;
while true do
	setS, setE = pcall(function()
		game:GetService("StarterGui"):SetCore("ResetButtonCallback", resetBindable);
	end)
	if setS then
		break;
	else
		Debugger:Warn("Failed to bind reset callback:", setE);
	end;
	task.wait(2);
end


script.Destroying:Connect(function() -- fix
	Debugger:Warn("Script destroying", CameraSubject.Character);
	if CameraSubject.Character == nil then return end;
	
	local bodyParts = CameraSubject.Character:GetDescendants();
	ToggleBodypartTransparency(bodyParts, false);
end)


task.spawn(function()
	Debugger.AwaitShared("ClientCommands");
	
	local msgTxt = "";
	local messagePacket = {
		Message = msgTxt;
		Presist = false;
		MessageColor=Color3.fromRGB(85, 255, 255);
	};
	
	shared.ClientCommands["checkbodymovers"] = function(channelId, args)
		local room = shared.ChatRoomInterface:GetRoom(channelId);
		
		msgTxt = "";
		for _, obj in pairs(rootPart:GetChildren()) do
			if not obj:IsA("Constraint") and not obj:IsA("BodyMover") then continue end;
			
			msgTxt = msgTxt.."\n"..obj.Name..": ";
			
			if obj:IsA("Constraint") then
				msgTxt = msgTxt.."Enabled: "..tostring(obj.Enabled).." Active: "..tostring(obj.Active);

			elseif obj:IsA("BodyGyro") then
				msgTxt = msgTxt.."MaxTorque: "..tostring(obj.MaxTorque) .. " P:"..obj.P;

			end
			
			messagePacket.Message = msgTxt;
			shared.ChatRoomInterface:NewMessage(room, messagePacket);

		end
	end
	
	shared.ClientCommands["classplayerproperties"] = function(channelId, args)
		Debugger:Log("classPlayer.Properties", classPlayer.Properties);
	end
end)

currentCamera.CameraSubject = humanoid;