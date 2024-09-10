local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

-- runs on server too;
local CharacterModule = {};

if RunService:IsClient() then
	CharacterModule = {
		__init=false;
		Script=script;
		
		Player=game.Players.LocalPlayer;

		Humanoid=script.Parent:WaitForChild("Humanoid");
		
		TouchButtons={
			SpaceActionButton = nil;
			CtrlActionButton = nil;
		};
		CharacterProperties={
			State = Enum.HumanoidStateType.None;
	
			MoveSpeed=0;
	
			DefaultWalkSpeed=18;
			DefaultSprintSpeed=22;
			DefaultSwimSpeed=12;
			NewWalkSpeed=18;
			CrouchSpeed=10;
			WalkingSpeed=6;
			WoundedSpeed=6;
			CustomWalkSpeed=nil;
	
			DefaultJumpPower=50;
			CanInteract=true;
			IsAlive=true;
			LeftSideCamera=false;
			CanMove=true;
			CanMoveFreeCam=true;
			CanAction=true;
			CanCrouch=true;
			CanSprint=true;
	
			IsMoving=false;
			IsSliding=false;
			IsWalking=false;
			IsSprinting=false;
			IsSwimming=false;
			IsCrouching=false;
			IsEquipped=false;
			IsFocused=false;
			IsWounded=false;
			IsKnockedOut=false;
			IsRagdoll=false;
			IsAntiGravity=false;
	
			AllowLerpBody=true;
			ZoomLevel=8;
			PlayerVelocity=0;
			FieldOfView=nil;
			BaseFieldOfView=70;
			IsSpectating=false;
			FirstPersonCamera=false;
			ThirdPersonCamera=true;
			BodyLockToCam=false;
			CharacterCameraEnabled=true;
			EyeSightAttachment=nil;
			HeadUnderwater=false;
			ControllerEnabled=false;
	
			SprintKeyDown=false;
			WalkKeyDown=false;
			CrouchKeyDown=false;
	
			ActionKeyShiftDown=false;
			ActionKeyCtrlDown=false;
			ActionKeyAltDown=false;
			ActionKeySpaceDown=false;
	
			FreecamState=0;
	
			Mass=0;
			SlideSpeed=55;
			Joints={
				WaistX=0;
				WaistY=0;
				WaistZ=0;
				RightShoulderAngle=CFrame.Angles(0, 0, 0);
				LeftShoulderAngle=CFrame.Angles(0, 0, 0);
			};
			SwayYStrength=1;
			VelocitySrength=1;
	
			RefreshTransparency=false;
	
			UseViewModel=true;
			ViewModelPivot=CFrame.new();
			ViewModel=CFrame.new(-0.3, -0.9, 0); --0, -0.9, 0.1
			DefaultViewModel=CFrame.new(-0.3, -0.9, 0); -- (LR, UD, FB);
			CustomViewModel=nil;
			AimDownSights=false;
	
			InteractionActive=false;
			ActiveInteract=nil;
			
			GroundObject=nil;
			GroundPoint=Vector3.zero;
			GroundNormal=Vector3.yAxis;
			
			ViewModelSwayX=0;
			ViewModelSwayY=0;
			ViewModelSwayRoll=0;
			ViewModelSwayPitch=0;
	
			CharacterInteracting=false; -- Whether interact alpha is incrementing
			InteractGyro=nil;
			InteractAlpha=0;
	
			UnderwaterVision = 0.01;
			
			EnumStates = {};
			
			MotorHeadCFrameA=CFrame.new();
			MotorHeadCFrameB=CFrame.new();
		};
		MouseProperties={
			X=0;
			Y=0;
			Z=0;
			XAngOffset=0;
			YAngOffset=0;
			ZAngOffset=0;
			
			FlinchInacc=0;
			
			Mouse1Down=false;
			Mouse2Down=false;
			MouseLocked=true;
			CanManualLockMouse=true;
			CursorEnabled=false;
			CameraSmoothing=0;
			MovementNoise=false;
			DefaultSensitivity=1;
			Sensitivity=1;
	
			Focus=CFrame.new();
			Direction=Vector3.new();
		};
		Settings={
			InteractKeybind=Enum.KeyCode.E;
		};
		
		--== Tool;
		EquippedTool=nil; -- Model
		EquippedItem=nil; -- StorageItem
		EquippedToolModule=nil; -- ToolModule;
		
		Animations = {};
		OnAnimationsChanged = RunService:IsClient() and modEventSignal.new("OnAnimationsChanged") or nil;
	};

	function CharacterModule:ToggleMouseLock(locked)
		if not locked then
			self.MouseProperties.CanManualLockMouse = false;
			self.MouseProperties.MouseLocked = false;
		else
			self.MouseProperties.CanManualLockMouse = true;
			self.MouseProperties.MouseLocked = true;
		end
	end;

	function CharacterModule:GetAnimation(name)
		local humanoid = self.Humanoid;
		local animations = humanoid and humanoid:GetPlayingAnimationTracks() or nil;
		if animations then
			for a=1, #animations do
				if animations[a].Name == name then
					return animations[a];
				end
			end
		elseif humanoid == nil then
			warn("Character>> Missing humanoid to get animation ("..name..").");
		end

		return;
	end;

	function CharacterModule:AddAnimation(name, track)
		self.Animations[name] = track;
		self.OnAnimationsChanged:Fire(name, track);
	end

	function CharacterModule:RemoveAnimation(name)
		self.Animations[name] = nil;
		self.OnAnimationsChanged:Fire(name);
	end;

	-- DataModule Destroying conn;
end

--==MARK: SERVER & CLIENT:

local ragJoints, bodyParts = {}, {};

function CharacterModule.UpdateBodyObjects()
	local character = script.Parent;
	local ragdollEnabled = character:GetAttribute("Ragdoll") ~= 0;
	
	if #bodyParts <= 0 then
		for _, obj in pairs(character:GetDescendants()) do
			if obj:IsA("Motor6D") and obj:GetAttribute("RagdollJoint") == true then
				table.insert(ragJoints, obj);
				
			elseif obj:IsA("BasePart") then
				if obj.Name == "CollisionRootPart" then continue end;
				table.insert(bodyParts, obj);
			end
		end
	end
	
	for a=1, #ragJoints do
		if ragJoints[a] == nil or not character:IsAncestorOf(ragJoints[a]) then continue end;
		
		ragJoints[a].Parent.BallSocketConstraint.Enabled = ragdollEnabled;
		ragJoints[a].Enabled = not ragdollEnabled;
	end

	for a=1, #bodyParts do
		local obj = bodyParts[a];
		if obj == nil or not character:IsAncestorOf(obj) then continue end;

		if ragdollEnabled and (obj.Name == "LeftHand" or obj.Name == "RightHand" 
			or obj.Name == "LeftFoot" or obj.Name == "RightFoot"
			or obj.Name == "Head" or obj.Name == "UpperTorso" or obj.Name == "LowerTorso") then
			obj.CanCollide = true;
			
		else
			obj.CanCollide = false;
			
		end
	end
end

return CharacterModule;