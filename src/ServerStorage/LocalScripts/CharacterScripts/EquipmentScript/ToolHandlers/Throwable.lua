local ToolHandler = {}

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);

local character = script.Parent.Parent.Parent;
local humanoid = character:WaitForChild("Humanoid");
local animator = humanoid:WaitForChild("Animator");
local player = game.Players.LocalPlayer;

--== Modules;
local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();
local modInterface = modData:GetInterfaceModule();

local modFlashlight = require(script.Parent.Parent:WaitForChild("Flashlight"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modArcTracing = require(game.ReplicatedStorage.Library.ArcTracing);
local modWeaponMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);

--== Remotes;
local remoteToolPrimaryFire = modRemotesManager:Get("ToolHandlerPrimaryFire");

--== Vars;
local mouseProperties = modCharacter.MouseProperties;
local characterProperties = modCharacter.CharacterProperties;

local Equipped;
local animationFiles = {};

local projRaycast = RaycastParams.new();
projRaycast.FilterType = Enum.RaycastFilterType.Include;
projRaycast.IgnoreWater = true;
projRaycast.CollisionGroup = "Raycast";

local arcPartTemplate = Instance.new("Part");
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
--== Script;

function ToolHandler:Equip(storageItem, toolModels)
	local itemId = storageItem.ItemId;
	local toolLib = modTools[itemId];
	local toolConfig = toolLib.NewToolLib();
	
	local toolModel = Equipped.RightHand.Prefab or Equipped.LeftHand.Prefab;
	local handle = toolModel and toolModel:WaitForChild("Handle") or nil;
	
	local audio = toolLib.Audio;
	local animations = {};

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
		animations["Load"]:Play(0);
		if toolConfig.OnAnimationPlay then
			task.defer(function()
				toolConfig.OnAnimationPlay("Load", ToolHandler, toolModel);
			end)
		end
	end
	
	if toolConfig.UseViewmodel == false then
		characterProperties.UseViewModel = false;
	end
	if toolConfig.CustomViewModel then
		characterProperties.CustomViewModel = toolConfig.CustomViewModel;
	end
	
	Equipped.ToolConfig = toolConfig;
	
	local rootPart = modCharacter.RootPart;
	local head = character.Head;
	local mouseProperties = modCharacter.MouseProperties;
	local configurations = toolConfig.Configurations;

	local arcList = {};
	local arcTracer = modArcTracing.new();
	arcTracer.Bounce = configurations.ProjectileBounce;
	arcTracer.LifeTime = configurations.ProjectileLifeTime;
	arcTracer.Acceleration = configurations.ProjectileAcceleration;
	arcTracer.KeepAcceleration = configurations.ProjectileKeepAcceleration
	arcTracer.IgnoreWater = configurations.IgnoreWater;
	arcTracer.Delta = 1/60;
	
	table.insert(arcTracer.RayWhitelist, workspace.Entity);
	table.insert(arcTracer.RayWhitelist, workspace:FindFirstChild("Characters"));
	local charactersList = CollectionService:GetTagged("PlayerCharacters");
	if charactersList then for a=1, #charactersList do
			if charactersList[a] ~= character then table.insert(arcTracer.RayWhitelist, charactersList[a]); end
	end end
	
	local arcDisk = landPartTemplate:Clone();
	
	Equipped.RightHand.Unequip = function()
		if toolConfig.DisableMovement then
			characterProperties.CanMove = true;
		end
		characterProperties.UseViewModel = true;
		characterProperties.CustomViewModel = nil;
		characterProperties.FieldOfView = nil;
		for key, _ in pairs(animations) do animations[key]:Stop(); end;
		
		modCharacter.EquippedTool = nil;
		characterProperties.Joints.WaistY = 0;
		
		arcDisk:Destroy();
		for _, obj in pairs(CollectionService:GetTagged("ThrowableArc")) do
			obj:Destroy();
		end
		arcList = {};
	end
	
	local initThrow = false;
	local throwChargeTick, progressBarTick;
	local throwChargeValue = 0;
	
	local function updateProgressionBar(p)
		p = p or 0;
		if progressBarTick == nil or tick()-progressBarTick > 0.1 then
			progressBarTick = tick();
			modData.UpdateProgressionBar(p, "Throw");
		end
	end
	
	local function reset()
		throwChargeTick = nil;
		progressBarTick = nil;
		throwChargeValue = 0;
		updateProgressionBar();
	end
	
	local toggleTraj = false;
	local function getImpactPoint(origin) -- reasonable throw ranges [25, 80];
		local rayWhitelist = CollectionService:GetTagged("TargetableEntities") or {};
		table.insert(rayWhitelist, workspace.Environment);
		table.insert(rayWhitelist, workspace.Characters);
		table.insert(rayWhitelist, workspace.Terrain);
		projRaycast.FilterDescendantsInstances = rayWhitelist;

		local velocity = (configurations.Velocity + configurations.VelocityBonus * throwChargeValue);

		local scanPoint = modWeaponMechanics.CastHitscanRay{
			Origin = mouseProperties.Focus.p;
			Direction = mouseProperties.Direction;
			IncludeList = rayWhitelist;
			Range = velocity;
		};

		local newDirection = (scanPoint-origin).Unit;
		local distance = (scanPoint-origin).Magnitude;

		-- Gets where player can hit.
		-- Get hitscan point from head using direction provided by crosshair hitscan.
		local impactPoint = modWeaponMechanics.CastHitscanRay{
			Origin = origin;
			Direction = newDirection;
			IncludeList = rayWhitelist;
			Range = distance;
		};

		return impactPoint;
	end

	local throwOrigin = toolConfig.CustomThrowPoint and toolModel[toolConfig.CustomThrowPoint] or handle;
	local function primaryThrow()
		storageItem = modData.GetItemById(storageItem.ID);
		if storageItem == nil then return end;
		
		toolConfig.CanThrow = false;
		
		local throwCharge = throwChargeValue > 0.05 and throwChargeValue or 0;

		local origin = handle.Position;
		local impactPoint = getImpactPoint(head.Position);

		animations["Throw"]:Play(0.1);
		if audio.Throw then
			modAudio.PlayReplicated(audio.Throw.Id, throwOrigin);
		end
		
		task.delay(0.05, function()
			if animations["Reload"] == nil then
				throwOrigin.Transparency = 1;
			end
			
			if toolConfig.OnThrow then
				toolConfig.OnThrow(self, toolModels);
			end
		end)
		remoteToolPrimaryFire:FireServer(storageItem.ID, origin, impactPoint, throwCharge);
		
		if storageItem.Quantity <= 1 and configurations.ConsumeOnThrow then
			--ToolHandler:Unequip(storageItem);
		else
			if animations["Reload"] then
				throwOrigin.Transparency = 0;
				animations["Reload"]:Play();
				if toolConfig.OnAnimationPlay then
					task.defer(function()
						toolConfig.OnAnimationPlay("Reload", ToolHandler, toolModel);
					end)
				end
			end
			wait(configurations.ThrowRate or 0.2);
			throwOrigin.Transparency = 0;
			toolConfig.CanThrow = true;
			if toolConfig.OnThrowComplete then
				toolConfig.OnThrowComplete(self, toolModels);
			end
		end
	end
	
	local quickThrown = false;
	RunService:BindToRenderStep("Throwable", Enum.RenderPriority.Character.Value, function()
		if modKeyBindsHandler:IsKeyDown("KeyFire") and characterProperties.CanAction and characterProperties.IsEquipped then

			if configurations.ChargeDuration then
				if toolConfig.CanThrow then
					if not initThrow then
						if audio.Charge then
							modAudio.PlayReplicated(audio.Charge.Id, handle);
						end
					end
					initThrow = true;
				end
				if throwChargeTick == nil or not toolConfig.CanThrow then
					throwChargeTick = tick();
				else
					throwChargeValue = math.clamp((tick()-throwChargeTick) / configurations.ChargeDuration, 0, 1);
					if throwChargeValue > 0.05 then
						if not animations["Charge"].IsPlaying then
							animations["Charge"]:Play(nil, nil, 0);
						end
						animations["Charge"].TimePosition = animations["Charge"].Length * throwChargeValue;
					end
					updateProgressionBar(throwChargeValue);

				end
				characterProperties.Joints.WaistY = configurations.WaistRotation;
				
			else
				if toolConfig.CanThrow then
					initThrow = true;
				end
			end
			
			if toggleTraj then -- disable trajectory
				local origin = handle.Position;
				local impactPoint = getImpactPoint(head.Position);
				game.Debris:AddItem(Debugger:PointPart(impactPoint), 0.1);
				
				local velocity = (configurations.Velocity + configurations.VelocityBonus * throwChargeValue);

				local travelTime = (impactPoint-origin).Magnitude/velocity;
				local velocityToImpact = arcTracer:GetSteppedVelocityByTime(origin, impactPoint, travelTime);

				local arcPoints = arcTracer:GeneratePath(handle.Position, velocityToImpact);
				if #arcList ~= #arcPoints then
					while #arcList <= #arcPoints do
						local arcPart = arcPartTemplate:Clone();
						CollectionService:AddTag(arcPart, "ThrowableArc");
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
					
					local order = math.clamp(1 - (a/#arcList * 0.7), 0.5, 1);
					arcPart.Parent = workspace.CurrentCamera;
					arcPart.Size = Vector3.new(0.01, 0.01, arcPoint.Displacement);
					arcPart.Transparency = 0;
					arcPart.CFrame = CFrame.new(arcPoint.Origin, arcPoint.Point) * CFrame.new(0, 0, -arcPoint.Displacement/2);
					
					if a == #arcList and arcPoint.Normal then
						arcDisk.Parent = workspace.CurrentCamera;
						arcDisk.CFrame = CFrame.new(arcPoint.Point, arcPoint.Point + arcPoint.Normal) * CFrame.Angles(math.pi/2, 0, 0);
					end
				end
			end
		else
			if configurations.ChargeDuration then
				if animations["Charge"].IsPlaying and initThrow then
					animations["Charge"].TimePosition = animations["Charge"].Length;
				end
				
				characterProperties.Joints.WaistY = 0;
				animations["Charge"]:Stop();
				
				if initThrow then
					initThrow = false;
					primaryThrow();
				end

				reset();
			else
				if initThrow and not quickThrown then
					initThrow = false;
					primaryThrow();
					quickThrown = true;
					delay(0.1, function()
						quickThrown = false;
					end)
				end
			end
			
			arcDisk.Parent = nil;
			for _, obj in pairs(CollectionService:GetTagged("ThrowableArc")) do
				obj:Destroy();
			end
			arcList = {};
		end
	end)
	
	if toolConfig.OnToolEquip then
		task.defer(function()
			toolConfig.OnToolEquip(ToolHandler, toolModel);
		end)
	end
	
	delay(toolConfig.LoadTime or 0.5, function()
		toolConfig.CanThrow = true;
		if toolConfig.OnLoad then
			toolConfig.OnLoad(self, toolModels);
		end
	end)

	
	if RunService:IsStudio() then
		Equipped.RightHand["KeyWalk"] = function()
			toggleTraj = not toggleTraj;
			local tracks = animator:GetPlayingAnimationTracks();
			
			Debugger:Warn("animator", tracks);
			for _, track in pairs(tracks) do
				Debugger:Warn(track, "WeightCurrent", track.WeightCurrent, "WeightTarget", track.WeightTarget);
			end
		end
	end

end

function ToolHandler:Unequip(storageItem)
	RunService:UnbindFromRenderStep("Throwable");
	modFlashlight:Destroy();
	modData.UpdateProgressionBar();
	characterProperties.HideCrosshair = false;
	for key, equipment in pairs(Equipped) do
		if typeof(equipment) == "table" and equipment.Item and equipment.Item.ID == storageItem.ID then
			if equipment.Unequip then equipment.Unequip(); end
			Equipped[key] = {Data={};};
		end;
	end
	Equipped = nil;
end

function ToolHandler:Initialize(equipped)
	if Equipped ~= nil then return end;
	Equipped = equipped;
end

return ToolHandler;