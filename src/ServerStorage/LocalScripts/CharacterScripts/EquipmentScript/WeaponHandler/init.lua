local WeaponHandler = {
	InstanceCache = nil;
};

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local player = game.Players.LocalPlayer;
local playerGui = player.PlayerGui;
local camera = workspace.CurrentCamera;
local character = script.Parent.Parent;
local rootPart = character:WaitForChild("HumanoidRootPart");
local head = character:WaitForChild("Head");
local humanoid = character:WaitForChild("Humanoid");
local animator = humanoid:WaitForChild("Animator");

local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();

local modWeaponMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);
local modAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modFlashlight = require(script.Parent:WaitForChild("Flashlight"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modArcTracing = require(game.ReplicatedStorage.Library.ArcTracing);
local modParticleSprinkler = require(game.ReplicatedStorage.Particles.ParticleSprinkler);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local modRadialImage = require(game.ReplicatedStorage.Library.UI.RadialImage);
local modStorageInterface = require(game.ReplicatedStorage.Library.UI.StorageInterface);

--== Remotes;
local prefabs = game.ReplicatedStorage.Prefabs.Objects;

local remotePrimaryFire = modRemotesManager:Get("PrimaryFire");
local remoteReloadWeapon = modRemotesManager:Get("ReloadWeapon");
local remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler");

local bindReloadYield = script:WaitForChild("ReloadYield");
local bindPrimaryFiringYield = script:WaitForChild("PrimaryFiringYield");
local bindReloadingYield = script:WaitForChild("ReloadingYield");

--==
local mouseProperties = modCharacter.MouseProperties;
local characterProperties = modCharacter.CharacterProperties;

local random = Random.new();
local spreadRandom = Random.new(player.UserId);
local animationFiles = {};
local reloadRadial;
local lastAdsBool = false;

local arcPartTemplate = Instance.new("Part");
arcPartTemplate.Name = "ArcRender";
arcPartTemplate.Anchored = true;
arcPartTemplate.CanCollide = false;
arcPartTemplate.Material = Enum.Material.SmoothPlastic;
arcPartTemplate.Transparency = 0.5;
arcPartTemplate.Color = Color3.fromRGB(255, 0, 0);

local landPartTemplate = Instance.new("Part");
landPartTemplate.Anchored = true;
landPartTemplate.CanCollide = false;
landPartTemplate.Material = Enum.Material.Neon;
landPartTemplate.Color = Color3.fromRGB(124, 89, 89);
landPartTemplate.Size = Vector3.new(1, 0.1, 1);
landPartTemplate.Transparency = 0.5;
local diskMesh = Instance.new("SpecialMesh");
diskMesh.MeshType = Enum.MeshType.Sphere;
diskMesh.Scale = Vector3.new(1, 1, 1);
diskMesh.Parent = landPartTemplate;

local reloadRadialConfig = '{"version":1,"size":128,"count":60,"columns":8,"rows":8,"images":["rbxassetid://4286509260"]}';
local weaponInterface;
--== Shared;
local Equipped;
local itemPromptConn;

local editPanelVisible = false;
--== Script;
--modGuiObjectTween.FadeTween(script:WaitForChild("WeaponInterface"), modGuiObjectTween.FadeDirection.Out, TweenInfo.new(0.1));

local function toggleWeaponInterface(oldValue, disabled)
	disabled = disabled == true;
	
	if weaponInterface and weaponInterface:IsDescendantOf(playerGui) then
		weaponInterface.Enabled = not disabled;
	end
end
modConfigurations.OnChanged("DisableWeaponInterface", toggleWeaponInterface)
modConfigurations.OnChanged("DisableHud", toggleWeaponInterface);

function WeaponHandler:Equip(library, weaponId)
	local cache = {
		FlipPlayingWeaponAnim = nil;
		LastSprintAnimationCanPlay = nil;
	};

	for _, obj in pairs(playerGui:GetChildren()) do
		if obj.Name == "WeaponInterface" then
			obj:Destroy();
		end
	end

	local modInterface = modData:GetInterfaceModule();
	weaponInterface = script.WeaponInterface:Clone();
	weaponInterface.Parent = playerGui;
	
	local crosshairFrame = weaponInterface:WaitForChild("CrosshairFrame");
	local tpScanFrame = weaponInterface:WaitForChild("TPScan");
	local scopeFrame = weaponInterface:WaitForChild("ScopeFrame");
	local ammoCounter = weaponInterface:WaitForChild("AmmoCounter");
	local reloadLabel = crosshairFrame:WaitForChild("ReloadIcon");
	local hitmarker = weaponInterface:WaitForChild("HitmarkerFrame");
	
	local keyPromptsFrame = weaponInterface:WaitForChild("KeyPrompts");
	local reloadFrame = keyPromptsFrame:WaitForChild("ReloadHint");
	local activateModHint = keyPromptsFrame:WaitForChild("ActivateModHint");

	local itemPromptButton = modInterface.TouchControls:WaitForChild("ItemPrompt");
	local touchItemPrompt = itemPromptButton:WaitForChild("Item");
	
	Equipped.Id = weaponId;
	local rightWeaponModel = Equipped.RightHand.Prefab;
	local leftWeaponModel = Equipped.LeftHand.Prefab;
	
	if rightWeaponModel == nil and leftWeaponModel == nil then return end;
	
	local classPlayer = shared.modPlayers.GetByName(player.Name);
	local modWeaponModule = modData:GetItemClass(weaponId);
	
	local properties = modWeaponModule.Properties;
	local configurations = modWeaponModule.Configurations;
	local animations = modWeaponModule.Animations or library.Animations;
	local audio = modWeaponModule.Audio or library.Audio;

	properties.CanPrimaryFire = false;
	
	local objects = {};
	reloadRadial = modRadialImage.new(reloadRadialConfig, reloadLabel);
	
	local unequiped = false;
	local equipped = false;
	
	hitmarker.Visible = false;

	if rightWeaponModel then
		objects.Right = {};
		objects.Right.Model = rightWeaponModel;
		objects.Right.Handle = rightWeaponModel:WaitForChild("Handle");
		objects.Right.BulletOrigin = objects.Right.Handle:WaitForChild("BulletOrigin");
		objects.Right.MuzzleOrigin = objects.Right.Handle:WaitForChild("MuzzleOrigin");
		objects.Right.CaseOutPoint = objects.Right.Handle:FindFirstChild("CaseOut");
		objects.Right.WeaponSights = objects.Right.Handle:FindFirstChild("WeaponSights");
		
	end
	
	if leftWeaponModel then
		objects.Left = {};
		objects.Left.Model = leftWeaponModel;
		objects.Left.Handle = leftWeaponModel:WaitForChild("Handle");
		objects.Left.BulletOrigin = objects.Left.Handle:WaitForChild("BulletOrigin");
		objects.Left.MuzzleOrigin = objects.Left.Handle:WaitForChild("MuzzleOrigin");
		objects.Left.CaseOutPoint = objects.Left.Handle:FindFirstChild("CaseOut");
		objects.Left.WeaponSights = objects.Left.Handle:FindFirstChild("WeaponSights");
	end

	local storageItem = modData.GetItemById(weaponId);
	Equipped.RightHand.Item = storageItem;
	
	local mainWeaponModel = rightWeaponModel or leftWeaponModel;
	local mainHandle = mainWeaponModel:WaitForChild("Handle");
	local bulletOrigin = (objects.Right and objects.Right.BulletOrigin) or (objects.Left and objects.Left.BulletOrigin);

	local infType = mainWeaponModel:GetAttribute("InfAmmo");
	
	local sightViewModel;
	if character:FindFirstChild("EditMode") then
		sightViewModel = mainWeaponModel:FindFirstChild("SightViewModel", true);

		if sightViewModel then
			editPanelVisible = true;
			if configurations.AimDownViewModel == nil then
				configurations.AimDownViewModel = CFrame.new();
			end
			if configurations.HipFireViewModel == nil then
				configurations.HipFireViewModel = CFrame.new();
			end
			sightViewModel.CFrame = configurations.HipFireViewModel;
		end
	end
	
	local wieldConfigModule = mainWeaponModel:FindFirstChild("WieldConfig");
	if wieldConfigModule then
		local wieldConfigData = require(wieldConfigModule);
		for k, v in pairs(wieldConfigData) do
			modWeaponModule.SetConfigurations(k, v);
		end
	end
	
	modCharacter.EquippedToolModule = modWeaponModule;
	
	local hideOnAds = {};
	local adsPartsHidden = false;
	for _, obj in pairs(mainWeaponModel:GetChildren()) do
		if obj:IsA("BasePart") and obj:GetAttribute("HideOnAds") == true then
			table.insert(hideOnAds, obj);
		end
	end
	
	local arcList = {};
	local arcTracer, arcDisk, arcTracerConfig;
	
	if configurations.BulletMode == modAttributes.BulletModes.Projectile then
		arcDisk = landPartTemplate:Clone();
		
		local projectileId = storageItem.Values.CustomProj or configurations.ProjectileId;
		local projectileObject = modProjectile.Get(projectileId);
		arcTracerConfig = projectileObject.ArcTracerConfig;
		
		arcTracer = modArcTracing.new();
		for k, v in pairs(arcTracerConfig) do
			arcTracer[k] = v;
		end
		if arcTracerConfig.IgnoreEntities ~= true then
			table.insert(arcTracer.RayWhitelist, workspace.Entity);
			table.insert(arcTracer.RayWhitelist, workspace:FindFirstChild("Characters"));
		end
	end
	
	Equipped.RightHand.Data = {
		Inaccuracy=(configurations.ModInaccuracy or configurations.Inaccuracy); 
		LerpBody=true; 
		lastFired=tick()-5; 
		reloadCooldown=tick()-5; 
		reloadAttemptCount=0;
	};
	local inFocusDuration = nil;
	local focusCharge = 0;
	
	local loadedAnims = Equipped.Animations;
	local function isAnimPlaying(list)
		for a=1, #list do
			local k = list[a];
			if loadedAnims[k] and loadedAnims[k].IsPlaying then
				return true;
			end
		end
		
		return false;
	end

	local availableInvAmmo = 0;
	local function getReserveAmmo(recount)
		if recount == true and configurations.AmmoType then
			local activeAmmoId = storageItem.Values.AmmoId or configurations.AmmoType;
			availableInvAmmo = modData.CountItemIdFromCharacter(activeAmmoId);
		end

		return properties.MaxAmmo + availableInvAmmo;
	end
	getReserveAmmo(true);
	
	local function updateValues()
		modWeaponModule = modData:GetItemClass(weaponId);
		modCharacter.EquippedToolModule = modWeaponModule;
		
		local reloading = properties.Reloading
		
		properties = modWeaponModule.Properties;
		configurations = modWeaponModule.Configurations;
		
		properties.Reloading = reloading;
		
		if storageItem and storageItem.Values then
			local values = storageItem.Values;
			
			properties.Ammo = values.A or configurations.AmmoLimit;
			properties.MaxAmmo = values.MA or configurations.MaxAmmoLimit;
			
			if (getReserveAmmo() > 0 or properties.Ammo > 0) and loadedAnims["Empty"] then
				properties.CanPrimaryFire = true;
				loadedAnims["Empty"]:Stop();
			end
		end
	end
	
	local function updateAmmoCounter()
		if storageItem == nil then return end;
		
		if modConfigurations.CompactInterface then
			ammoCounter.Position = UDim2.new(0.5, 0, 1, -90);
		else
			ammoCounter.Position = UDim2.new(0.5, 0, 0.94, -145);
		end
		
		ammoCounter.Text = properties.Ammo .."/".. getReserveAmmo();
		
		task.spawn(function()
			modStorageInterface.RefreshStorageItemId(weaponId);
		end)
	end
	
	modData.OnAmmoUpdate:Connect(function(id)
		if weaponId == id then
			storageItem = modData.GetItemById(weaponId);
			Equipped.RightHand.Item = storageItem;
		end;
		
		getReserveAmmo(true);
		updateValues();
		updateAmmoCounter();
	end)
	
	local projRaycast = RaycastParams.new();
	projRaycast.FilterType = Enum.RaycastFilterType.Include;
	projRaycast.IgnoreWater = true;
	projRaycast.CollisionGroup = "Raycast";
	projRaycast.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain;};
	
	local s1Tick = tick();
	local function weaponRender(delta)
		if not characterProperties.IsEquipped then return end;
		if crosshairFrame == nil or not crosshairFrame:IsDescendantOf(playerGui) then return end;
		
		local currentTick = tick();
		if currentTick - s1Tick >= 1 then
			s1Tick = currentTick;
			
			updateAmmoCounter();
		end
		
		local mousePosition = UserInputService:GetMouseLocation();
		if not mouseProperties.MouseLocked then
			crosshairFrame.Position = UDim2.new(0, mousePosition.X, 0, mousePosition.Y);
		else
			crosshairFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
		end
		
		if configurations.SpinUpTime and configurations.SpinDownTime then
			if Equipped.RightHand.Data.SpinFloat == nil then Equipped.RightHand.Data.SpinFloat = 0 end;
			local spinUpRate = delta/configurations.SpinUpTime;
			local spinDownRate = delta/configurations.SpinDownTime;
			
			Equipped.RightHand.Data.SpinFloat = math.clamp(Equipped.RightHand.Data.IsSpinning
				and Equipped.RightHand.Data.SpinFloat + spinUpRate
				or Equipped.RightHand.Data.SpinFloat - spinDownRate, 0, 1);
			
		else
			Equipped.RightHand.Data.SpinningReady = nil;
		end
		local spinFloat=Equipped.RightHand.Data.SpinFloat;
		
		local playerVelocity = characterProperties.PlayerVelocity;
		Equipped.RightHand.Data.Inaccuracy = (configurations.ModInaccuracy or configurations.Inaccuracy)
			+ (characterProperties.DefaultWalkSpeed > 0 and (playerVelocity/characterProperties.DefaultWalkSpeed)*configurations.MovingInaccuracyScale or 0)
			- (characterProperties.IsCrouching and configurations.CrouchInaccuracyReduction or 0)
			- (characterProperties.IsFocused and configurations.FocusInaccuracyReduction or 0)
			+ (configurations.FullSpinInaccuracyChange and spinFloat and configurations.FullSpinInaccuracyChange*spinFloat or 0);
		
		if characterProperties.IsFocused and configurations.Deadeye then
			Equipped.RightHand.Data.Inaccuracy = Equipped.RightHand.Data.Inaccuracy * math.clamp(1-configurations.Deadeye, 0, 1);
		end
		
		-- Skill: Trained In Arms;
		if classPlayer.Properties.trinar then
			Equipped.RightHand.Data.Inaccuracy = Equipped.RightHand.Data.Inaccuracy * (100-classPlayer.Properties.trinar.Percent)/100;
		end
		
		-- Flinch
		if mouseProperties.FlinchInacc > 0 then
			Equipped.RightHand.Data.Inaccuracy = Equipped.RightHand.Data.Inaccuracy + mouseProperties.FlinchInacc;
		end
		
		if characterProperties.FirstPersonCamera then
			characterProperties.BodyLockToCam = true;
			tpScanFrame.Visible = false;
			
		else
			if (currentTick - Equipped.RightHand.Data.lastFired) > 1 or properties.Reloading then
				characterProperties.BodyLockToCam = false;
			else
				characterProperties.BodyLockToCam = true;
			end
			
			local scanPoint = modWeaponMechanics.CastHitscanRay{
				Origin = mouseProperties.Focus.p;
				Direction = mouseProperties.Direction;
				IncludeList = projRaycast.FilterDescendantsInstances;
				Range = configurations.BulletRange;
			};
			
			local headDir = (scanPoint-head.Position).Unit;

			local landPoint = modWeaponMechanics.CastHitscanRay{
				Origin = head.Position;
				Direction = headDir;
				IncludeList = projRaycast.FilterDescendantsInstances;
				Range = configurations.BulletRange;
			};

			local pointsDist = ((scanPoint.X-landPoint.X)^2 + (scanPoint.Y-landPoint.Y)^2 + (scanPoint.Z-landPoint.Z)^2);
			
			local screenPoint, onScreen = camera:WorldToViewportPoint(landPoint);
			
			if onScreen and pointsDist > 4 then
				tpScanFrame.Visible = true;
				tpScanFrame.Position = UDim2.new(0, screenPoint.X, 0, screenPoint.Y);
				
			else
				tpScanFrame.Visible = false;
			end
			
		end
		
		if configurations.AimDownViewModel and equipped then
			properties.CanAimDown = true;
			if properties.Reloading and configurations.CanUnfocusFire ~= false then
				properties.CanAimDown = false;
			end
			if loadedAnims["Empty"] and loadedAnims["Empty"].IsPlaying then
				properties.CanAimDown = false;
			end
			if loadedAnims["Inspect"] and loadedAnims["Inspect"].IsPlaying then
				properties.CanAimDown = false;
			end
			if loadedAnims["Inspect2"] and loadedAnims["Inspect2"].IsPlaying then
				properties.CanAimDown = false;
			end
			
			if properties.IsPrimaryFiring and configurations.UseScopeGui then
				properties.CanAimDown = false;
			end
			
			if properties.CanAimDown and characterProperties.IsFocused then
				characterProperties.FieldOfView = rootPart:GetAttribute("FOV") or configurations.AimDownFOV or 50;
				characterProperties.SwayYStrength=0.01;
				characterProperties.VelocitySrength=0.1;
				
				characterProperties.AimDownSights = true;
				
				if sightViewModel then
					if lastAdsBool ~= characterProperties.AimDownSights then
						sightViewModel.CFrame = configurations.AimDownViewModel;
					end

					modWeaponModule.SetConfigurations("AimDownViewModel", sightViewModel.CFrame);
					UserInputService.MouseIconEnabled = true;

					weaponInterface.EditPanel.Visible = editPanelVisible;
					weaponInterface.EditPanel.AttachmentTag.Value = sightViewModel;
					weaponInterface.EditPanel.AttachmentTag:SetAttribute("ADS", characterProperties.AimDownSights);

					modCharacter.DevViewModel = configurations.AimDownViewModel;
				end
				
				--if objects.Right and objects.Right.SightViewModel then
					
				--	if lastAdsBool ~= characterProperties.AimDownSights then
				--		objects.Right.SightViewModel.CFrame = configurations.AimDownViewModel;
				--	end
					
				--	modWeaponModule.SetConfigurations("AimDownViewModel", objects.Right.SightViewModel.CFrame);
				--	UserInputService.MouseIconEnabled = true;
					
				--	weaponInterface.EditPanel.Visible = editPanelVisible;
				--	weaponInterface.EditPanel.AttachmentTag.Value = objects.Right.SightViewModel;
				--	weaponInterface.EditPanel.AttachmentTag:SetAttribute("ADS", characterProperties.AimDownSights);
					
				--	modCharacter.DevViewModel = configurations.AimDownViewModel;
				--end
				
				
				lastAdsBool = true;
			else
				characterProperties.AimDownSights = false;
			end
		else
			characterProperties.AimDownSights = false;
		end
		if not characterProperties.AimDownSights then
			if configurations.HipFireFOV then
				characterProperties.FieldOfView = rootPart:GetAttribute("FOV") or configurations.HipFireFOV or nil;
				
			else
				characterProperties.FieldOfView = nil;
				
			end
			
			characterProperties.SwayYStrength=1;
			characterProperties.VelocitySrength=1;
			
			if objects.Right and objects.Right.SightViewModel then
				
				if lastAdsBool ~= characterProperties.AimDownSights and configurations.HipFireViewModel then
					objects.Right.SightViewModel.CFrame = configurations.HipFireViewModel;
				end
				
				configurations.HipFireViewModel = objects.Right.SightViewModel.CFrame;
				UserInputService.MouseIconEnabled = true;
				
				weaponInterface.EditPanel.Visible = editPanelVisible;
				weaponInterface.EditPanel.AttachmentTag.Value = objects.Right.SightViewModel;
				weaponInterface.EditPanel.AttachmentTag:SetAttribute("ADS", characterProperties.AimDownSights);
				
				modCharacter.DevViewModel = configurations.HipFireViewModel;
			end
			lastAdsBool = false;
		end
		
		
		if properties.Ammo <= 0 and getReserveAmmo() > 0 then
			reloadFrame.Visible = true;
		else
			reloadFrame.Visible = false;
		end
		
		if characterProperties.IsFocused then
			
			if inFocusDuration == nil then
				if properties.Ammo <= 0 or properties.Reloading then
				else
					inFocusDuration = tick();
				end
			end;
			
			if configurations.WeaponType == modAttributes.WeaponType.SMG then
				characterProperties.AdsWalkSpeedMultiplier = nil;
			elseif configurations.WeaponType == modAttributes.WeaponType.HMG then
				characterProperties.AdsWalkSpeedMultiplier = 0.3;
			elseif configurations.FocusWalkSpeedReduction then
				characterProperties.AdsWalkSpeedMultiplier = configurations.FocusWalkSpeedReduction;
			else
				characterProperties.AdsWalkSpeedMultiplier = 0.5;
			end
			
		else
			if inFocusDuration ~= nil then
				inFocusDuration = nil;
				focusCharge = 0;
			end;
			characterProperties.AdsWalkSpeedMultiplier = nil;
			
		end
		
		local aimDownScope = false;
		local s = 1/15;
		if characterProperties.FirstPersonCamera and configurations.AimDownViewModel and characterProperties.IsFocused then
			
			if configurations.FocusDuration > 0 then
				crosshairFrame.Visible = true;
				if inFocusDuration then
					focusCharge	= configurations.FocusDuration and math.clamp((tick()-inFocusDuration)/configurations.FocusDuration, 0, 1) or 0;
				else
					focusCharge = 0;
				end
				
				local uiSpread = properties.Reloading and 14 or (1-focusCharge)*20;
				crosshairFrame.CrosshairN:TweenPosition(UDim2.new(0.5, 0, 0.5, -uiSpread), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, s);
				crosshairFrame.CrosshairS:TweenPosition(UDim2.new(0.5, 0, 0.5, uiSpread), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, s);
				crosshairFrame.CrosshairW:TweenPosition(UDim2.new(0.5, -uiSpread, 0.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, s);
				crosshairFrame.CrosshairE:TweenPosition(UDim2.new(0.5, uiSpread, 0.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, s);
			else
				crosshairFrame.Visible = false;
			end
			if configurations.UseScopeGui and properties.CanAimDown then
				scopeFrame.Visible = true;
				aimDownScope = true;
			else
				scopeFrame.Visible = false;
				aimDownScope = false;
			end
			
		else
			if configurations.FocusDuration > 0 and characterProperties.IsFocused then
				if inFocusDuration then
					crosshairFrame.Visible = true;

					if inFocusDuration then
						focusCharge	= configurations.FocusDuration and math.clamp((tick()-inFocusDuration)/configurations.FocusDuration, 0, 1) or 0;
					else
						focusCharge = 0;
					end
					
					local uiSpread = properties.Reloading and 14 or (1-focusCharge)*20;
					crosshairFrame.CrosshairN:TweenPosition(UDim2.new(0.5, 0, 0.5, -uiSpread), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, s);
					crosshairFrame.CrosshairS:TweenPosition(UDim2.new(0.5, 0, 0.5, uiSpread), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, s);
					crosshairFrame.CrosshairW:TweenPosition(UDim2.new(0.5, -uiSpread, 0.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, s);
					crosshairFrame.CrosshairE:TweenPosition(UDim2.new(0.5, uiSpread, 0.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, s);
				end
				scopeFrame.Visible = false;
				aimDownScope = false;
			else
				scopeFrame.Visible = false;
				aimDownScope = false;
				crosshairFrame.Visible = true;
				local uiSpread = properties.Reloading and 14 or math.clamp(Equipped.RightHand.Data.Inaccuracy*configurations.UISpreadIntensity, 2, 999);
				crosshairFrame.CrosshairN:TweenPosition(UDim2.new(0.5, 0, 0.5, -uiSpread), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, s);
				crosshairFrame.CrosshairS:TweenPosition(UDim2.new(0.5, 0, 0.5, uiSpread), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, s);
				crosshairFrame.CrosshairW:TweenPosition(UDim2.new(0.5, -uiSpread, 0.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, s);
				crosshairFrame.CrosshairE:TweenPosition(UDim2.new(0.5, uiSpread, 0.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, s);
			end
		end
		
		if modData.Settings.CinematicMode == 1 then
			ammoCounter.Visible = false;
		else
			ammoCounter.Visible = equipped;
		end
		
		if adsPartsHidden ~= aimDownScope then
			for a=1, #hideOnAds do
				hideOnAds[a].Transparency = aimDownScope and 1 or 0.8;
			end
			
			adsPartsHidden = aimDownScope;
		end
		
		local sprintAnimationCanPlay = false;
		local isPlayingWeaponAnim = isAnimPlaying{"Focus"; "Load"; "PrimaryFire"; "TacticalReload"; "Reload"; "CustomReload"; "CustomLoad"};
		
		if loadedAnims["Focus"] then
			sprintAnimationCanPlay = false;
			local isPerformingAction = isAnimPlaying{"Load"; "TacticalReload"; "Reload"; "CustomReload"; "CustomLoad"};
			
			if loadedAnims["Focus"].IsPlaying then
				
				if not characterProperties.IsFocused 
					or (isPerformingAction and loadedAnims["Focus"]:GetAttribute("StopOnAction") == true)
					or inFocusDuration == nil then
					
					loadedAnims["Focus"]:Stop();
					if loadedAnims["FocusCore"] and loadedAnims["FocusCore"].IsPlaying then
						loadedAnims["FocusCore"]:Stop();
					end
				else
					loadedAnims["Focus"].TimePosition = math.clamp(focusCharge, 0, 0.99);
					if loadedAnims["FocusCore"] and focusCharge > 0.99 and not loadedAnims["FocusCore"].IsPlaying then
						loadedAnims["FocusCore"]:Play(0);
					end
				end
				
			elseif isAnimPlaying{"FocusCore"} then
				
			else
				if isPerformingAction and loadedAnims["Focus"]:GetAttribute("StopOnAction") == true then
				elseif characterProperties.IsFocused and inFocusDuration then
					loadedAnims["Focus"]:Play(nil, nil, 0);
				end
			end
			
			if cache.FlipPlayingWeaponAnim ~= isPlayingWeaponAnim then
				cache.FlipPlayingWeaponAnim = isPlayingWeaponAnim;
				cache.LastPlayingWeaponAnim = tick();
			end
			
			if isPlayingWeaponAnim then
				
				if configurations.FocusWaistRotation then
					characterProperties.Joints.WaistY = configurations.FocusWaistRotation;
				end
			else
				if configurations.UnfocusWaistRotation then
					characterProperties.Joints.WaistY = configurations.UnfocusWaistRotation;
				end
			end
			
		else
			--
			if characterProperties.IsMoving then
				if characterProperties.IsSprinting then
					sprintAnimationCanPlay = true;
					
				else
					sprintAnimationCanPlay = false;
				end
			else
				sprintAnimationCanPlay = false;
			end
		end
		
		if isAnimPlaying{"Empty";} then
			sprintAnimationCanPlay = false;
		end
		if isAnimPlaying{"Inspect"; "Inspect2"} then
			sprintAnimationCanPlay = false;
		end
		if isPlayingWeaponAnim then
			sprintAnimationCanPlay = false;
		end
		
		if characterProperties.IsFocused or properties.IsPrimaryFiring then
			sprintAnimationCanPlay = false;
		end
		
		if sprintAnimationCanPlay == true then
			if cache.LastSprintAnimationCanPlay == nil then
				cache.LastSprintAnimationCanPlay = tick();
			end
			if cache.LastSprintAnimationCanPlay == nil or tick()-cache.LastSprintAnimationCanPlay <= 1 then
				sprintAnimationCanPlay = false;
			end
		else
			cache.LastSprintAnimationCanPlay = nil;
		end
		
		if sprintAnimationCanPlay then
			if loadedAnims["Sprint"] then
				if configurations.SprintWaistRotation then
					characterProperties.Joints.WaistY = configurations.SprintWaistRotation
				end
				if not loadedAnims["Sprint"].IsPlaying and (cache.LastPlayingWeaponAnim == nil or tick()-cache.LastPlayingWeaponAnim >=0.2) then
					loadedAnims["Sprint"]:Play(0.3);
					
				end
			else
				if loadedAnims["Core"].IsPlaying then
					loadedAnims["Core"]:Stop(0.2);
				end
			end
		else
			if loadedAnims["Sprint"] then
				characterProperties.Joints.WaistY = configurations.WaistRotation
				if loadedAnims["Sprint"].IsPlaying then
					loadedAnims["Sprint"]:Stop(0.2);
				end
				
			else
				if not loadedAnims["Core"].IsPlaying then
					loadedAnims["Core"]:Play(0.1);
				end
				
			end
		end
		
		
		if properties.Reloading then
			reloadLabel.Visible = true;
			local alpha = math.clamp((tick() - Equipped.RightHand.Data.reloadCooldown)/(properties.ReloadSpeed-0.1), 0, 1);
			reloadRadial:UpdateLabel(alpha);
		else
			reloadLabel.Visible = false;
		end
		
		local projArcShow = false;
		if configurations.AdsTrajectory and projArcShow then -- perma disabled;
			if characterProperties.IsFocused then

				local rayWhitelist = CollectionService:GetTagged("TargetableEntities") or {};
				table.insert(rayWhitelist, workspace.Environment);
				table.insert(rayWhitelist, workspace.Characters);
				table.insert(rayWhitelist, workspace.Terrain);
				projRaycast.FilterDescendantsInstances = rayWhitelist;
				
				local origin = mouseProperties.Focus.p;
				local raycastResult = workspace:Raycast(origin, mouseProperties.Direction*configurations.BulletRange, projRaycast);
				local rayEndPoint = raycastResult and raycastResult.Position or (origin + mouseProperties.Direction*configurations.BulletRange);
				local dist = (origin-rayEndPoint).Magnitude;
				
				local bulletOrigin = bulletOrigin.WorldPosition;
				
				local velocity = arcTracer:GetVelocityByTime(bulletOrigin, rayEndPoint, dist/ arcTracerConfig.Velocity);
				local arcPoints = arcTracer:GeneratePath(bulletOrigin, velocity);
				--bulletOrigin.WorldPosition; mouseProperties.Direction * configurations.ProjectileVelocity;
				
				if #arcList ~= #arcPoints then
					while #arcList <= #arcPoints do
						local arcPart = arcPartTemplate:Clone();
						CollectionService:AddTag(arcPart, "AdsTrajectory");
						table.insert(arcList, arcPart);
					end
					while #arcList > #arcPoints do
						local arcPart = table.remove(arcList, #arcList);
						arcPart:Destroy();
					end
				end
				
				for a=1, #arcList do
					local arcPart = arcList[a];
					local arcPoint = arcPoints[a];
					
					local _order = math.clamp(1 - (a/#arcList * 0.7), 0.5, 1);
					arcPart.Parent = workspace.CurrentCamera;
					arcPart.Size = Vector3.new(0.05, 0.05, arcPoint.Displacement);
					arcPart.Transparency = 0;
					arcPart.CFrame = CFrame.new(arcPoint.Origin, arcPoint.Point) * CFrame.new(0, 0, -arcPoint.Displacement/2);
					
					if a == #arcList and arcPoint.Normal and arcDisk then
						arcDisk.Parent = workspace.CurrentCamera;
						arcDisk.CFrame = CFrame.new(arcPoint.Point, arcPoint.Point + arcPoint.Normal) * CFrame.Angles(math.pi/2, 0, 0);
					end
				end
			else
				arcDisk = nil;
				for _, obj in pairs(CollectionService:GetTagged("AdsTrajectory")) do
					obj:Destroy();
				end
				table.clear(arcList);
			end
		end
		
		if rootPart:GetAttribute("WaistRotation") then
			characterProperties.Joints.WaistY = math.rad(tonumber(rootPart:GetAttribute("WaistRotation")) or 0);
			
		elseif configurations.WaistRotation then
			characterProperties.Joints.WaistY = configurations.WaistRotation;
		end
		
		
		modFlashlight:Update(camera.CFrame);
	end
	
	local function playWeaponSound(id, looped)
		local soundOrigin = mainHandle;
		
		if characterProperties.FirstPersonCamera then
			soundOrigin = camera;
		end
		
		local sound = modAudio.PlayReplicated(id, soundOrigin, looped);
		sound:SetAttribute("WeaponAudio", true);
		
		return sound;
	end
	
	local onShotTick;
	local ejectBullet = configurations.BulletEject and prefabs:WaitForChild(configurations.BulletEject) or nil;
	
	local function ejectShell(objectTable)
		local newEjectBullet = ejectBullet:Clone();
		game.Debris:AddItem(newEjectBullet, 5);

		newEjectBullet.CFrame = objectTable.CaseOutPoint.WorldCFrame * (configurations.BulletOffset or CFrame.new()) 
			* CFrame.Angles(0, math.rad(math.random(0, 360)), math.rad(math.random(-35, 35)));
		newEjectBullet.Parent = workspace.Debris;

		newEjectBullet:ApplyImpulse(objectTable.CaseOutPoint.WorldCFrame.RightVector * 0.05);

		task.wait(0.1);
		for _, obj in pairs(newEjectBullet:GetDescendants()) do
			if obj:IsA("Motor6D") and obj:GetAttribute("BreakJoint") == true then
				obj:Destroy();
			end
		end
	end

	local delta = 1/30;
	local function fireProj()
		if not equipped or unequiped then return end;
		
		local baseFr = 60/properties.Rpm;
		local firerate = baseFr;
		
		if configurations.RapidFire then
			local f = math.clamp((tick()-Equipped.RightHand.Data.RapidFireStart)/configurations.RapidFire, 0, 1);
			firerate = baseFr + f*(delta - baseFr);
			
		end
		firerate = math.clamp(firerate, configurations.RapidFireMax or delta, 999);
		
		if onShotTick and tick()-onShotTick < firerate then return end;
		
		if properties.IsPrimaryFiring then return end
		properties.IsPrimaryFiring = true;
		
		local fireFocusCharge = focusCharge;
		inFocusDuration = nil;
		
		-- apply recoil;
		local xR = math.random(0, configurations.XRecoil*1000)/1000 * (math.random(0, 1) == 1 and 1 or -1);
		local yR = configurations.YRecoil;

		if characterProperties.IsFocused and configurations.Deadeye then
			yR = yR * math.clamp(1-configurations.Deadeye, 0, 1);
		end
		
		if modCharacter.DizzyZAim or characterProperties.Ragdoll == true then
			mouseProperties.ZAngOffset = mouseProperties.ZAngOffset + (xR * 2);
			xR = xR *2.5;
			yR = yR *2.5;
		end
		
		mouseProperties.XAngOffset = mouseProperties.XAngOffset + (xR * modConfigurations.RecoilScaler);
		mouseProperties.YAngOffset = mouseProperties.YAngOffset + (yR * modConfigurations.RecoilScaler);
		--
		
		onShotTick = tick();
		
		local primaryFireAnim: AnimationTrack = loadedAnims["PrimaryFire"];
		local roll = random:NextInteger(1,10);
		if loadedAnims["PrimaryFire2"] and roll >= 7 then
			primaryFireAnim = loadedAnims["PrimaryFire2"];
		end
		if loadedAnims["LastFire"] and properties.Ammo == 1 then --properties.Ammo == 1 then
			primaryFireAnim = loadedAnims["LastFire"];
		end
		
		if loadedAnims["Sprint"] and loadedAnims["Sprint"].IsPlaying then
			loadedAnims["Sprint"]:Stop(0.05);
		end
		
		if characterProperties.FirstPersonCamera and configurations.AimDownViewModel and characterProperties.IsFocused then
			primaryFireAnim:Play(0, primaryFireAnim:GetAttribute("FocusWeight") or 0.2);
		else
			if primaryFireAnim:GetAttribute("LoopMarker") == true then
				if not primaryFireAnim.IsPlaying then
					primaryFireAnim:Play(0, nil);
					Equipped.RightHand.Data.loopPrimaryFireAnim = primaryFireAnim;
				end
			else
				primaryFireAnim:Play(0, nil);
			end
		end

		local values = storageItem.Values;
		task.spawn(function()
			for k, v in pairs(objects) do
				local objectTable = v;
				
				if properties.Ammo <= 0 then
					playWeaponSound(audio.Empty.Id);
					mouseProperties.Mouse1Down = false;
					return 
				end;
				if properties.Reloading then return end;
				local shotTick = tick();
				spreadRandom = Random.new(shotTick*10000);
				local shotData = {};
				
				local ammoCost = math.min(configurations.AmmoCost or 1, properties.Ammo);
				
				if configurations.Triplethreat then
					ammoCost = infType == 2 and 3 or math.min(properties.Ammo, 3);
					
				end
				
				if configurations.Rocketman and characterProperties.GroundObject == nil and getReserveAmmo() > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
					properties.MaxAmmo = properties.MaxAmmo -(infType == 2 and 0 or ammoCost);
					shotData.Rocketman = true;
					
				else
					properties.Ammo = properties.Ammo -(infType == 2 and 0 or ammoCost);
					values.A = properties.Ammo;
					
				end
				
				updateAmmoCounter();
				if configurations.OnAmmoUpdate then configurations.OnAmmoUpdate(mainWeaponModel, modWeaponModule, properties.Ammo, properties.MaxAmmo); end
				
				if configurations.BulletEject and objectTable.CaseOutPoint and modData:GetSetting("DisableParticle3D") ~= 1 then
					if configurations.BulletEjectDelayTime == nil then
						task.spawn(ejectShell, objectTable);
					end
				end
				
				if audio.PrimaryFire.Looped then
					if Equipped.RightHand.Data.loopedPrimaryFire == nil then
						Equipped.RightHand.Data.loopedPrimaryFire = playWeaponSound(audio.PrimaryFire.Id, true);
						if configurations.PrimaryFireAudio ~= nil then configurations.PrimaryFireAudio(Equipped.RightHand.Data.loopedPrimaryFire, 1); end
					end
				else
					local primaryFireSound = playWeaponSound(audio.PrimaryFire.Id, false);
					if primaryFireSound then
						primaryFireSound.PlaybackSpeed = (audio.PrimaryFire.Pitch or 1) + (math.noise(properties.Ammo+0.1, 0.1, 0.1)/5);
						
						if configurations.RapidFire and Equipped.RightHand.Data.RapidFireStart then
							local f = math.clamp((tick()-Equipped.RightHand.Data.RapidFireStart)/configurations.RapidFire, 0, 1);
							primaryFireSound.PlaybackSpeed = 1+(f/2);
						end
					end
					if configurations.PrimaryFireAudio ~= nil then configurations.PrimaryFireAudio(primaryFireSound, 1); end
				end
				
				local multishot = type(properties.Multishot) == "table" and spreadRandom:NextInteger(properties.Multishot.Min, properties.Multishot.Max) or properties.Multishot;
				
				if configurations.Triplethreat then
					multishot = ammoCost;
				end
				
				local spreadRollStart = spreadRandom:NextNumber()*2*math.pi;
				local spreadPitch = multishot <= 1 and spreadRandom:NextNumber()^2 or 1;
				
				local function spread(direction, maxSpreadAngle, multiIndex)
					maxSpreadAngle = math.clamp(maxSpreadAngle, 0, 90);
					local deflection = math.rad(maxSpreadAngle) * spreadPitch;
					if multishot > 1 then
						local mSpread = spreadRandom:NextNumber(-0.5, 0.5);
						
						if math.sign(mSpread) == -1 then
							mSpread = -1 * (math.abs(mSpread)^1.4) + 0.5;
						else
							mSpread = mSpread^1.4 + 0.5;
						end
						
						deflection = deflection * mSpread;
					end
					
					local cf = CFrame.new(Vector3.new(), direction);
					
					--multiIndex
					cf = cf*CFrame.Angles(0, 0, spreadRollStart + ((math.pi*2/multishot)*multiIndex) ); -- roll cframe
					cf = cf*CFrame.Angles(deflection, 0, 0); --pitch cframe;
					
					return cf.lookVector;
				end
				
				if configurations.ShakeCamera and modCharacter.CameraShakeAndZoom and Equipped.RightHand.Data.Inaccuracy then
					--modCharacter.CameraShakeAndZoom(Equipped.RightHand.Data.Inaccuracy/2, 1, properties.FireRate);
					--modCharacter.CameraShakeAndZoom(1, 1, math.clamp(Equipped.RightHand.Data.Inaccuracy/20, 0.3, 2));
				end
				
				modWeaponMechanics.CreateMuzzle(objectTable.MuzzleOrigin, objectTable.BulletOrigin, multishot, configurations.GenerateMuzzle);
			
				shotData.ShotOrigin = objectTable.BulletOrigin;
				if configurations.BulletMode == modAttributes.BulletModes.Hitscan then
					shotData.TargetPoints = {};
					shotData.Victims = {};
					
				elseif configurations.BulletMode == modAttributes.BulletModes.Projectile then
					shotData.Projectiles = {};
					
				end
				
				shotData.ShotPoint = shotData.ShotOrigin.WorldPosition;
				shotData.Direction = mouseProperties.Direction;
				
				if characterProperties.IsSwimming or characterProperties.IsAntiGravity then
					rootPart:ApplyImpulse(-camera.CFrame.LookVector*Vector3.new(1, 0.5, 1) * configurations.RecoilStregth*150); -- recoil force;
					
				else
					rootPart:ApplyImpulse(-camera.CFrame.LookVector*Vector3.new(1, 0.5, 1) * configurations.RecoilStregth*40); -- recoil force;
				end
				
				
				for multiIndex=1, multishot do
					local newInaccuracy = Equipped.RightHand.Data.Inaccuracy;
					if newInaccuracy == nil then return end;
					if multishot <= 1 or (multishot == 2 and multiIndex == 1) then
						local inaccuracyDeduction = (configurations.ModInaccuracy or configurations.Inaccuracy) 
							* math.clamp((shotTick-Equipped.RightHand.Data.lastFired)/configurations.InaccDecaySpeed, 0, 1);
						newInaccuracy = newInaccuracy - inaccuracyDeduction;
					end
					local spreadedDirection = spread(shotData.Direction, math.max(newInaccuracy, 0), multiIndex);
					
					
					if configurations.BulletMode == modAttributes.BulletModes.Hitscan then
						
						local destructibleModels = {};
						local firstImpactPoint = nil;
						local function onCast(basePart, position, normal, material, index, distance)
							if firstImpactPoint == nil then
								firstImpactPoint = position;
							end
							
							if basePart == nil then return end;
							local model = basePart.Parent;
							if model:IsA("Accessory") then
								model = model.Parent;
							end
							while model:GetAttribute("EntityParent") do model = model.Parent; end
							
							local npcStatus = model:FindFirstChild("NpcStatus");
							local humanoid = model:FindFirstChildWhichIsA("Humanoid");
							if humanoid and humanoid.Name == "NavMeshIgnore" then humanoid = nil; end;
							
							if (humanoid and humanoid.Health > 0 or npcStatus) then
								local weakPointGui = model:FindFirstChild("WeakpointTarget", true);
								if weakPointGui and weakPointGui.Parent ~= basePart then
									local wpRaycastParams = RaycastParams.new();
									wpRaycastParams.FilterType = Enum.RaycastFilterType.Include;
									wpRaycastParams.IgnoreWater = true
									wpRaycastParams.CollisionGroup = "Raycast";
									wpRaycastParams.FilterDescendantsInstances = {weakPointGui.Parent};
									
									local wpOrigin = position - spreadedDirection*3;
									
									local raycastResult = workspace:Raycast(wpOrigin, spreadedDirection*6, wpRaycastParams);
									
									if raycastResult and raycastResult.Instance then
										basePart = raycastResult.Instance;
									end
								end
								
								modWeaponMechanics.BulletHitSound{
									Humanoid=humanoid;
									BasePart=basePart;
									Index=index;
								}
								
								local weakpointTarget = basePart:FindFirstChild("WeakpointTarget");
								if weakpointTarget then
									modAudio.Play("WeakPointImpact", nil, false, 1/((index+1)*0.9));
									weakpointTarget:Destroy();
								end
								
								if humanoid == nil or humanoid.Name ~= "NavMeshIgnore" then
									if modData and modData:GetSetting("DisableParticle3D") ~= 1 and multiIndex == 1 and Debugger.ClientFps > 45 then
										modParticleSprinkler:Emit{
											Type=1;
											Origin=CFrame.new(position);
											Velocity=normal;
											MinSpawnCount=1;
											MaxSpawnCount=4;
										};
									else
										if humanoid and configurations.GenerateBloodEffect and Debugger.ClientFps > 25 then
											modWeaponMechanics.CreateBlood(basePart, position, (mouseProperties.Focus.p-position).unit, camera);
										end;
									end
									
									modWeaponMechanics.ImpactSound{
										Humanoid = humanoid;
										BasePart = basePart;
										Point = position;
										Normal = normal;
									}
								end
								
								table.insert(shotData.Victims, {Object=basePart; Humanoid=humanoid; Index=index;});
								
								return model;
								
							else
								while model:GetAttribute("DestructibleParent") do model = model.Parent; end
								
								if model:FindFirstChild("Destructible") and model.Destructible.ClassName == "ModuleScript" and destructibleModels[model] == nil then
									destructibleModels[model] = model;
									table.insert(shotData.Victims, {Object=basePart; Index=index;});
								end
								if configurations.GeneratesBulletHoles and basePart.Transparency <= 0.9 then
									task.spawn(function() 
										modWeaponMechanics.CreateBulletHole(basePart, position, normal);
									end)
								end;
							end

							return;
						end
						
						local rayWhitelist = CollectionService:GetTagged("TargetableEntities") or {};
						table.insert(rayWhitelist, workspace.Environment);
						table.insert(rayWhitelist, workspace.Characters);
						table.insert(rayWhitelist, workspace.Terrain);

						local scanPoint = modWeaponMechanics.CastHitscanRay{
							Origin = mouseProperties.Focus.p;
							Direction = spreadedDirection;
							IncludeList = rayWhitelist;
							Range = configurations.BulletRange;
						};
						
						local reDirection = (scanPoint-mouseProperties.Focus.Position).Unit;
						local newDirection = (scanPoint-head.Position).Unit;

						local bulletEnd = modWeaponMechanics.CastHitscanRay{
							Origin = head.Position;
							Direction = newDirection;
							IncludeList = rayWhitelist;
							Range = configurations.BulletRange;
							MaxPierce = properties.Piercing;
							PenTable = configurations.Penetration;
							PenReDirection = reDirection;
							
							OnCastFunc = onCast;
							OnPenFunc = function(packet)
								task.spawn(function()
									local basePart = packet.BasePart;
									local position = packet.Position;
									local normal = packet.Normal;
									
									if configurations.GeneratesBulletHoles and basePart.Transparency <= 0.9 then
										task.spawn(function() 
											modWeaponMechanics.CreateBulletHole(basePart, position, normal);
										end)
									end;
									modWeaponMechanics.ImpactSound{
										BasePart = basePart;
										Point = position;
										Normal = normal;
									}
								end)
							end
						};
						
						table.insert(shotData.TargetPoints, bulletEnd);
						table.clear(destructibleModels);
						
						shotData.TracerColor = Color3.fromRGB(255, 255, 255);

						local modInfo = modWeaponModule.ModHooks.PrimaryEffectMod;
						if modInfo then
							local storageItemOfMod = modData.GetItemById(modInfo.StorageItemID);

							modWeaponMechanics.ProcessModHooks({
								Dealer = player;
								ToolModule = modWeaponModule;
								ToolStorageItem = storageItemOfMod;
								ToolModel = objectTable.Model;
								ShotData = shotData;
							});
						end

						if configurations.GenerateTracers then
							modWeaponMechanics.CreateTracer(objectTable.BulletOrigin, firstImpactPoint, camera, shotData.TracerColor, configurations.SuppressorAttached)
						end;
						
						
					elseif configurations.BulletMode == modAttributes.BulletModes.Projectile then
						
						if objectTable.BulletOrigin then

							local rayWhitelist = CollectionService:GetTagged("TargetableEntities") or {};
							table.insert(rayWhitelist, workspace.Environment);
							table.insert(rayWhitelist, workspace.Characters);
							table.insert(rayWhitelist, workspace.Terrain);
							projRaycast.FilterDescendantsInstances = rayWhitelist;

							local scanPoint = modWeaponMechanics.CastHitscanRay{
								Origin = mouseProperties.Focus.p;
								Direction = mouseProperties.Direction;
								IncludeList = rayWhitelist;
								Range = configurations.BulletRange;
							};

							local newDirection = (scanPoint-head.Position).Unit;
							
							local origin = head.Position;
							spreadedDirection = newDirection * arcTracerConfig.Velocity;
							local bulletOrigin = objectTable.BulletOrigin.WorldPosition;

							local rayPoint = modWeaponMechanics.CastHitscanRay{
								Origin = origin;
								Direction = spreadedDirection;
								IncludeList = rayWhitelist;
								Range = arcTracerConfig.Velocity;
							};
							
							local rayDisplacement, offsetDir;
							if rayPoint then
								rayDisplacement = (rayPoint-bulletOrigin);
								offsetDir = rayDisplacement.Unit;
								
							else
								rayDisplacement = ((shotData.ShotPoint + newDirection* arcTracerConfig.Velocity) - bulletOrigin);
								offsetDir = rayDisplacement.Unit;
								
							end
							
							local pdata = {};
							pdata.Origin = CFrame.new(bulletOrigin);
							pdata.Orientation = objectTable.BulletOrigin.WorldOrientation;
							pdata.Direction = offsetDir;
							
							if multiIndex > 1 then
								local leftRight = multiIndex%2 == 0 and 1 or -1;
								local radMultiplier = math.floor(multiIndex/2);
								
								local deg = math.max(3/(rayDisplacement.Magnitude/32), 1);
								pdata.Direction = CFrame.Angles(0, math.rad(deg * leftRight * radMultiplier), 0):VectorToWorldSpace(offsetDir);
							end
							
							
							if modConfigurations.AutoAdjustProjectileAim == true then
								local raycastResult = workspace:Raycast(origin, mouseProperties.Direction*configurations.BulletRange, projRaycast);
								local rayEndPoint = raycastResult and raycastResult.Position or (origin + mouseProperties.Direction*configurations.BulletRange);
								local dist = (origin-rayEndPoint).Magnitude;
								
								pdata.RayEndPoint = rayEndPoint;
								pdata.Dist = dist;
								
							end
							
							table.insert(shotData.Projectiles, pdata);
							
						end
						
						
					end

					if Debugger.ClientFps <= 30 then
						task.wait();
						if  Debugger.ClientFps <= 15 then
							task.wait();
						end
					end 
				end
				
				if configurations.FocusDuration > 0 then
					shotData.FocusCharge = fireFocusCharge;
					inFocusDuration = nil;

				end
				
				if shotData.Victims and #shotData.Victims > 0 then
					hitmarker.Visible = true;
					hitmarker:SetAttribute("Timer", tick());
					
					task.delay(0.35, function()
						if tick()-hitmarker:GetAttribute("Timer") >= 0.35 then
							hitmarker.Visible = false;
						end; 

						for a=#shotData.Victims, 1, -1 do
							local victimPacket = shotData.Victims[a];
							
							if victimPacket.Humanoid then
								modInterface.modEntityHealthHudInterface.TryHookEntity(victimPacket.Humanoid.Parent);
							end
						end
					end)
				end
				
				shotData.ShotId = modData.ShotIdGen:NextInteger(1, 99);
				shotData.AmmoData = {
					Ammo = properties.Ammo;
					MaxAmmo = properties.MaxAmmo;
				}
				remotePrimaryFire:FireServer(weaponId, objectTable.Model, shotData);
				Equipped.RightHand.Data.lastFired = shotTick;
				
				if configurations.ToolCycleDelay then
					task.wait(configurations.ToolCycleDelay);
				end
			end
		end)
		
		-- local baseFr = 60/properties.Rpm;
		-- local firerate = baseFr;
		if configurations.RapidFire then
			local f = math.clamp((tick()-Equipped.RightHand.Data.RapidFireStart)/configurations.RapidFire, 0, 1);
			firerate = baseFr + f*(delta - baseFr);
			
			if Equipped.RightHand.Data.loopedPrimaryFire then
				Equipped.RightHand.Data.loopedPrimaryFire.PlaybackSpeed = 1+(f/2);
			end
		end
		
		firerate = math.clamp(firerate, delta, 999);
		
		if configurations.OnPrimaryFire then
			configurations.OnPrimaryFire(mainWeaponModel, modWeaponModule);
		end

		repeat
			RunService.RenderStepped:Wait();
		until (tick()-onShotTick) >= firerate;
		
		properties.IsPrimaryFiring = false;
		bindPrimaryFiringYield:Fire();
		return true;
	end
	
	local function reload()
		if not equipped or unequiped then return end;
		if properties.Reloading then return end;
		
		local values = storageItem.Values;
		
		--local hasCompatibleAmmo = false;
		--if properties.MaxAmmo <= 0 and configurations.AmmoType ~= nil then
		--	for a=1, #configurations.AmmoIds do
		--		local fIt = modData.FindItemIdFromCharacter(configurations.AmmoIds[a]);
		--		if fIt then
		--			hasCompatibleAmmo = true;
		--			break;
		--		end
		--	end
		--end
		
		if infType == nil and getReserveAmmo(true) <= 0  then --and not hasCompatibleAmmo
			playWeaponSound(audio.Empty.Id);
			return 
		end;
		
		if properties.IsPrimaryFiring then 
			mouseProperties.Mouse1Down = false;
			bindPrimaryFiringYield.Event:Wait(); 
		end;
		
		if properties.Ammo >= configurations.AmmoLimit then return end;
		if (tick()-(Equipped.RightHand.Data.reloadCooldown or 0)) < 0.5+(0.25*(Equipped.RightHand.Data.reloadAttemptCount or 0)) then return end;
		Equipped.RightHand.Data.reloadCooldown = tick();
		Equipped.RightHand.Data.reloadAttemptCount = math.clamp((Equipped.RightHand.Data.reloadAttemptCount or 0) +1, 0, 4);
		
		properties.Reloading = true;
		Equipped.RightHand.Data.LerpBody = false;
		loadedAnims["Inspect"]:Stop();
		
		local reloadAnim = loadedAnims["Reload"];
		local roll = random:NextInteger(1,10);
		if loadedAnims["Reload2"] and roll >= 7 then
			reloadAnim = loadedAnims["Reload2"];
		end
		
		if loadedAnims["TacticalReload"] and properties.Ammo > 0 then
			reloadAnim = loadedAnims["TacticalReload"];
		end
		
		if configurations.DoCustomReload then
			local animId = configurations.DoCustomReload(modWeaponModule, storageItem, objects);
			reloadAnim = loadedAnims[animId];
		end
		
		if loadedAnims["Sprint"] and loadedAnims["Sprint"].IsPlaying then
			loadedAnims["Sprint"]:Stop(0);
		end
		
		if configurations.ReloadMode == modAttributes.ReloadModes.Full then
			remoteReloadWeapon:FireServer(weaponId, mainWeaponModel, true);
			
			reloadAnim:Play();
			reloadAnim:AdjustSpeed(reloadAnim.Length/properties.ReloadSpeed);
			if configurations.OnReloadAnimation ~= nil then
				for k, objTable in pairs(objects) do
					configurations.OnReloadAnimation(objTable.Model, reloadAnim);
				end
			end
			local reloadSound = audio.Reload and playWeaponSound(audio.Reload.Id);
			
			if reloadSound then
				reloadSound.PlaybackSpeed = reloadSound.TimeLength/properties.ReloadSpeed;
				
			end
			
			getReserveAmmo(true);
			
			local reloadYielded = false;
			local reloadDuration = math.clamp(properties.ReloadSpeed-0.2, 0.05, 20);
			delay(reloadDuration, function()
				if not reloadYielded then
					bindReloadYield:Fire(1);
				end
			end);
			local reloadComplete = bindReloadYield.Event:Wait();
			reloadYielded = true;
			
			if reloadComplete == 2 and tick()-reloadDuration >= reloadDuration then
				reloadComplete = 1;
			end
			
			reloadAnim:Stop();
			if reloadSound then reloadSound:Stop(); end;
			
			if reloadComplete == 1 and character:IsAncestorOf(mainWeaponModel) then
				
				remoteReloadWeapon:FireServer(weaponId, mainWeaponModel, false);
				Equipped.RightHand.Data.lastSuccessfulReload = tick();
				
				local currentAmmo = properties.Ammo;
				local ammoNeeded = configurations.AmmoLimit - currentAmmo;
				local newAmmo = configurations.AmmoLimit;
				local newMaxAmmo = properties.MaxAmmo - ammoNeeded;
				
				if newMaxAmmo < 0 then
					newAmmo = properties.MaxAmmo + currentAmmo;
					newMaxAmmo = 0
				end;
				
				if newAmmo < configurations.AmmoLimit and availableInvAmmo > 0 then
					local ammoToAdd = math.min(configurations.AmmoLimit-newAmmo, availableInvAmmo);
					newAmmo = newAmmo + ammoToAdd;
					availableInvAmmo = availableInvAmmo - ammoToAdd;
				end
				
				properties.Ammo = newAmmo;
				properties.MaxAmmo = infType == nil and newMaxAmmo or configurations.MaxAmmoLimit;
				values.A = newAmmo;
				
				Equipped.RightHand.Data.reloadAttemptCount = 0;
				updateAmmoCounter();
			end
			
		elseif configurations.ReloadMode == modAttributes.ReloadModes.Single and properties.Ammo < configurations.AmmoLimit then
			repeat
				properties.Reloading = true;
				
				remoteReloadWeapon:FireServer(weaponId, mainWeaponModel, true);
				Equipped.RightHand.Data.reloadCooldown = tick();
				
				reloadAnim:Play();
				reloadAnim:AdjustSpeed(reloadAnim.Length/properties.ReloadSpeed);
				
				if audio.Reload then
					playWeaponSound(audio.Reload.Id);
				end
				
				local reloadYielded = false;
				
				coroutine.wrap(function()
					task.wait(math.clamp(properties.ReloadSpeed, 0.05, 20));
					if not reloadYielded then bindReloadYield:Fire(1); end
				end)()
				local reloadComplete = bindReloadYield.Event:Wait(); reloadYielded = true;

				local ammoCost = configurations.AmmoCost or 1;
				if properties.Ammo + ammoCost > configurations.AmmoLimit then
					reloadAnim:Stop();
					break;
				end
				
				if reloadComplete == 2 then
					reloadAnim:Stop();
					break;
					
				elseif reloadComplete == 1 then
					local reserveAmmo = getReserveAmmo();
					if storageItem and storageItem.ID == weaponId and reloadComplete and reserveAmmo > 0 then
						
						local ammoDelta = ammoCost;
						if configurations.DualShell then ammoDelta = 2; end
						if properties.Ammo + ammoDelta > configurations.AmmoLimit then -- cap to ammolimit
							ammoDelta = math.clamp(configurations.AmmoLimit - properties.Ammo, 0, ammoDelta);
						end
						
						local ammoFromMA = math.min(ammoDelta, properties.MaxAmmo);
						local ammoFromInv = 0;
						
						if ammoDelta-ammoFromMA > 0 then
							ammoFromInv = math.min(ammoDelta-ammoFromMA, availableInvAmmo);
						end
						
						ammoDelta = ammoFromMA + ammoFromInv;
						
						if ammoDelta > 0 then
							properties.Ammo = properties.Ammo + ammoDelta;
							
							if ammoFromMA > 0 then
								properties.MaxAmmo = infType == nil and (properties.MaxAmmo - ammoFromMA) or configurations.MaxAmmoLimit;
								properties.MaxAmmo = math.max(properties.MaxAmmo, 0);
							end
							if ammoFromInv > 0 then
								availableInvAmmo = availableInvAmmo - ammoFromInv;
							end
							
							values.A = properties.Ammo;
						end
						
						remoteReloadWeapon:FireServer(weaponId, mainWeaponModel, false);
						Equipped.RightHand.Data.lastSuccessfulReload = tick();
						Equipped.RightHand.Data.reloadAttemptCount = 0;
						
						if ammoDelta <= 0 then break end;
					else
						break;
					end
					
				end
				
				updateAmmoCounter();
				if configurations.OnAmmoUpdate then configurations.OnAmmoUpdate(mainWeaponModel, modWeaponModule, properties.Ammo); end
				if properties.IsPrimaryFiring then break; end;
			until configurations.AmmoLimit == 1 or properties.Ammo >= configurations.AmmoLimit or getReserveAmmo(true) <= 0 or mainWeaponModel.Parent == nil;
		end
		
		if loadedAnims["Empty"] then loadedAnims["Empty"]:Stop(); end
		Equipped.RightHand.Data.LerpBody = true;
		properties.Reloading = false;
		bindReloadingYield:Fire();
		updateAmmoCounter();
	end

	local function tryAutoReload()
		if properties.Reloading or getReserveAmmo(true) <= 0 then return end;
		
		reload();
		if configurations.OnAmmoUpdate then configurations.OnAmmoUpdate(mainWeaponModel, modWeaponModule, properties.Ammo); end
	end
	
	local function primaryFire()
		if not equipped or unequiped then return end;
		
		if configurations.CanUnfocusFire == false and inFocusDuration == nil then
			return;
		end
		
		if Equipped.RightHand.Data.lastSuccessfulReload and (tick()-Equipped.RightHand.Data.lastSuccessfulReload <= 0.2) then
			return;
		end
		
		if properties.Reloading then bindReloadingYield.Event:Wait(); end;
		
		if humanoid.Health > 0 and properties.CanPrimaryFire then
			properties.CanPrimaryFire = false;
			
			if loadedAnims["Inspect"] and loadedAnims["Inspect"].IsPlaying then loadedAnims["Inspect"]:Stop(); end
			if properties.Ammo > 0 then
				if loadedAnims["Empty"] then
					loadedAnims["Empty"]:Stop();
				end
				
				if configurations.CanUnfocusFire == false and not characterProperties.IsFocused then
					properties.CanPrimaryFire = true;
					return;
				end
				
				if configurations.TriggerMode == modAttributes.TriggerModes.Semi then
					fireProj();
					
				elseif configurations.TriggerMode == modAttributes.TriggerModes.Automatic
					or configurations.TriggerMode == modAttributes.TriggerModes.SpinUp then
					
					if configurations.TriggerMode == modAttributes.TriggerModes.SpinUp then
						if Equipped.RightHand.Data.SpinFloat == nil then Equipped.RightHand.Data.SpinFloat = 0 end;
						Equipped.RightHand.Data.IsSpinning = true;
						
						local function revFunc()
							while (Equipped.RightHand.Data.SpinFloat or 0) < 1 and mouseProperties.Mouse1Down do
								task.wait();
							end
						end
						
						if audio.SpinUp then Equipped.RightHand.Data.SpinUpSound = playWeaponSound(audio.SpinUp.Id); end;
						if loadedAnims["SpinUp"] then loadedAnims["SpinUp"]:Play(configurations.SpinUpTime); end;
						
						if configurations.SpinAndFire then
							coroutine.wrap(revFunc)();
						else
							revFunc();
						end
					end
					
					if configurations.TriggerMode == modAttributes.TriggerModes.Automatic or Equipped.RightHand.Data.SpinFloat >= 1 or configurations.SpinAndFire then
						if configurations.RapidFire then
							Equipped.RightHand.Data.RapidFireStart = tick();
						end
						repeat
							if fireProj() ~= true then
								task.wait();
							end
							if not characterProperties.CanAction then break; end;
						until not mouseProperties.Mouse1Down or unequiped;
						
						if Equipped.RightHand.Data.loopPrimaryFireAnim then
							local primaryFireAnim = Equipped.RightHand.Data.loopPrimaryFireAnim;
							if primaryFireAnim:GetAttribute("LoopEnd") then
								primaryFireAnim.TimePosition = primaryFireAnim:GetAttribute("LoopEnd");
							else
								primaryFireAnim:Stop();
							end
						end
					end
					
					if Equipped.RightHand.Data.SpinUpSound then Equipped.RightHand.Data.SpinUpSound:Stop(); end
					if configurations.TriggerMode == modAttributes.TriggerModes.SpinUp then
						if loadedAnims["SpinUp"] then loadedAnims["SpinUp"]:Stop(configurations.SpinDownTime); end;
						if audio.SpinDown then Equipped.RightHand.Data.SpinDownSound = playWeaponSound(audio.SpinDown.Id); end;
						Equipped.RightHand.Data.IsSpinning = nil;
						
					end
					if Equipped.RightHand.Data.loopedPrimaryFire ~= nil then
						local prevPrimaryFire = Equipped.RightHand.Data.loopedPrimaryFire;
						Equipped.RightHand.Data.loopedPrimaryFire = nil;
						if configurations.PrimaryFireAudio ~= nil then
							configurations.PrimaryFireAudio(prevPrimaryFire, 2);
						else
							prevPrimaryFire:Destroy();
						end
					end
				end
				
				if properties.Ammo <= 0 and configurations.AutoReload then
					tryAutoReload();
				end
				
			else
				if loadedAnims["Empty"] then
					loadedAnims["Empty"]:Play();
				end
				playWeaponSound(audio.Empty.Id);
				if configurations.AutoReload then
					tryAutoReload();
				end
				
			end
			
			updateAmmoCounter();
			properties.CanPrimaryFire = true;
		end
	end
	
	local function PrimaryFireRequest()
		spawn(function()
			if not characterProperties.CanAction then return end;
			if properties.Reloading then
				if configurations.ReloadMode == modAttributes.ReloadModes.Single and properties.Ammo > 0 then
					bindReloadYield:Fire(2);
				else
					return;
				end 
			end
			
			if properties.CanPrimaryFire then primaryFire(); end;
		end); -- Switching this to coroutine will cause mouse1down false issues.
	end;
	
	local function ReloadRequest()
		if not equipped or unequiped then return end;
		if not properties.Reloading then 
			reload();
		else 
			playWeaponSound(audio.Empty.Id);
		end
		
		updateAmmoCounter();
		if configurations.OnAmmoUpdate then configurations.OnAmmoUpdate(mainWeaponModel, modWeaponModule, properties.Ammo); end
	end;
	
	local function InspectRequest() 
		if not properties.Reloading and not properties.IsPrimaryFiring then
			Equipped.RightHand.Data.LerpBody = false;
			
			if sightViewModel then
				editPanelVisible = not editPanelVisible;
			end
			--if objects.Right and objects.Right.SightViewModel then
			--	editPanelVisible = not editPanelVisible;
			--end
			
			local roll = random:NextInteger(1,10);
			if loadedAnims["Inspect2"] and roll >= 7 then
				loadedAnims["Inspect2"]:Play();
				loadedAnims["Inspect2"].Stopped:Wait();
			else
				loadedAnims["Inspect"]:Play();
				loadedAnims["Inspect"].Stopped:Wait();
			end
			
			Equipped.RightHand.Data.LerpBody = true;
		end
	end
	
	local function SpecialRequest()
		Debugger:Warn("Special Request");
		return true;
	end
	
	if configurations.UseViewModel == false then
		characterProperties.UseViewModel = false;
	end
	if configurations.CustomViewModel then
		characterProperties.CustomViewModel = configurations.CustomViewModel;
	end
	
	Equipped.RightHand["KeyFire"] = PrimaryFireRequest;
	Equipped.RightHand["KeyReload"] = ReloadRequest;
	Equipped.RightHand["KeyInspect"] = InspectRequest;
	Equipped.RightHand["KeyToggleSpecial"] = SpecialRequest;
	
	local function ToggleSpecialRequest()
		local modInfo = modWeaponModule.ModHooks.PrimaryEffectMod;
		
		if modInfo == nil then return end;

		local storageItemOfMod = modData.GetItemById(modInfo.StorageItemID);
		local modLib = modInfo.Library;
		
		if modLib.EffectTrigger == modModsLibrary.EffectTrigger.Passive then
			return;
		end

		if storageItemOfMod and storageItemOfMod.Values then
			local timelapsed = modSyncTime.GetTime() - (storageItemOfMod.Values.AT or 0);

			if timelapsed > modLib.ActivationDuration+modLib.CooldownDuration then
				if modLib.ActivateSound == nil then
					playWeaponSound("ToggleDigital");

				else
					playWeaponSound(modLib.ActivateSound);

				end

			elseif timelapsed > modLib.ActivationDuration then
				modInterface:HintWarning(modLib.Name .." is on cooldown..");

			else
				modInterface:HintWarning(modLib.Name .." is already active!");

			end
		end
		
		return modInfo;
	end
	
	function Equipped.RightHand:OnInputEvent(inputData)
		if inputData.InputType ~= "Begin" then return end;
		
		if modKeyBindsHandler:Match(inputData.InputObject, "KeyToggleSpecial") then
			inputData.PrimaryEffectMod = ToggleSpecialRequest();
			return true;
		end;

		return;
	end

	if modWeaponModule.ModHooks.PrimaryEffectMod then
		local storageItemOfMod = modData.GetItemById(modWeaponModule.ModHooks.PrimaryEffectMod.StorageItemID);
		local modLib = modModsLibrary.Get(storageItemOfMod.ItemId);

		if modLib.EffectTrigger == modModsLibrary.EffectTrigger.Passive then
			
			
		elseif modLib.EffectTrigger == modModsLibrary.EffectTrigger.Activate then
			if UserInputService.TouchEnabled then
				touchItemPrompt.Image = modLib.Icon;
				itemPromptButton.Visible = true;

				if itemPromptConn then itemPromptConn:Disconnect(); end
				itemPromptConn = itemPromptButton.MouseButton1Click:Connect(function()
					local inputData = {
						InputType = "Begin";
						KeyIds = {
							KeyToggleSpecial=true;
						}
					}
					inputData.PrimaryEffectMod = ToggleSpecialRequest();

					inputData.Action = "input";
					remoteToolInputHandler:Fire(modRemotesManager.Compress(inputData));
					
				end)
			end
			
		end
	end
	
	Equipped.RightHand.Unequip = function()
		equipped = false;
		unequiped = true;
		
		task.spawn(function()
			for _, obj in pairs(camera:GetChildren()) do
				if obj:GetAttribute("WeaponAudio") then
					obj:Destroy();
				end
			end
		end)
		
		if loadedAnims["Unequip"] then
			loadedAnims["Unequip"]:Play();
		end;
		
		game.Debris:AddItem(arcDisk, 0);
		for _, obj in pairs(CollectionService:GetTagged("AdsTrajectory")) do
			obj:Destroy();
		end
		table.clear(arcList);
		
		if sightViewModel then
			configurations.AimDownViewModel = sightViewModel.CFrame;
		end

		characterProperties.UseViewModel = true;
		scopeFrame.Visible = false;
		
		bindReloadYield:Fire(2);
		for k, track in pairs(loadedAnims) do
			modCharacter:RemoveAnimation(k);
			
			if k ~= "Unequip" then
				track:Stop();
			end
		end
		
		weaponInterface:Destroy();

		modData.OnAmmoUpdate:DisconnectAll();
		characterProperties.Joints.WaistY = 0;
		characterProperties.CustomViewModel = nil;
		characterProperties.AimDownSights = false;
		modCharacter.DevViewModel = nil;
		modCharacter.EquippedTool = nil;
	end
	
	updateValues();
	updateAmmoCounter();
	if modWeaponMechanics.EquipUpdateExperience and not modConfigurations.DisableExperiencebar then
		modData.UpdateProgressionBar(
			(storageItem.Values.E or 0)/(storageItem.Values.EG or 100), 
			"WeaponLevel", 
			storageItem.Values.L
		);
	end;
	
	if configurations.OnAmmoUpdate then
		configurations.OnAmmoUpdate(mainWeaponModel, modWeaponModule, properties.Ammo);
	end
	
	RunService:BindToRenderStep("WeaponRender", Enum.RenderPriority.Camera.Value, weaponRender);
	
	for key, animLib in pairs(animations) do
		local animationId = "rbxassetid://"..(animations[key].OverrideId or animations[key].Id);
		local animationFile: Animation = animationFiles[animationId] or Instance.new("Animation");
		animationFile.AnimationId = animationId;
		animationFile.Parent = humanoid;
		animationFiles[animationId] = animationFile;
		
		if loadedAnims[key] then loadedAnims[key]:Stop(); end
		local track: AnimationTrack = animator:LoadAnimation(animationFile);
		
		if animLib.Looped ~= nil then
			track.Looped = animLib.Looped == true;
		end
		
		loadedAnims[key] = track;
		
		track:SetAttribute("FocusWeight", animLib.FocusWeight or 0.2);
		track:SetAttribute("StopOnAction", animLib.StopOnAction);
		track:SetAttribute("LoopMarker", animLib.LoopMarker);
		
		track.Name = weaponId..":"..key;
		
		if key ~= "Core" then
			track.Priority = Enum.AnimationPriority.Action2;
			
			if key:find("PrimaryFire") == nil then
				modCharacter:AddAnimation(key, loadedAnims[key]);
			end
			if string.lower(key):find("load") then
				track.Priority = Enum.AnimationPriority.Action3;
			end
			if key == "FocusCore" then
				track.Priority = Enum.AnimationPriority.Action3;
			end
		end
		if key == "Sprint" then
			track.Priority = Enum.AnimationPriority.Action3;
		end
		
		track:GetMarkerReachedSignal("PlaySound"):Connect(function(paramString)
			--print(key," Animation PlaySound Marker:",paramString)
			playWeaponSound(paramString);
		end)
		
		local magazine = mainWeaponModel:FindFirstChild("Magazine");
		if magazine then
			local magazineParts = {magazine};
			
			for _, obj in pairs(magazine:GetChildren()) do
				if obj:IsA("Motor6D") then
					if obj.Part1 then
						table.insert(magazineParts, obj.Part1);
					end
				end
			end
			
			track:GetMarkerReachedSignal("DropMagCopy"):Connect(function(paramString)
				--print(key," Animation DropMagCopy Marker:",paramString);
				
				local new = magazine:Clone();
				new.Transparency = 0;
				new.CFrame = magazine.CFrame;
				new.CanCollide = true;
				new.Parent = workspace.Debris;
				new:BreakJoints();
				game.Debris:AddItem(new, 20);
			end)
			track:GetMarkerReachedSignal("HideMag"):Connect(function(paramString)
				--print(key," Animation HideMag Marker:",paramString);
				
				for a=1, #magazineParts do
					if magazineParts[a]:GetAttribute("OriginalTransparency") == nil then
						magazineParts[a]:SetAttribute("OriginalTransparency", magazineParts[a].Transparency);
					end
					magazineParts[a].Transparency = 1;
				end
			end)
			track:GetMarkerReachedSignal("ShowMag"):Connect(function(paramString)
				--print(key," Animation ShowMag Marker:",paramString);
				
				for a=1, #magazineParts do
					local oT = magazineParts[a]:GetAttribute("OriginalTransparency") or 0;
					magazineParts[a].Transparency = oT;
				end
			end)
		end
		
		track:GetMarkerReachedSignal("CloneDebris"):Connect(function(paramString)
			local args = string.split(tostring(paramString), ";");
			
			local toolModel = args[1] == "Left" and leftWeaponModel or rightWeaponModel;
			local partObj = args[2] and toolModel and toolModel:FindFirstChild(args[2]);
			
			if partObj then
				local new = partObj:Clone();
				
				if partObj:IsA("Model") then
					new:PivotTo(partObj:GetPivot());
					for _, obj in pairs(new:GetChildren()) do
						if not obj:IsA("BasePart") then continue end;
						obj.CanCollide = true;
						obj.Transparency = 0;
					end
					
				elseif partObj:IsA("BasePart") then
					new.Transparency = 0;
					new.CFrame = partObj.CFrame;
					new.CanCollide = true;
					
				end
				
				
				new.Parent = workspace.Debris;
				new:BreakJoints();
				game.Debris:AddItem(new, 20);
			end
		end)
		
		track:GetMarkerReachedSignal("SetTransparency"):Connect(function(paramString)
			local args = string.split(tostring(paramString), ";");
			
			local toolModel = args[1] == "Left" and leftWeaponModel or rightWeaponModel;
			local partObj = args[2] and toolModel and toolModel:FindFirstChild(args[2]);
			local transparencyValue = partObj and args[3];

			if transparencyValue then
				local function setTransparency(obj)
					if obj:IsA("BasePart") then
						obj.Transparency = obj:GetAttribute("CustomTransparency") or transparencyValue;
						for _, child in pairs(obj:GetChildren()) do
							if child:IsA("Decal") or child:IsA("Texture") then
								child.Transparency = transparencyValue;
							end
						end
						
					elseif obj:IsA("Model") then
						for _, child in pairs(obj:GetChildren()) do
							setTransparency(child);
						end
					end
				end
				
				setTransparency(partObj);
			end
		end)
		
		local fakeMotors;
		track:GetMarkerReachedSignal("NewFake"):Connect(function(paramString)
			if fakeMotors == nil then
				fakeMotors = {};
				
				if leftWeaponModel then
					for _, obj in pairs(leftWeaponModel:GetDescendants()) do
						if obj:IsA("Motor6D") and obj.Name:sub(1, 4) == "Fake" then
							fakeMotors[obj.Name] = obj;
						end
					end
				end
				
				if rightWeaponModel then
					for _, obj in pairs(rightWeaponModel:GetDescendants()) do
						if obj:IsA("Motor6D") and obj.Name:sub(1, 4) == "Fake" then
							fakeMotors[obj.Name] = obj;
						end
					end
				end
			end
			
			local args = string.split(tostring(paramString), ";");

			local toolModel = args[1] == "Left" and leftWeaponModel or rightWeaponModel;
			local partObj = args[2] and toolModel and toolModel:FindFirstChild(args[2]);

			if partObj then
				local objName = partObj.Name;
				local fakeMotor = fakeMotors["Fake"..objName];
				
				toolModel:FindFirstChild("Fake"..objName):Destroy();

				if fakeMotor then
					local new = partObj:Clone();
					new.Name = "Fake"..objName;
					new.Transparency = 0;
					new.Parent = toolModel;
					fakeMotor.Part1 = new;

				else
					Debugger:Warn("WeaponAnim(",key,") NewFake missing fake motor for:",objName);
				end
			end
		end)
		
		
		track:GetMarkerReachedSignal("FireLoop"):Connect(function(paramString)
			if paramString == "Start" and track:GetAttribute("LoopStart") == nil then
				track:SetAttribute("LoopStart", track.TimePosition);
				
			elseif paramString == "End" then
				if track:GetAttribute("LoopEnd") == nil then
					track:SetAttribute("LoopEnd", track.TimePosition);
				end
				
				if mouseProperties.Mouse1Down and track:GetAttribute("LoopStart") then
					track.TimePosition = track:GetAttribute("LoopStart");
				end
			end
		end)
		if animLib.LoopMarker then
			track:Play(0, 0.001);
		end
		
		track:GetMarkerReachedSignal("Event"):Connect(function(paramString)
			if configurations.OnMarkerEvent ~= nil then
				configurations.OnMarkerEvent({Left=leftWeaponModel; Right=rightWeaponModel;}, key, paramString);
			end
		end)

		track:GetMarkerReachedSignal("ShellEject"):Connect(function(paramString)
			local objectTable = paramString == "Left" and objects.Left or objects.Right;
			if configurations.BulletEject and objectTable.CaseOutPoint and modData:GetSetting("DisableParticle3D") ~= 1 then
				ejectShell(objectTable);
			end
		end)
	end

	loadedAnims["Core"]:Play();

	local equipTimeReduction = classPlayer:GetBodyEquipment("EquipTimeReduction");
	local equipTime = configurations.EquipLoadTime;
	if equipTimeReduction then
		equipTime = equipTime * math.clamp(equipTimeReduction, 0, 1);
	end
	
	local selectedLoadAnim = loadedAnims["Load"];
	
	if loadedAnims["Load2"] and math.random(1, 10) <= 3 then
		selectedLoadAnim = loadedAnims["Load2"];
	end
	
	if configurations.DoCustomLoad then
		local animId = configurations.DoCustomLoad(modWeaponModule, storageItem, objects);
		selectedLoadAnim = loadedAnims[animId];
	end
	
	if selectedLoadAnim then
		selectedLoadAnim:AdjustSpeed(selectedLoadAnim.Length/ math.max(equipTime-0.2, 0.2));
		selectedLoadAnim:Play();
	end
	
	if audio.Load then
		playWeaponSound(audio.Load.Id);
	end
	
	characterProperties.HideCrosshair = true;
	modCharacter.EquippedTool = mainWeaponModel;

	task.delay(equipTime, function()
		if unequiped then return end;
		updateValues();
		updateAmmoCounter();
		properties.CanPrimaryFire = true;
		properties.CanAimDown = true;
		equipped = true;
	end);
	
	local modInfo = modWeaponModule.ModHooks.PrimaryEffectMod;
	if modInfo and UserInputService.KeyboardEnabled then
		if modInfo.Library.EffectTrigger == modModsLibrary.EffectTrigger.Passive then
			
			
		elseif modInfo.Library.EffectTrigger == modModsLibrary.EffectTrigger.Activate then
			activateModHint.Visible = true;
			task.delay(1, function()
				activateModHint.Visible = false;
			end)
			
		end
	end
	
end

function WeaponHandler:Unequip(id)
	if modWeaponMechanics.EquipUpdateExperience and not modConfigurations.DisableExperiencebar then modData.UpdateProgressionBar(); end;
	
	RunService:UnbindFromRenderStep("WeaponRender");
	modFlashlight:Destroy();
	characterProperties.FieldOfView = nil;
	characterProperties.SwayYStrength=1;
	characterProperties.VelocitySrength=1;
	characterProperties.ViewModel = characterProperties.DefaultViewModel;
	characterProperties.AdsWalkSpeedMultiplier = nil;
	
	for key, equipment in pairs(Equipped) do
		if typeof(equipment) == "table" and equipment.Item and equipment.Item.ID == id then
			if equipment.Unequip then equipment.Unequip(); end
			Equipped[key] = {Data={};};
		end;
	end
	
	characterProperties.HideCrosshair = false;
end

function WeaponHandler:Initialize(equipped)
	Equipped = equipped;
end

remoteReloadWeapon.OnClientEvent:Connect(function(paramPacket)
	if Equipped == nil then return end;
	if Equipped.Id ~= paramPacket.Id then
		return;
	end;
	
	--Debugger:Warn("remoteReloadWeapon", paramPacket);

	local modWeaponModule = modData:GetItemClass(paramPacket.Id);
	local properties = modWeaponModule.Properties;

	local _unixTime = paramPacket.UnixTime;
	
	if paramPacket.MA then
		properties.MaxAmmo = paramPacket.MA;
	end
	
	if paramPacket.A then
		properties.Ammo = paramPacket.A;
	end
end)

return WeaponHandler;