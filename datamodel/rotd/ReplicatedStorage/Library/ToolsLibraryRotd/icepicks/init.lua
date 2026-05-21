local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local modRaycastUtil = shared.require(game.ReplicatedStorage.Library.Util.RaycastUtil);
--==

local toolPackage = {
	ItemId = script.Name;
	Class = "Melee";
	HandlerType = "MeleeTool";

	Welds={
		LeftToolGrip = "icepick";
		RightToolGrip = "icepick";
	};

	Animations={
		Core = {Id=84589246471756;};
		Load = {Id=82757525078387;};
		PrimaryAttack = {Id={140465274820449; 84956648904881; 119092351296588; 124205651794358;}};
		--HeavyAttack = {Id=84287397371920};
		Inspect = {Id=82747217283694; WaistStrength=0.2;};
		Unequip = {Id=109703950319099};
		LeftClimbHook = {Id=114825587353553;};
		RightClimbHook = {Id=121356522251923;};
		FrontClimbHook = {Id=140253595577585;};
	};
	Audio={
		Load = {Id=116507113186443; Pitch=0.6; Volume=0.5;};
		PrimaryHit = {Id=9141019032; Pitch=0.6; Volume=1;};
		PrimarySwing = {Id=158037267; Pitch=0.75; Volume=1;};
		HeavySwing = {Id=158037267; Pitch=0.70; Volume=1;};
	};
	
	Configurations = {
		Category = "Edged";
		Type = "Tool";
		
		EquipLoadTime = 0.6;
		Damage = 500;

		PrimaryAttackSpeed = 0.3;
		HitRange = 14;

		WaistRotation = math.rad(0);

		StaminaCost = 4;
		StaminaDeficiencyPenalty = 0.8;

		BleedDamagePercent = 0.1;
		BleedSlowPercent = 0.1;
	};
	Properties={};
};

function toolPackage.newClass()
	local equipmentClass = modEquipmentClass.new(toolPackage);

	equipmentClass:AddBaseModifier("FrozenTip", {
		ArrayValues = {
			PassiveModifiers = "Frozen Tip";
		};
	});
	equipmentClass:AddBaseModifier("PeakReacher", {
		ArrayValues = {
			PassiveModifiers = "Peak Reacher";
		};
	});
	equipmentClass:AddBaseModifier("ChainedAttack", {
		SetValues = {
			AutoSwing = true;
		};
		ArrayValues = {
			PassiveModifiers = "Chained Attack";
		};
	});

	return equipmentClass;
end

function toolPackage.BindAnimPlay(handler: ToolHandlerInstance, animName: string, playTrack: AnimationTrack, tracks: {AnimationTrack})
	local equipmentClass: EquipmentClass = handler.EquipmentClass;
	if equipmentClass == nil then return end;

	local properties = equipmentClass.Properties;
	local primaryAnimIndex = properties.PrimaryAnimIndex or 0;
	primaryAnimIndex += 1;
	properties.PrimaryAnimIndex = primaryAnimIndex;

	if primaryAnimIndex%2 == 0 then
		return tracks[1];
	else
		return tracks[2];
	end
end

function toolPackage.onRequire()
	if RunService:IsClient() then
		modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	end
end


if RunService:IsClient() then

	local isHookKeyDown = false;
	local STEEPNESS_THRESHOLD = math.cos(math.rad(55));
	local WALLRAY_DIST = 4;
	local GRAVITY = Vector3.new(0, -game.Workspace.Gravity, 0);
	local WALL_OFFSET = 1.5;

	function toolPackage.ClientEquip(handler: ToolHandlerInstance)
		local modCharacter = modData:GetModCharacter();
		local characterProperties = modCharacter.CharacterProperties;

		local playerClass: PlayerClass = handler.CharacterClass :: PlayerClass;
		local rayWhitelist = {workspace.Environment; workspace.Terrain};
		
		local equipmentClass: EquipmentClass = handler.EquipmentClass;
		local properties = equipmentClass.Properties;
		local rootPart = playerClass.RootPart;

		local dustEmitters = {};
		for _, model in pairs(handler.Prefabs) do
			local emitter = model:FindFirstChild("DustParticle", true);
			if emitter then
				if handler.MainToolModel:IsAncestorOf(emitter) then
					emitter:SetAttribute("RightHand", true);
				end
				table.insert(dustEmitters, emitter);
			end
		end
		handler.Garbage:Tag(function() 
			for _, emitter in pairs(dustEmitters) do
				emitter.Enabled = false;
			end
		end)
		handler.Garbage:Tag(properties.OnChanged:Connect(function(k, v)
			if k ~= "HookInfo" then return end;
			
			if v == nil then
				for _, emitter in pairs(dustEmitters) do
					emitter.Enabled = false;
				end
				return;
			end

			local dir = v.WallDirection;
			if dir == "Left" then
				for _, emitter in pairs(dustEmitters) do
					emitter.Enabled = emitter:GetAttribute("RightHand") ~= true;
				end
			elseif dir == "Right" then
				for _, emitter in pairs(dustEmitters) do
					emitter.Enabled = emitter:GetAttribute("RightHand") == true;
				end
			else
				for _, emitter in pairs(dustEmitters) do
					emitter.Enabled = true;
				end
			end
		end))

		handler.Garbage:Tag(RunService.PreSimulation:Connect(function(delta: number)
			if playerClass.HealthComp.IsDead then
				return
			end;

			local shouldDismount = false;

			local charAlignPosition: AlignPosition = rootPart.RootPosition;

			local function onCast(basePart, position, normal, material, index, distance)
				if basePart == nil then return end;
				if position == nil then return end;
				
				if normal.Y > STEEPNESS_THRESHOLD then return end;
				if basePart.Anchored ~= true then return end;

				if modCharacter.CharacterProperties.LeftSideCamera then
				end

				return {
					Part = basePart;
					Position = position;
					Normal = normal;
				} :: HitInfo;
			end

			local ROOT_OFFSET_VEC = Vector3.new(0, 1.5, 0);
			local function getClosestWallInfo()
				local hookInfo = properties.HookInfo;

				local rpCf = rootPart.CFrame;

				local origin = (rpCf.Position + ROOT_OFFSET_VEC);
				local dir;

				local rightHitInfo: HitInfo, leftHitInfo: HitInfo;
				local frontHitInfo: HitInfo;
				do
					dir = rpCf.RightVector;
					-- Debugger.Expire(Debugger:Ray(Ray.new(origin, dir*WALLRAY_DIST)), 0.2);
					modRaycastUtil.castHitscanRay{
						Origin = origin;
						Direction = dir;
						IncludeInstances = rayWhitelist;
						Range = WALLRAY_DIST;
						OnCastFunc = function(...)
							if rightHitInfo then return end;
							rightHitInfo = onCast(...);
							return;
						end;
					};
				end
				do
					dir = -rpCf.RightVector;
					-- Debugger.Expire(Debugger:Ray(Ray.new(origin, dir*WALLRAY_DIST)), 0.2);
					modRaycastUtil.castHitscanRay{
						Origin = origin;
						Direction = dir;
						IncludeInstances = rayWhitelist;
						Range = WALLRAY_DIST;
						OnCastFunc = function(...)
							if leftHitInfo then return end;
							leftHitInfo = onCast(...);
							return;
						end;
					};
				end
				do
					local frontOrigin = origin;
					if hookInfo then
						if hookInfo.WallDirection == "Left" then
							frontOrigin += -rpCf.RightVector;
						elseif hookInfo.WallDirection == "Right" then
							frontOrigin += rpCf.RightVector;
						end
					end
					dir = rpCf.LookVector;
					-- Debugger.Expire(Debugger:Ray(Ray.new(frontOrigin, dir*WALLRAY_DIST)), 0.2);
					modRaycastUtil.castHitscanRay{
						Origin = frontOrigin;
						Direction = dir;
						IncludeInstances = rayWhitelist;
						Range = WALLRAY_DIST;
						OnCastFunc = function(...)
							if frontHitInfo then return end;
							frontHitInfo = onCast(...);
							return;
						end;
					};
				end
				

				local closerWallInfo = nil;
				if leftHitInfo == nil and rightHitInfo then
					rightHitInfo.WallDirection = "Right";
					closerWallInfo = rightHitInfo;

				elseif rightHitInfo == nil and leftHitInfo then
					leftHitInfo.WallDirection = "Left";
					closerWallInfo = leftHitInfo;

				elseif leftHitInfo and rightHitInfo then
					
					leftHitInfo.Distance = (leftHitInfo.Position-origin).Magnitude;
					rightHitInfo.Distance = (rightHitInfo.Position-origin).Magnitude;

					if leftHitInfo.Distance < rightHitInfo.Distance then
						leftHitInfo.WallDirection = "Left";
						closerWallInfo = leftHitInfo;
					else
						rightHitInfo.WallDirection = "Right";
						closerWallInfo = rightHitInfo;
					end

				elseif frontHitInfo then
					frontHitInfo.WallDirection = "Front";
					closerWallInfo = frontHitInfo;

				end

				if closerWallInfo then
					closerWallInfo.RootCFrame = rpCf;
				end

				return closerWallInfo;
			end

			local hookInfo = properties.HookInfo;
			local isInAir = playerClass.Humanoid.FloorMaterial == Enum.Material.Air;

			if properties.LeapCooldown and tick() < properties.LeapCooldown then
				characterProperties.BodyLockToCam = true;
				characterProperties.AllowLerpBody = false;
				return;
			else
				characterProperties.BodyLockToCam = false;
				characterProperties.AllowLerpBody = true;
			end
			
			if isHookKeyDown and hookInfo == nil and isInAir then

				local wallInfo = getClosestWallInfo();
				if wallInfo then
					characterProperties.WallClimbCooldown= tick()+1;
					wallInfo.Velocity = rootPart.AssemblyLinearVelocity;
					wallInfo.StartTick = tick();
					properties.HookInfo = wallInfo;

					if properties.ClimbAnim then
						properties.ClimbAnim:Stop();
						properties.ClimbAnim = nil;
					end

				end


			elseif isInAir and hookInfo then
				local prevWallInfo = hookInfo;

				local wallInfo = getClosestWallInfo();
				if wallInfo and wallInfo.Part == prevWallInfo.Part then
					prevWallInfo.Position = wallInfo.Position;
					prevWallInfo.Normal = wallInfo.Normal;
					prevWallInfo.WallDirection = wallInfo.WallDirection;
					wallInfo = prevWallInfo;
					
				else
					if prevWallInfo.Att then -- reattach
						prevWallInfo.Att:Destroy();
					end
				end

				if wallInfo then
					if properties.ClimbAnim 
					and properties.ClimbAnim:GetAttribute("Direction") ~= wallInfo.WallDirection then
						properties.ClimbAnim:Stop();
						properties.ClimbAnim = nil;
					end
					if properties.ClimbAnim == nil then
						local toolAnimator: ToolAnimator = handler.ToolAnimator;
						local animTrack: AnimationTrack;

						if wallInfo.WallDirection == "Right" then
							animTrack = toolAnimator:Play("RightClimbHook");
							animTrack:SetAttribute("Direction", "Right")
						elseif wallInfo.WallDirection == "Left" then
							animTrack = toolAnimator:Play("LeftClimbHook");
							animTrack:SetAttribute("Direction", "Left")
						elseif wallInfo.WallDirection == "Front" then
							animTrack = toolAnimator:Play("FrontClimbHook");
							animTrack:SetAttribute("Direction", "Front")
						end
						properties.ClimbAnim = animTrack;

						modAudio.Play("BodySlide", rootPart).PlaybackSpeed = 2;
					end

					--MARK: Wall Mount
					if wallInfo.StartTick == nil then
						wallInfo.StartTick = tick();
					end

					local curVel = rootPart.AssemblyLinearVelocity;
					local rate = math.clamp(math.abs(curVel.Y)/10, 0, 1) * 16;
					for _, emitter: ParticleEmitter in pairs(dustEmitters) do
						emitter.Rate = rate;
					end
					local timeSinceStart = math.max(0.3-math.max(tick()-wallInfo.StartTick, 0), 0);

					local wallPosition = wallInfo.Position;
					local wallNormal = wallInfo.Normal;
					
					wallPosition += (GRAVITY * delta * timeSinceStart);

					local wallAtt: Attachment = wallInfo.Att;
					if wallAtt == nil then
						wallAtt = Instance.new("Attachment");
						handler.Garbage:Tag(wallAtt);

						wallAtt.Name = "IcePickAnchor";
						wallAtt.Parent = wallInfo.Part;
						wallInfo.Att = wallAtt;
					end

					wallAtt.WorldPosition = (wallPosition - ROOT_OFFSET_VEC) + (wallNormal * WALL_OFFSET);
					properties.HookInfo = wallInfo;

					characterProperties.AllowLerpBody = false;

					charAlignPosition.Position = wallAtt.WorldPosition;
					charAlignPosition.Enabled = true;
					characterProperties.WallClimbCooldown = tick()+1;
					properties.CanLeap = tick();

				else
					shouldDismount = true;
				end

			elseif not isInAir then
				shouldDismount = true;

			end

			if shouldDismount and properties.HookInfo then
				toolPackage.CancelHook(handler);
			end
		end))
	end
	
	function toolPackage.CancelHook(handler: ToolHandlerInstance)
		local modCharacter = modData:GetModCharacter();

		local characterProperties = modCharacter.CharacterProperties;

		local equipmentClass: EquipmentClass = handler.EquipmentClass;

		local playerClass: PlayerClass = handler.CharacterClass :: PlayerClass;
		local rootPart = playerClass.RootPart;
		local charAlignPosition: AlignPosition = rootPart.RootPosition;

		local properties = equipmentClass.Properties;
		local hookInfo = properties.HookInfo;
		
		charAlignPosition.Enabled = false;
		if hookInfo and hookInfo.Att then
			hookInfo.Att:Destroy();
		end
		properties.HookInfo = nil;

		characterProperties.WallClimbCooldown = tick();

		characterProperties.AllowLerpBody = true;

		if properties.ClimbAnim then
			properties.ClimbAnim:Stop();
			properties.ClimbAnim = nil;
		end
	end

	function toolPackage.InputEvent(handler: ToolHandlerInstance, inputData: ToolInputData)
		local modCharacter = modData:GetModCharacter();

		if inputData.KeyIds.KeyFocus == true then
			if inputData.InputState == "Begin" then
				isHookKeyDown = true;
			elseif inputData.InputState == "End" then
				isHookKeyDown = false;
			end

		elseif inputData.KeyIds.KeyJump == true and inputData.InputState == "Begin" then

			local playerClass: PlayerClass = handler.CharacterClass :: PlayerClass;
			local equipmentClass: EquipmentClass = handler.EquipmentClass;
			local properties = equipmentClass.Properties;

			if properties.CanLeap and tick()-properties.CanLeap <= 0.3 then
				properties.CanLeap = nil;

				toolPackage.CancelHook(handler);
				properties.LeapCooldown = tick()+0.3;

				RunService.PreSimulation:Wait();
				RunService.PreSimulation:Wait();
				
				local rootPart = playerClass.RootPart;
				local camLookVec = camera.CFrame.LookVector;
				local mass = rootPart:GetMass();
				
				rootPart:ApplyImpulse(Vector3.yAxis * 30 * mass + camLookVec * 240 * mass);

				modCharacter.playAnimation("doubleJump"):AdjustSpeed(5);
			end
		end;
	end

	function toolPackage.ClientUnequip(handler: ToolHandlerInstance)
		toolPackage.CancelHook(handler);
	end
end

return toolPackage;