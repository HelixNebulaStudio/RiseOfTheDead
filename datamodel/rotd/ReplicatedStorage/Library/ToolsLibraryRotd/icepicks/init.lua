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
		Damage = 750;

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

local STEEPNESS_THRESHOLD = math.cos(math.rad(55));

if RunService:IsClient() then

	local isHookKeyDown = false;
	local WALLRAY_DIST = 4;
	local GRAVITY = Vector3.new(0, -game.Workspace.Gravity, 0);
	local WALL_OFFSET = 1.5;

	function toolPackage.ClientEquip(handler: ToolHandlerInstance)
		local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
		local modCharacter = modData:GetModCharacter();
		local characterProperties = modCharacter.CharacterProperties;

		local playerClass: PlayerClass = handler.CharacterClass :: PlayerClass;
		local rayWhitelist = {workspace.Environment; workspace.Terrain};
		
		local equipmentClass: EquipmentClass = handler.EquipmentClass;
		local properties = equipmentClass.Properties;
		local rootPart = playerClass.RootPart;

		handler.Garbage:Tag(RunService.PreSimulation:Connect(function(delta: number)
			if playerClass.HealthComp.IsDead then return end;

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
				local rpCf = rootPart.CFrame;

				local origin = rpCf.Position + ROOT_OFFSET_VEC;
				local dir;

				local rightHitInfo: HitInfo, leftHitInfo: HitInfo;
				do
					dir = rootPart.CFrame.RightVector;
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
					dir = -rootPart.CFrame.RightVector;
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

				local closerWallInfo = nil;
				if leftHitInfo == nil and rightHitInfo then
					rightHitInfo.RightWall = true;
					closerWallInfo = rightHitInfo;

				elseif rightHitInfo == nil and leftHitInfo then
					leftHitInfo.RightWall = false;
					closerWallInfo = leftHitInfo;

				elseif leftHitInfo and rightHitInfo then
					
					leftHitInfo.Distance = (leftHitInfo.Position-origin).Magnitude;
					rightHitInfo.Distance = (rightHitInfo.Position-origin).Magnitude;

					if leftHitInfo.Distance < rightHitInfo.Distance then
						leftHitInfo.RightWall = false;
						closerWallInfo = leftHitInfo;
					else
						rightHitInfo.RightWall = true;
						closerWallInfo = rightHitInfo;
					end

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

					local toolAnimator: ToolAnimator = handler.ToolAnimator;
					local animTrack: AnimationTrack;
					
					if equipmentClass.Properties.ClimbAnim then
						equipmentClass.Properties.ClimbAnim:Stop();
						equipmentClass.Properties.ClimbAnim = nil;
					end
					if wallInfo.RightWall then
						animTrack = toolAnimator:Play("RightClimbHook");
					else
						animTrack = toolAnimator:Play("LeftClimbHook");
					end
					equipmentClass.Properties.ClimbAnim = animTrack;

					modAudio.Play("BodySlide", rootPart).PlaybackSpeed = 4;
				end


			elseif isInAir and hookInfo then
				local prevWallInfo = hookInfo;

				local wallInfo = getClosestWallInfo();
				if wallInfo and wallInfo.Part == prevWallInfo.Part then
					prevWallInfo.Position = wallInfo.Position;
					prevWallInfo.Normal = wallInfo.Normal;
					wallInfo = prevWallInfo;
					
				else
					if prevWallInfo.Att then -- reattach
						prevWallInfo.Att:Destroy();
					end
				end

				if wallInfo then
					--MARK: Wall Mount

					local timeSinceStart = math.max(0.3-math.max(tick()-wallInfo.StartTick, 0), 0.01);
					local wallPosition = wallInfo.Position + (GRAVITY * delta * timeSinceStart);
					local wallNormal = wallInfo.Normal;

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

					characterProperties.CanTurn = false;
					characterProperties.AllowLerpBody = false;

					charAlignPosition.Position = wallAtt.WorldPosition;
					charAlignPosition.Enabled = true;
					characterProperties.WallClimbCooldown = tick()+1;
					properties.CanLeap = tick();

				else
					charAlignPosition.Enabled = false;
					if prevWallInfo.Att then
						prevWallInfo.Att:Destroy();
					end
					properties.HookInfo = nil;

					characterProperties.WallClimbCooldown = tick();

				end

			elseif not isInAir then

				charAlignPosition.Enabled = false;
				if hookInfo and hookInfo.Att then
					hookInfo.Att:Destroy();
				end
				properties.HookInfo = nil;
				characterProperties.WallClimbCooldown = tick();

				if equipmentClass.Properties.ClimbAnim then
					equipmentClass.Properties.ClimbAnim:Stop();
					equipmentClass.Properties.ClimbAnim = nil;
				end

			end
		end))
	end
	
	function toolPackage.CancelHook(handler: ToolHandlerInstance)
		local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
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

		characterProperties.CanTurn = true;
		characterProperties.AllowLerpBody = true;

		if equipmentClass.Properties.ClimbAnim then
			equipmentClass.Properties.ClimbAnim:Stop();
			equipmentClass.Properties.ClimbAnim = nil;
		end
	end

	function toolPackage.InputEvent(handler: ToolHandlerInstance, inputData: ToolInputData)
		local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
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