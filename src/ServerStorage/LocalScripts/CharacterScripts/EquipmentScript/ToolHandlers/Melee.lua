local ToolHandler = {}

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local UserInputService = game:GetService("UserInputService");

local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

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
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modArcTracing = require(game.ReplicatedStorage.Library.ArcTracing);
local modWeaponMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modToolAnimator = require(script.Parent.Parent.ToolAnimator);

local modVector = require(game.ReplicatedStorage.Library.Util.Vector);

--== Remotes;
local remoteToolPrimaryFire = modRemotesManager:Get("ToolHandlerPrimaryFire");
local remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler");

--== Vars;
local mouseProperties = modCharacter.MouseProperties;
local characterProperties = modCharacter.CharacterProperties;

local Equipped;
local animationFiles = {};
local random = Random.new();
local classPlayer = modPlayers.GetByName(player.Name);

local BaseStats = {
	MaxStamina = 100;
	DeficiencyStart = 0.2;
	RecoveryRecoveryRate = 25;
	RecoveryRecoveryDelay = 5;
};

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

local throwChargeValue = 0;
local Stats = setmetatable({Stamina = 0; SubStamina = 0;}, {__index=BaseStats;});
local nextAttackTick = tick()-5;

modData.MeleeStats = Stats;
--== Script;
ToolHandler.StaminaStats = Stats;

function ToolHandler:Equip(storageItem, toolModels)
	local itemId = storageItem.ItemId;
	local toolLib = modTools[itemId];
	local toolConfig = toolLib.NewToolLib();
	local itemLib = modItemsLibrary:Find(itemId);

	local rootPart = modCharacter.RootPart;
	local configurations = toolConfig.Configurations;
	local properties = toolConfig.Properties;
	local audio = toolLib.Audio;
	
	for k, audioData in pairs(audio) do
		modAudio.Preload(audioData.Id);
	end
	
	local meleeMode = configurations.Mode or "Swing";
	
	local comboCounter = 0;
	local comboTick = nil;
	
	Equipped.Connections = {};
	Equipped.Cache = {};
	
	local unequiped = false;
	local equipped = false;
	
	local arcList, arcDisk = {}, nil;
	local toolModel = Equipped.RightHand.Prefab;

	local handle = toolModel and toolModel:WaitForChild("Handle") or nil;
	local collider = toolModel and toolModel:WaitForChild("Collider") or nil;

	local head = character:WaitForChild("Head");

	local toolAnimator = modToolAnimator.new(animator);
	toolAnimator:LoadToolAnimations(toolLib.Animations, toolConfig.DefaultAnimatorState or "");

	Equipped.ToolAnimator = toolAnimator;
	toolAnimator:Play("Core", {FadeTime=0.5});
	
	characterProperties.HideCrosshair = false;
	if toolConfig.UseViewmodel == false then
		characterProperties.UseViewModel = false;
	end
	
	Equipped.RightHand.Unequip = function()
		equipped = false;
		unequiped = true;

		characterProperties.HideCrosshair = false;
		characterProperties.UseViewModel = true;

		toolAnimator:Destroy();

		modCharacter.EquippedTool = nil;
		characterProperties.Joints.WaistY = 0;

		toolAnimator:Play("Unequip");

		if configurations.Throwable then
			arcDisk:Destroy();
			for _, obj in pairs(CollectionService:GetTagged("ThrowableArc")) do
				obj:Destroy();
			end
			arcList = {};
		end
		
		if modData.ItemPromptConn then
			modData.ItemPromptConn:Disconnect();
		end
	end

	local colliderOverlapParams = OverlapParams.new();
	colliderOverlapParams.MaxParts = 4;
	
	local function onKeyFrameReached(keyframe)
		Debugger:Warn("Using deprecated keyframe waist rotation.");
		if keyframe:sub(1, 14) == "WaistRotation:" then
			local waist = tonumber(keyframe:sub(15, #keyframe));
			if waist then
				characterProperties.Joints.WaistY = math.rad(waist);
			end
			
		end
	end
	
	local function setWaistMarker(paramString)
		local waist = tonumber(paramString);
		if waist then
			characterProperties.Joints.WaistY = math.rad(waist);
		end
		if modBranchConfigs.CurrentBranch.Name == "Dev" then
			Debugger:Warn("[Dev] Set WaistRotation ", waist);
		end
	end

	-- table.insert(Equipped.Connections, animations["PrimaryAttack"]:GetMarkerReachedSignal("SetWaist"):Connect(setWaistMarker));
	-- if animations["PrimaryAttack2"] then
	-- 	table.insert(Equipped.Connections, animations["PrimaryAttack2"]:GetMarkerReachedSignal("SetWaist"):Connect(setWaistMarker));
	-- end;
	-- -- OLD
	-- table.insert(Equipped.Connections, animations["PrimaryAttack"].KeyframeReached:Connect(onKeyFrameReached));
	-- if animations["PrimaryAttack2"] then
	-- 	table.insert(Equipped.Connections, animations["PrimaryAttack2"].KeyframeReached:Connect(onKeyFrameReached));
	-- end;
	-- --
	
	Equipped.Cache.HitCache = {};
	
	local victims = {};
	local function onColliderTouch(hitPart)
		local model = hitPart.Parent;
		if model == nil then return end;

		local npcStatus = model:FindFirstChild("NpcStatus");
		local humanoid = hitPart.Parent:FindFirstChildWhichIsA("Humanoid") or hitPart.Parent.Parent:FindFirstChildWhichIsA("Humanoid");
		
		if humanoid or npcStatus then
			task.spawn(function()
				if modInterface.modEntityHealthHudInterface then
					modInterface.modEntityHealthHudInterface.TryHookEntity(humanoid.Parent);
				end
			end)
			
			local key = humanoid or npcStatus;
			if victims[key] == nil then
				victims[key] = true;
				
				if modConfigurations.PvpMode then
					return;
				end
				
				local playedImpactSound = modWeaponMechanics.ImpactSound{
					Enemy=true;
					BasePart=hitPart;
					Point=collider.Position;
					HideMolten=true;
				}
				
				if not playedImpactSound and audio.PrimarySwing then
					-- local snd = modAudio.PlayReplicated(audio.PrimaryHit.Id, handle, nil, audio.PrimarySwing.Pitch, audio.PrimarySwing.Volume);
					-- if snd then
					-- 	snd.PlaybackSpeed = math.random(audio.PrimarySwing.Pitch*10-1, audio.PrimarySwing.Pitch*10+1)/10
					-- end
				end
			end
			
		else
			if Equipped.Cache.HitCache[model] == nil then
				Equipped.Cache.HitCache[model] = true;
				
				task.delay(Equipped.Cache.AttRate or 0.5, function()
					if Equipped == nil or unequiped then return end;
					Equipped.Cache.HitCache[model] = nil;
				end)
				
				modWeaponMechanics.ImpactSound{
					BasePart=hitPart;
					Point=collider.Position;
					HideMolten=true;
				}
			end
		end
	end
	
	local meleeFuryBonus = 0;
	local function PrimaryFireRequest(...)
		if toolConfig.RoleplayStateWindow and modInterface:IsVisible(toolConfig.RoleplayStateWindow) then
			return;
		end
		
		if not characterProperties.CanAction then return end;
		if configurations.Throwable and characterProperties.IsFocused then return end;
		
		if meleeMode == "Swing" then
			if properties.Attacking then return end;
			if tick()-nextAttackTick < 0 then return end;
			Stats.LastDrain = tick();
			--animations["Inspect"]:Stop();
			toolAnimator:Stop("Inspect");

			victims = {};
			properties.Attacking = true;
			
			local playerBodyEquipments = classPlayer.Properties and classPlayer.Properties.BodyEquipments;
			local staminaCost = (configurations.StaminaCost or 10);

			local deficiency = 1;
			local defill = Stats.MaxStamina*Stats.DeficiencyStart;
			
			if Stats.Stamina < defill then
				local a = 1-math.clamp(Stats.Stamina/defill, 0, 1);
				deficiency = 1 + (configurations.StaminaDeficiencyPenalty or 0.5) * a;
			end
			if Stats.SubStamina > 0 then
				deficiency = deficiency + (Stats.SubStamina/Stats.MaxStamina);
			end
			
			local function primaryAttack(comboIndex)
				remoteToolPrimaryFire:FireServer(storageItem.ID, comboIndex);
				if audio.PrimarySwing then
					modAudio.PlayReplicated(audio.PrimarySwing.Id, handle, nil, audio.PrimarySwing.Pitch, audio.PrimarySwing.Volume);
				end
				
				if comboIndex and toolAnimator:GetTracks(`ComboAttack{comboIndex}`) then
					--characterProperties.CanMove = false;

					local comboInfo = configurations.Combos[comboIndex];
					local animationId = "ComboAttack"..comboIndex;

					modCharacter.CharacterProperties.SpeedMulti:Set("melee", 0.6, 2);
					modCharacter.UpdateWalkSpeed();

					local track = toolAnimator:Play(animationId, {FadeTime=0;});
					track:AdjustWeight(1,0);
					track:AdjustSpeed(track.Length / comboInfo.AnimationSpeed);
					
					local onAnimFinish
					onAnimFinish = track.Stopped:Connect(function() 
						onAnimFinish:Disconnect();
						modCharacter.CharacterProperties.SpeedMulti:Remove("melee");
					end)
					return;
				end
				
				local track = toolAnimator:Play("PrimaryAttack");
				track:AdjustWeight(1, 0);
				if configurations.PrimaryAttackAnimationSpeed then
					track:AdjustSpeed(track.Length / configurations.PrimaryAttackAnimationSpeed);
				end
			end
			
			if configurations.HeavyAttackSpeed and toolConfig.Category == "Edged" then
				local charge = 0;
				local maxCharged = false;
				repeat
					charge = charge + RunService.Heartbeat:Wait();

					local track = toolAnimator:GetPlaying("HeavyAttack");
					if charge >= 0.15 and track == nil then
						track = toolAnimator:Play("HeavyAttack", {PlayLength=configurations.HeavyAttackSpeed*2;});
					end
					if maxCharged and track.IsPlaying then
						track.TimePosition = track.Length/2;
						track:AdjustSpeed(0);
					end
					
					maxCharged = charge >= configurations.HeavyAttackSpeed;
					
				until not mouseProperties.Mouse1Down or not characterProperties.CanAction or not characterProperties.IsEquipped;
				if not characterProperties.IsEquipped then return end;
				
				if maxCharged then
					staminaCost = staminaCost *2;
					
					local track = toolAnimator:GetPlaying("HeavyAttack");
					track:AdjustSpeed(1);
					
					remoteToolPrimaryFire:FireServer(storageItem.ID, 2);
					if audio.PrimarySwing then
						modAudio.PlayReplicated(audio.PrimarySwing.Id, handle, nil, audio.PrimarySwing.Pitch, audio.PrimarySwing.Volume);
					end
					
				else
					toolAnimator:Stop("HeavyAttack");
					primaryAttack();
				end
				
			else
				local comboIndex;
				if configurations.Combos then
					if comboTick == nil then
						comboTick = tick();
					end;
					comboCounter = comboCounter +1;
					local comboInfo = configurations.Combos[comboCounter];
					if comboInfo then
						if tick()-comboTick <= comboInfo.TimeSlot then
							comboIndex = comboCounter;
							if comboInfo.ResetCombo then
								comboCounter = 0;
								comboTick = nil;
							end
						else
							comboCounter = 0;
							comboTick = nil;
						end
					end
				end
				primaryAttack(comboIndex);
			end
			
			if Stats.Stamina <= 0 then
				local times = math.clamp(math.ceil(Stats.SubStamina/staminaCost), 1, math.huge);
				Stats.SubStamina = Stats.SubStamina + (staminaCost*times);
			end
			
			local infType = toolModel:GetAttribute("InfAmmo");
			if infType ~= nil then
				staminaCost = 0;
			end
			Stats.Stamina = math.clamp(Stats.Stamina - staminaCost, -BaseStats.RecoveryRecoveryRate, Stats.MaxStamina);
			
			local attackTime = configurations.PrimaryAttackSpeed;
			
			if meleeFuryBonus > 0 then
				attackTime = attackTime * (1-math.clamp(meleeFuryBonus, 0, 1));
			end
			
			attackTime = math.max(attackTime, 0.1);
			nextAttackTick = tick()+attackTime;
			task.wait(attackTime);
			if unequiped then return end;
			
			characterProperties.Joints.WaistY = configurations.WaistRotation;
			
			local cooldownTime = (attackTime * deficiency) - attackTime;
			wait(cooldownTime);
			properties.Attacking = false;
			
			meleeFuryBonus = 0;
			if playerBodyEquipments then
				if playerBodyEquipments.MeleeFury and modConfigurations.DisableGearMods ~= true then
					local meleeFuryBuff = classPlayer.Properties["MeleeFury"];
					local buffDuration = 5;
					if meleeFuryBuff == nil then
						local statusTable = {
							ExpiresOnDeath=true;
							Duration=buffDuration;
							Amount=1;
						};
						statusTable.Expires=modSyncTime.GetTime() + buffDuration;
						classPlayer:SetProperties("MeleeFury", statusTable);
						
					else
						meleeFuryBuff.Expires=modSyncTime.GetTime() + buffDuration;
						meleeFuryBuff.Amount = math.clamp(meleeFuryBuff.Amount + 1, 1, 5);
					end
					
					if meleeFuryBuff then
						meleeFuryBonus = meleeFuryBuff.Amount * playerBodyEquipments.MeleeFury;
					end
				end
				
				if playerBodyEquipments.AutoSwing and mouseProperties.Mouse1Down and characterProperties.CanAction then
					PrimaryFireRequest();
				end
			end
			
		elseif meleeMode == "Auto" then
			if properties.Attacking then return end;
			if tick()-nextAttackTick < 0 then return end;
			if Stats.Stamina <= 0 then return end;
			
			if Equipped.Cache["CoreLoopAudio"] then
				Equipped.Cache["CoreLoopAudio"].PlaybackSpeed = 2;
				Equipped.Cache["CoreLoopAudio"].Volume = 1;
			end
			
			if Equipped.Cache["SwingAudio"] then
				Equipped.Cache["SwingAudio"]:Stop();
			end
			if audio.PrimarySwing then
				Equipped.Cache["SwingAudio"] = modAudio.PlayReplicated(audio.PrimarySwing.Id, handle, nil, audio.PrimarySwing.Pitch, audio.PrimarySwing.Volume);
			end
			
			repeat
				if unequiped then return end;
				remoteToolPrimaryFire:FireServer(storageItem.ID);
				--animations["PrimaryAttack"]:Play(0);
				
				Stats.LastDrain = tick();
				toolAnimator:Stop("Inspect");

				victims = {};
				properties.Attacking = true;
				
				local playerBodyEquipments = classPlayer.Properties and classPlayer.Properties.BodyEquipments;
				local staminaCost = (configurations.StaminaCost or 10);

				local infType = toolModel:GetAttribute("InfAmmo");
				if infType ~= nil then
					staminaCost = 0;
				end
				Stats.Stamina = math.clamp(Stats.Stamina - staminaCost, -BaseStats.RecoveryRecoveryRate, Stats.MaxStamina);
			
				local attackTime = configurations.PrimaryAttackSpeed;
				nextAttackTick = tick()+attackTime;
				
				local hitParts = workspace:GetPartsInPart(collider, colliderOverlapParams);
				for a=1, #hitParts do
					if hitParts[a]:IsDescendantOf(character) then continue end;
					onColliderTouch(hitParts[a]);
				end
				
				if meleeFuryBonus > 0 then
					attackTime = attackTime * (1-math.clamp(meleeFuryBonus, 0, 1));
				end
				
				Equipped.Cache.AttRate = attackTime;
				task.wait(attackTime);
				if unequiped then return end;
				
				meleeFuryBonus = 0;
				
				if playerBodyEquipments then
					if playerBodyEquipments.MeleeFury and modConfigurations.DisableGearMods ~= true then
						local meleeFuryBuff = classPlayer.Properties["MeleeFury"];
						local buffDuration = 5;
						if meleeFuryBuff == nil then
							local statusTable = {
								ExpiresOnDeath=true;
								Duration=buffDuration;
								Amount=1;
							};
							statusTable.Expires=modSyncTime.GetTime() + buffDuration;
							classPlayer:SetProperties("MeleeFury", statusTable);
							
						else
							meleeFuryBuff.Expires=modSyncTime.GetTime() + buffDuration;
							meleeFuryBuff.Amount = math.clamp(meleeFuryBuff.Amount + 1, 1, 5);
						end
						
						if meleeFuryBuff then
							meleeFuryBonus = meleeFuryBuff.Amount * playerBodyEquipments.MeleeFury;
						end
					end
					
				end
				
				if not characterProperties.CanAction then break; end;
			until not mouseProperties.Mouse1Down or Stats.Stamina <= 0;
			if unequiped then return end;
			
			properties.Attacking = false;
			
			toolAnimator:Stop("PrimaryAttack", {FadeTime=0.6});

			if Equipped.Cache["CoreLoopAudio"] and audio.Core then
				Equipped.Cache["CoreLoopAudio"].PlaybackSpeed = 1;
				Equipped.Cache["CoreLoopAudio"].Volume = audio.Core.Volume;
			end
			
		end
	end;
	
	local function InspectRequest()
		if not properties.Attacking then
			toolAnimator:Play("Inspect", {FadeTime=0;});
		end
	end
	
	local toggleTraj = false;

	Equipped.Throwable = configurations.Throwable;
	if configurations.Throwable then
		local projRaycast = RaycastParams.new();
		projRaycast.FilterType = Enum.RaycastFilterType.Include;
		projRaycast.IgnoreWater = true;
		projRaycast.CollisionGroup = "Raycast";
		projRaycast.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain;};
		
		local arcTracer = modArcTracing.new();
		arcTracer.Bounce = configurations.ProjectileBounce;
		arcTracer.LifeTime = configurations.ProjectileLifeTime;
		arcTracer.Acceleration = configurations.ProjectileAcceleration;
		arcTracer.AirSpin = configurations.ProjectileAirSpin;
		arcTracer.Delta = 1/60;
		
		table.insert(arcTracer.RayWhitelist, workspace.Entity);
		table.insert(arcTracer.RayWhitelist, workspace:FindFirstChild("Characters"));
		local charactersList = CollectionService:GetTagged("PlayerCharacters");
		if charactersList then 
			for a=1, #charactersList do
				if charactersList[a] ~= character then
					table.insert(arcTracer.RayWhitelist, charactersList[a]);
				end
			end 
		end
		
		arcDisk = landPartTemplate:Clone();
		
		local initThrow = false;
		local throwChargeTick;
		throwChargeValue = 0;
		
		local function reset()
			throwChargeTick = nil;
			throwChargeValue = 0;
		end
		
		local function getImpactPoint() -- reasonable throw ranges [25, 80];
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

			local newDirection = (scanPoint-head.Position).Unit;
			local distance = (scanPoint-head.Position).Magnitude;

			-- Gets where player can hit.
			-- Get hitscan point from head using direction provided by crosshair hitscan.
			local impactPoint = modWeaponMechanics.CastHitscanRay{
				Origin = head.Position;
				Direction = newDirection;
				IncludeList = rayWhitelist;
				Range = distance;
			};

			if toggleTraj then
				game.Debris:AddItem(Debugger:PointPart(impactPoint), 0.1);
			end

			return impactPoint;
		end

		local function primaryThrow()
			if storageItem.MockItem ~= true then
				storageItem = modData.GetItemById(storageItem.ID);
			end
			if storageItem == nil then return end;
			
			local throwStaminaCost = (configurations.ThrowStaminaCost or 0);
			local infType = toolModel:GetAttribute("InfAmmo");
			if infType ~= nil then
				throwStaminaCost = 0;
			end
			if Stats.Stamina <= 0 then 
				toolAnimator:Stop("Charge", {FadeTime=0;});
				toolAnimator:Play("Throw", {FadeTime=0; PlaySpeed=0.1});

				return 
			end;
			Stats.LastDrain = tick();

			toolConfig.CanThrow = false;
			
			local throwCharge = throwChargeValue > 0.05 and throwChargeValue or 0;
			local impactPoint = getImpactPoint();

			toolAnimator:Stop("Charge", {FadeTime=0;});
			toolAnimator:Play("Throw", {FadeTime=0;});
			
			if audio.Throw then
				modAudio.PlayReplicated(audio.Throw.Id, handle);
			end

			Stats.Stamina = math.clamp(Stats.Stamina - throwStaminaCost, -BaseStats.RecoveryRecoveryRate, Stats.MaxStamina);

			for _, obj in pairs(toolModel:GetChildren()) do
				if not obj:IsA("BasePart") then continue end;
				if obj.Transparency >= 1 then continue end;
				
				obj.Transparency = 1;
				task.delay(configurations.ThrowRate or 0.2, function()
					obj.Transparency = 0;
				end)
			end
			remoteToolPrimaryFire:FireServer(storageItem.ID, "Throw", handle.Position, impactPoint, throwCharge);
			
			if storageItem.Quantity > 1 and configurations.ConsumeOnThrow ~= true then
				--
			else
				wait(configurations.ThrowRate or 0.2);
				toolConfig.CanThrow = true;
			end
		end

		local function meleeRender()
			if not characterProperties.IsEquipped then return end;
		
			if rootPart:GetAttribute("WaistRotation") then
				characterProperties.Joints.WaistY = math.rad(tonumber(rootPart:GetAttribute("WaistRotation")) or 0);
				
			elseif configurations.WaistRotation then
				characterProperties.Joints.WaistY = configurations.WaistRotation;
				
			end
		end
		RunService:BindToRenderStep("MeleeRender", Enum.RenderPriority.Camera.Value, meleeRender);

		RunService:BindToRenderStep("Throwable", Enum.RenderPriority.Character.Value, function()
			if not characterProperties.IsFocused then
				characterProperties.HideCrosshair = true;
				arcDisk.Parent = nil;
				for _, obj in pairs(CollectionService:GetTagged("ThrowableArc")) do
					obj:Destroy();
				end
				arcList = {};
				
				characterProperties.Joints.WaistY = configurations.WaistRotation;
				local track = toolAnimator:GetPlaying("Charge");
				if track then
					track:Stop(0);
					toolAnimator:Play("Throw", {FadeTime=0; PlaySpeed=0.3});
				end
				
				initThrow = false;
				reset();
				return;
			else
				characterProperties.HideCrosshair = false;
			end
			
			if modKeyBindsHandler:IsKeyDown("KeyFire") and characterProperties.CanAction and characterProperties.IsEquipped then
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
					throwChargeValue = math.clamp((tick()-throwChargeTick) / configurations.ChargeDuration, 0.01, 0.99);
					if throwChargeValue > 0.05 or characterProperties.IsFocused then
						local track = toolAnimator:GetPlaying("Charge");
						if track == nil then
							track = toolAnimator:Play("Charge", {FadeTime=0; PlaySpeed=0;});
						end
						track.TimePosition = track.Length * throwChargeValue;
					end
					
				end
				characterProperties.Joints.WaistY = configurations.ThrowWaistRotation;
			else
				if initThrow then
					initThrow = false;
					primaryThrow();
				end
				reset()
			end
			
			if mouseProperties.Mouse2Down and characterProperties.CanAction and characterProperties.IsEquipped and toggleTraj then
				local impactPoint = getImpactPoint();
				game.Debris:AddItem(Debugger:PointPart(impactPoint), 0.1);

				local handlePoint: Vector3 = handle.Position;
				local velocity = (configurations.Velocity + configurations.VelocityBonus * throwChargeValue);

				local travelTime = (impactPoint-handlePoint).Magnitude/velocity;
				local velocityToImpact = arcTracer:GetSteppedVelocityByTime(handlePoint, impactPoint, travelTime);

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
					
					--local order = math.clamp(1 - (a/#arcList * 0.7), 0.5, 1);
					arcPart.Parent = workspace.CurrentCamera;
					arcPart.Size = Vector3.new(0.05, 0.05, arcPoint.Displacement);
					arcPart.Transparency = 0;
					arcPart.CFrame = CFrame.new(arcPoint.Origin, arcPoint.Point) * CFrame.new(0, 0, -arcPoint.Displacement/2);
					
					if a == #arcList and arcPoint.Normal then
						arcDisk.Parent = workspace.CurrentCamera;
						arcDisk.CFrame = CFrame.new(arcPoint.Point, arcPoint.Point + arcPoint.Normal) * CFrame.Angles(math.pi/2, 0, 0);
					end
				end
			end
		end)
	end
	
	if meleeMode ~= "Auto" then
		table.insert(Equipped.Connections, collider.Touched:Connect(function(hitPart)
			if properties.Attacking then
				onColliderTouch(hitPart);
			end
		end))
	end
	
	function Equipped.ItemPromptRequest()
		if not characterProperties.CanAction then return end;
		if characterProperties.ActiveInteract ~= nil and characterProperties.ActiveInteract.CanInteract and characterProperties.ActiveInteract.Reachable then return end;
		if toolConfig.ClientItemPrompt then
			toolConfig:ClientItemPrompt();
		end
		
		if toolConfig.RoleplayStateWindow and table.find(toolAnimator.StateList, "Roleplay") then
			
			toolAnimator:SetState("Roleplay");
			toolAnimator:Play("Core", {FadeTime=0.5;});

			task.spawn(function()
				repeat task.wait(0.3) until not equipped or not modInterface:IsVisible(toolConfig.RoleplayStateWindow);
				toolAnimator:SetState();
				toolAnimator:Play("Core", {FadeTime=0.5;});
			end)
			
		end
	end
	
	characterProperties.Joints.WaistY = configurations.WaistRotation;
	
	if audio.Load then
		modAudio.PlayReplicated(audio.Load.Id, handle, nil, audio.PrimarySwing.Pitch, audio.PrimarySwing.Volume);
	end
	
	if audio.Core then
		Equipped.Cache["CoreLoopAudio"] = modAudio.Play(audio.Core.Id, handle, true, audio.PrimarySwing.Pitch, audio.PrimarySwing.Volume);
	end

	
	local equipTimeReduction = classPlayer:GetBodyEquipment("EquipTimeReduction");
	local equipTime = configurations.EquipLoadTime;
	if equipTimeReduction then
		equipTime = equipTime * math.clamp(1-equipTimeReduction, 0, 1);
	end
	
	local loadTrack = toolAnimator:Play("Load", {FadeTime=0;});
	if loadTrack.Length > 0 then
		local animSpeed = math.clamp(configurations.EquipLoadTime/equipTime, 0.5, 2);
		loadTrack:AdjustSpeed(animSpeed);
	end
	
	if toolConfig.OnToolEquip then
		task.defer(function()
			toolConfig.OnToolEquip(ToolHandler, toolModel);
		end)
	end

	toolConfig.Player = player;
	toolConfig.Prefab = toolModel;
	toolConfig.Handle = handle;
	toolConfig.StorageItem = storageItem;
	toolConfig.PrimaryFireRequest = PrimaryFireRequest;

	Equipped.RightHand["KeyInteract"] = Equipped.ItemPromptRequest;
	Equipped.RightHand["KeyFire"] = PrimaryFireRequest;
	Equipped.RightHand["KeyInspect"] = InspectRequest;

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

		if Equipped.ToolConfig.SpecialToggleHint then
			if UserInputService.KeyboardEnabled then
				local hintString = `Press [{modKeyBindsHandler:ToString("KeyToggleSpecial")}] {Equipped.ToolConfig.SpecialToggleHint}`;
				modInterface:HintWarning(hintString, nil, Color3.fromRGB(255, 255, 255));
			end

			if UserInputService.TouchEnabled then
				local itemPromptButton = modInterface.TouchControls:WaitForChild("ItemPrompt");
				local touchItemPrompt = itemPromptButton:WaitForChild("Item");
				
				touchItemPrompt.Image = itemLib.Icon;
				itemPromptButton.Visible = true;

				if modData.ItemPromptConn then modData.ItemPromptConn:Disconnect(); end
				modData.ItemPromptConn = itemPromptButton.MouseButton1Click:Connect(function()
					script.Parent.Parent.CharacterInput:Fire("KeyToggleSpecial");
				end)
			end
		end

	end

	delay(equipTime, function()
		if unequiped then return end;
		toolConfig.CanThrow = true;
		equipped = true;
		
	end)
end

function ToolHandler:Unequip(storageItem)
	RunService:UnbindFromRenderStep("MeleeRender");
	RunService:UnbindFromRenderStep("Throwable");
	RunService.RenderStepped:Wait();
	modFlashlight:Destroy();
	modData.UpdateProgressionBar();

	if Equipped.ToolConfig then
		if Equipped.ToolConfig.ClientUnequip then
			Equipped.ToolConfig:ClientUnequip();
		end
		
	end
	
	if Equipped.Connections then
		for a=1, #Equipped.Connections do
			Equipped.Connections[a]:Disconnect();
		end
	end
	
	for key, equipment in pairs(Equipped) do
		if typeof(equipment) == "table" and equipment.Item and equipment.Item.ID == storageItem.ID then
			if equipment.Unequip then equipment.Unequip(); end
			Equipped[key] = {Data={};};
		end;
	end
	Equipped.Cache = nil;
	Equipped = nil;
end

function ToolHandler:Initialize(equipped)
	if Equipped ~= nil then return end;
	Equipped = equipped;
end

function ToolHandler:InitStaminaSystem()
	task.spawn(function()
		repeat
			if classPlayer == nil then
				classPlayer = modPlayers.Get(player);
			end
			if classPlayer == nil then
				task.wait(1);
				continue;
			end
			
			local playerBodyEquipments = classPlayer.Properties and classPlayer.Properties.BodyEquipments;
	
			Stats.RecoveryRecoveryRate = nil;
			Stats.RecoveryRecoveryDelay = nil;
			
			if classPlayer.Properties.isBloxyRush then
				Stats.RecoveryRecoveryRate = 30;
				Stats.RecoveryRecoveryDelay = 1;
			end
	
			local additionalStamina = playerBodyEquipments and playerBodyEquipments.AdditionalStamina;
			if modConfigurations.DisableGearMods then
				additionalStamina = nil;
			end
			
			if additionalStamina then
				Stats.MaxStamina = BaseStats.MaxStamina + additionalStamina;
			else
				Stats.MaxStamina = nil;
			end
			
			local delta = wait(0.1);
			local rate = delta * Stats.RecoveryRecoveryRate;
			if Stats.LastDrain == nil or (tick()-Stats.LastDrain) > Stats.RecoveryRecoveryDelay then
				Stats.Stamina = math.clamp(Stats.Stamina + rate, -BaseStats.RecoveryRecoveryRate, Stats.MaxStamina);
				Stats.SubStamina = 0;
			end
			
			if Equipped then
				modData.UpdateProgressionBar(math.clamp(Stats.Stamina/Stats.MaxStamina, 0, 1), "MeleeStamina");
			end
		until not workspace:IsAncestorOf(character);
	end)
end

return ToolHandler;