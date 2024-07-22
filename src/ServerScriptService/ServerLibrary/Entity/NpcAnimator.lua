local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local animationLibrary = game.ReplicatedStorage.Prefabs.Animations;

local modEmotes = require(game.ReplicatedStorage.Library.EmotesLibrary);
local modAnimationController = require(game.ReplicatedStorage.Library.AnimationController);
local modRegion = require(game.ReplicatedStorage.Library.Region);

return function(self)
	if self.Humanoid == nil then Debugger:Warn("NpcAnimator>>  ",self.Name,"is missing humanoid."); return end;

	local mainPrefab = self.NpcService.GetNpcPrefab(self.Name);
	local npcName = mainPrefab.Name;
	
	local function getAnimationsFolder(animCategoryName)
		local npcAnimFolder = animationLibrary:FindFirstChild(npcName);
		
		if npcAnimFolder and npcAnimFolder:FindFirstChild(animCategoryName) then
			return npcAnimFolder[animCategoryName];
		end
		
		local humanoidAnimFolder = animationLibrary:FindFirstChild(self.Humanoid.Name);
		if humanoidAnimFolder and humanoidAnimFolder:FindFirstChild(animCategoryName) then
			return humanoidAnimFolder[animCategoryName];
		end
		
		local globalAnimFolder = script;
		if globalAnimFolder and globalAnimFolder:FindFirstChild(animCategoryName) then
			return globalAnimFolder[animCategoryName];
		end

		local baseAnimFolder = animationLibrary.Human;
		if baseAnimFolder and baseAnimFolder:FindFirstChild(animCategoryName) then
			return baseAnimFolder[animCategoryName];
		end
		return;
	end
	
	--local animationsPrefabs = animationLibrary:FindFirstChild(npcName) or animationLibrary:FindFirstChild(self.Humanoid.Name);

	if self.Prefab:GetAttribute("ClientSideAnimations") == true then
		
		function self.PlayAnimation(...)
			self.Remote:FireAllClients("Animate", "play", ...);
		end

		function self.StopAnimation(...)
			self.Remote:FireAllClients("Animate", "stop", ...)
		end
		
		function self.SetTimescale(...)
			self.Remote:FireAllClients("Animate", "settimescale", ...);
		end
		
		return;
	end
	
	local animator: Animator = self.Humanoid:WaitForChild("Animator");
	self.Animator = animator;
	
	self.AnimationController = modAnimationController.new(animator);
	
	self.CurrentSpeed = 0;
	
	local function LoadAnimations(category)
		local animCategoryFolder = getAnimationsFolder(category);
		
		
		if not animator:IsDescendantOf(workspace) then return end;
		if self.Prefab:GetAttribute("ClientSideAnimations") == true then return end;
		
		local getFirst = self.AnimationController:GetTrackGroup(category);
		if getFirst then return end;
		
		local animLib = modEmotes:Find(category);
		local animList;
		
		if animCategoryFolder then
			if (animCategoryFolder:IsA("Folder") or animCategoryFolder:IsA("ModuleScript")) then
				animList = animCategoryFolder:GetChildren();
				
			elseif animCategoryFolder:IsA("Animation") then
				animList = {animCategoryFolder};
				
			end
			
		elseif animLib then
			animList = {animLib.Animation};
			
		end
		
		
		if animList == nil and animCategoryFolder == nil then
			Debugger:Warn("Animation library: "..self.Name..":"..tostring(category).." does not exist.");
			return
		end;
		
		if animList then
			for a=1, #animList do
				local trackData = self.AnimationController:LoadAnimation(category, animList[a]);
				if animCategoryFolder and animCategoryFolder:IsA("ModuleScript") then
					self.AnimationController:SetAnimationMeta(category, animCategoryFolder, self);
				end
				if trackData == nil then continue end;
				
				local track = trackData.Track;
				
				local animPriority = animList[a]:GetAttribute("Priority");
				if animPriority == "Action2"
					or category == "Attack" then
					track.Priority = Enum.AnimationPriority.Action2;

				elseif animPriority == "Action" or category == "Flinch" then -- or category == "Walking"
					track.Priority = Enum.AnimationPriority.Movement;

				elseif animPriority == "Movement" 
					or category == "Running" or category == "Walking" or category == "Climbing" then
					track.Priority = Enum.AnimationPriority.Idle;

				elseif animPriority == "Idle" or category == "Idle" then
					track.Priority = Enum.AnimationPriority.Idle;

				elseif animPriority == "Core" or category == "Core" then
					track.Priority = Enum.AnimationPriority.Core;

				else
					track.Priority = Enum.AnimationPriority.Action4;
					animPriority = "Action4";

				end
				
			end
			
		end
	end
	
	function self.SetAnimation(category, animList)
		for a=1, #animList do
			self.AnimationController:LoadAnimation(category, animList[a]);
		end
		
	end
	
	function self.GetAnimation(name)
		LoadAnimations(name);
		local getFirst = self.AnimationController:GetTrackGroup(name);
		if getFirst and #getFirst > 0 then
			return getFirst[1].Track;
		end
		return;
	end
	
	
	function self.StopAllAnimations()
		self.AnimationController:StopAll()
	end
	
	function self.SetTimescale(...)
		self.AnimationController:SetTimescale(...);
	end
	
	function self.PlayAnimation(name, ...)
		if self.IsDead then return end;
		local fadeTime, weight, speed = ...;
		local paramPacket = {
			FadeTime=fadeTime;
			Weight=weight;
			Speed=speed;
		};
		
		LoadAnimations(name);
		self.AnimationController:Play(name, paramPacket);
	end
	
	function self.StopAnimation(name, fadeTime)
		if self.IsDead then return end;
		
		self.AnimationController:Stop(name, {FadeTime=fadeTime;});
	end
	
	function self.UpdateAnimations()
		self.AnimationController:Update();
	end
	
	LoadAnimations("Core");
	self.PlayAnimation("Core");

	LoadAnimations("Running");
	LoadAnimations("Walking");
	LoadAnimations("SwimIdle");
	LoadAnimations("Climbing");
	LoadAnimations("Ragdoll");
	LoadAnimations("Sit");
	
	local walkingAnims = getAnimationsFolder("Walking");
	self.AnimationController.MovementState = "Idle";
	
	
	local function movementUpdate(speed)
		if self.IsDead then return end;
		if self.Movement then self.Movement:UpdateWalkSpeed(); end

		if self.Humanoid.Sit then speed = 0; end;
		if self.Humanoid.PlatformStand and self.RootPart.AssemblyRootPart == self.RootPart then speed = 0; end

		if self.IsSwimming and self.Humanoid.FloorMaterial ~= nil then
			self.IsSwimming = false;
		end
		
		if speed > 0 then
			self.AnimationController.MovementState = "Running";
			if self.Humanoid.WalkSpeed <= 10 and walkingAnims then
				self.AnimationController.MovementState = "Walking";
			end
			if self.IsSwimming then
				self.AnimationController.MovementState = "SwimIdle";
			end
			if self.IsClimbing then
				self.AnimationController.MovementState = "Climbing";
			end
			if self.Humanoid:GetAttribute("RigAttached") == true then
				self.AnimationController.MovementState = "Idle";
			end

		else
			self.AnimationController.MovementState = "Idle";

		end
		
		if self.Prefab:GetAttribute("DebugAnim") == true then
			Debugger:Warn("MovementState", self.AnimationController.MovementState, "cs",self.CurrentSpeed, "s", speed, "ws", self.Humanoid.WalkSpeed, "state", self.Humanoid:GetState());
		end
		if self.AnimationController.MovementState == "Running" then
			self.AnimationController:Play(self.AnimationController.MovementState);

		elseif self.AnimationController.MovementState == "Walking" then
			self.AnimationController:Play(self.AnimationController.MovementState);
			
		elseif self.AnimationController.MovementState == "SwimIdle" then
			self.AnimationController:Play(self.AnimationController.MovementState, {
				Speed=(self.CurrentSpeed/6);
			});

		elseif self.AnimationController.MovementState == "Climbing" then
			self.AnimationController:Play(self.AnimationController.MovementState);
			
		end
		
		if self.DebugAnim then
			game.Debris:AddItem(Debugger:HudPrint(self.RootPart.Position, math.round(speed)), 1);
		end
		
		local categories = {"Running"; "Walking"; "SwimIdle"; "Climbing"};
		for a=1, #categories do
			if categories[a] == self.AnimationController.MovementState then continue end;

			self.AnimationController:Stop(categories[a]);
		end

		self.AnimationController:Update();
	end
	
	local movingSpeedThreshold = 0.1;
	self.Garbage:Tag(self.Humanoid.Running:Connect(function(speed)
		self.IsClimbing = false;
		self.IsSwimming = false;

		self.CurrentSpeed = speed;
		if speed > movingSpeedThreshold then
			movementUpdate(speed);
		end

		while self.CurrentSpeed > 0 do
			task.wait(1);
			if self.RootPart == nil or self.RootPart.AssemblyLinearVelocity.Magnitude <= 0.2 then
				movementUpdate(0);
				self.CurrentSpeed = 0;
				break;
			end
		end
	end));
	
	self.Humanoid:GetAttributeChangedSignal("IsDead"):Connect(function()
		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			track:Stop();
		end
	end)

	local flinchAnims = getAnimationsFolder("Flinch");
	if flinchAnims then
		self.AnimationController:LoadAnimation("Flinch", flinchAnims:GetChildren());
	end
	local lastHealth = self.Humanoid.Health;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(function(health)
		if self.IsDead then return end;
		
		if health < lastHealth then
			if flinchAnims then
				self.AnimationController:Play("Flinch", {
					FadeTime=0.05;
					Speed=2;
				});
			end
		end
		lastHealth = health;
	end));
	
	self.Garbage:Tag(self.Humanoid.Seated:Connect(function()
		if self.IsDead then return end;
		
		if self.Humanoid.Sit then
			local seatPart = self.Humanoid.SeatPart;
			if seatPart:GetAttribute("BedSeat") == true then
				self.AnimationController:Play("BedSleep");
				
			else
				self.AnimationController:Play("Sit");
				
			end
			
		else
			self.AnimationController:Stop("Sit");
			self.AnimationController:Stop("BedSleep");
			
		end
	end))
	
	self.Garbage:Tag(self.Humanoid.Climbing:Connect(function(speed)
		if self.Humanoid.Sit then speed = 0; end;
		
		self.CurrentSpeed = speed;
		if speed > 0 then
			self.IsClimbing = true;
			movementUpdate(speed);
			
		end
	end))

	self.WaistMotor = self.Prefab:FindFirstChild("UpperTorso") and self.Prefab.UpperTorso:FindFirstChild("Waist");
	self.RootMotor = self.Prefab:FindFirstChild("LowerTorso") and self.Prefab.LowerTorso:FindFirstChild("Root");
	
	self.Garbage:Tag(self.Humanoid.Swimming:Connect(function(speed)
		if self.Movement then self.Movement:UpdateWalkSpeed(); end
		if self.Humanoid.Sit then speed = 0; end;
		
		self.CurrentSpeed = speed;
		self.IsSwimming = true;
		
		movementUpdate(speed);
	end));

	self.Garbage:Tag(self.Humanoid.PlatformStanding:Connect(function(value)
		if self.IsDead then return end;
		
		if self.Humanoid.PlatformStand and self.RootPart.AssemblyRootPart == self.RootPart then
			self.AnimationController:Play("Ragdoll");
			
		else
			self.AnimationController:Stop("Ragdoll");
			
		end
	end))
	
end;
