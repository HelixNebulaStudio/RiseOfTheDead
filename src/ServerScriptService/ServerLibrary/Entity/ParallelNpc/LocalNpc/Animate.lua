local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");

local modAnimationController = require(game.ReplicatedStorage.Library.AnimationController);
local modRegion = require(game.ReplicatedStorage.Library.Region);

local animationLibrary = game.ReplicatedStorage.Prefabs.Animations;

--
local Animate = {}
Animate.__index = Animate;

function Animate.new(parallelNpc)
	local meta = {};
	meta.__index = meta;
	meta.ParallelNpc = parallelNpc;
	
	local self = {
		IsClimbing = false;
		IsSwimming = false;
		
		JointsDestroyed = {};
	};
	
	setmetatable(meta, Animate);
	setmetatable(self, meta);
	
	local prefab: Actor = self.ParallelNpc.Prefab;
	local humanoid: Humanoid = self.ParallelNpc.Humanoid;
	local rootPart: BasePart = self.ParallelNpc.RootPart;
	local animator: Animator = humanoid:WaitForChild("Animator") :: Animator;
	
	if prefab:GetAttribute("ClientSideAnimations") ~= true then return end;
	if prefab:HasTag("Deadbody") then return end;

	local function getAnimationsFolder(animCategoryName, skipFallbacks)
		local npcAnimFolder = animationLibrary:FindFirstChild(prefab.Name);

		if npcAnimFolder and npcAnimFolder:FindFirstChild(animCategoryName) then
			return npcAnimFolder[animCategoryName];
		end
		if skipFallbacks then return end;

		local humanoidAnimFolder = animationLibrary:FindFirstChild(humanoid.Name);
		if humanoidAnimFolder and humanoidAnimFolder:FindFirstChild(animCategoryName) then
			return humanoidAnimFolder[animCategoryName];
		end

		local globalAnimFolder = script;
		return globalAnimFolder:FindFirstChild(animCategoryName);
	end
	
	self.AnimationController = modAnimationController.new(animator, prefab);
	---
	
	self.AnimationController:LoadAnimation("Core", getAnimationsFolder("Core"):GetChildren());
	self.AnimationController:Play("Core");

	local spawnAnims = getAnimationsFolder("Spawn");
	if prefab:GetAttribute("NaturalSpawn") == true and spawnAnims then
		self.AnimationController:LoadAnimation("Spawn", spawnAnims:GetChildren());
		self.AnimationController:Play("Spawn", {FadeTime=0;});
	end
	
	local walkingAnims = getAnimationsFolder("Walking");
	if walkingAnims then
		self.AnimationController:LoadAnimation("Walking", walkingAnims:GetChildren());
		self.AnimationController:SetAnimationMeta("Walking", walkingAnims, self);
	end
	
	local runningAnims = getAnimationsFolder("Running");
	if runningAnims then
		self.AnimationController:LoadAnimation("Running", runningAnims:GetChildren());
		self.AnimationController:SetAnimationMeta("Running", runningAnims, self);
	end
	
	local climbingAnims = getAnimationsFolder("Climbing");
	if climbingAnims then
		self.AnimationController:LoadAnimation("Climbing", climbingAnims:GetChildren());
		self.AnimationController:SetAnimationMeta("Climbing", climbingAnims, self);
	end
	
	
	local function movementUpdate(speed)
		speed = speed or 0;
		if humanoid:GetAttribute("IsDead") == true then return end;
		
		if speed > 0 then
			self.AnimationController.MovementState = "Running";
			if humanoid.WalkSpeed <= 10 and walkingAnims then
				self.AnimationController.MovementState = "Walking";
			end
			if self.IsSwimming then
				self.AnimationController.MovementState = "SwimIdle";
			end
			if self.IsClimbing then
				self.AnimationController.MovementState = "Climbing";
			end

		else
			self.AnimationController.MovementState = "Idle";

		end

		if self.AnimationController.MovementState == "Running" then
			self.AnimationController:Play(self.AnimationController.MovementState);

		elseif self.AnimationController.MovementState == "Walking" then
			self.AnimationController:Play(self.AnimationController.MovementState);

		elseif self.AnimationController.MovementState == "SwimIdle" then
			self.AnimationController:Play(self.AnimationController.MovementState);
			
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
	humanoid.Running:Connect(function(speed)
		self.CurrentSpeed = speed;
		
		if speed > movingSpeedThreshold then
			movementUpdate(speed);

		else
			movementUpdate(0);
			
		end

		while self.CurrentSpeed > 0 do
			task.wait(1);
			if modRegion:InRegion(rootPart.AssemblyLinearVelocity, Vector3.zero, 1) then
				movementUpdate(0);
				self.CurrentSpeed = 0;
				break;
			end
		end
	end)
	
	humanoid.StateChanged:Connect(function(oldState: Enum.HumanoidStateType, newState: Enum.HumanoidStateType)
		--Debugger:Warn("oldState",oldState,"newState",newState);
		if not self.AnimationController:IsPlaying("Core") then
			self.AnimationController:Play("Core");
		end
		
		if newState == Enum.HumanoidStateType.Running then
			self.IsClimbing = false;
			self.IsSwimming = false;

		elseif newState == Enum.HumanoidStateType.Climbing then
			self.IsClimbing = true;
			self.IsSwimming = false;

		elseif newState == Enum.HumanoidStateType.Swimming then
			self.IsClimbing = false;
			self.IsSwimming = true;
			
		end
		
		movementUpdate(self.CurrentSpeed);
	end)
	
	prefab.DescendantRemoving:Connect(function(object)
		if object:IsA("Motor6D") then
			self.JointsDestroyed[object.Name] = true;
		end
	end)
	
	local deathAnimFolder = getAnimationsFolder("Death");
	if deathAnimFolder then
		self.AnimationController:LoadAnimation("Death", deathAnimFolder:GetChildren());
		self.AnimationController:ConnectMarker("Death", "Fire", function(trackData, paramString)
			local args = string.split(tostring(paramString), ";");

			if args[1] == "DeathPause" then
				local track: AnimationTrack = trackData.Track;
				track:AdjustSpeed(0);
			end
		end)
	end
	

	local flinchAnimFolder = getAnimationsFolder("Flinch");
	if flinchAnimFolder then
		self.AnimationController:LoadAnimation("Flinch", flinchAnimFolder:GetChildren());
		
		local lastHealth = humanoid.Health;
		humanoid.HealthChanged:Connect(function(health)
			if health < lastHealth then
				self.AnimationController:Play("Flinch", {
					FadeTime=0.05;
					Speed=2;
				})
			end
			lastHealth = health;
		end);
	end
	
	humanoid:GetAttributeChangedSignal("IsDead"):Connect(function()
		if humanoid:GetAttribute("IsDead") ~= true then return end;
		
		self.AnimationController:StopAll();
		task.wait();
		--Debugger:Warn("Play death");
		self.AnimationController:Play("Death");
	end)

	local aggroAnimFolder = getAnimationsFolder("Aggro", true);
	if aggroAnimFolder then
		local aggroLevelList = {};
		for _, anim in pairs(aggroAnimFolder:GetChildren()) do
			local lvl = anim.Name;
			if aggroLevelList[lvl] == nil then aggroLevelList[lvl] = {} end;
			table.insert(aggroLevelList[lvl], anim);
		end
		for lvl, list in pairs(aggroLevelList) do
			self.AnimationController:LoadAnimation("Aggro"..lvl,  list);
		end
		
		self.AggressLevel = 0;
		local prevAggressLevel = 0;
		humanoid:GetAttributeChangedSignal("AggressLevel"):Connect(function()
			self.AggressLevel = humanoid:GetAttribute("AggressLevel");
			local aggroLevelChanged = prevAggressLevel ~= self.AggressLevel;
			prevAggressLevel = self.AggressLevel;
			if humanoid:GetAttribute("IsDead") == true then return end;
			
			if aggroLevelChanged then
				if aggroLevelList[tostring(self.AggressLevel)] then
					self.AnimationController:Play("Aggro"..self.AggressLevel);
				end
			end
		end)
		
	end
	
	
	function self:OnRemoteEvent(action, ...)
		if action == "settimescale" then
			self.AnimationController:SetTimescale(...);
			return;
				
		end
		
		--==
		local categoryId = ...;

		if self.AnimationController:HasAnim(categoryId) == false then
			local anims = getAnimationsFolder(categoryId);
			if anims then
				self.AnimationController:LoadAnimation(categoryId,  anims:GetChildren());
				self.AnimationController:SetAnimationMeta(categoryId, anims, self);
			end
		end

		if self.AnimationController:HasAnim(categoryId) then
			if action == "play" then
				local fadeTime, weight, speed = select(3, ...);
				local paramPacket = {
					FadeTime=fadeTime;
					Weight=weight;
					Speed=speed;
				};

				self.AnimationController:Play(categoryId, paramPacket);

			elseif action == "stop" then
				local fadeTime, weight, speed = select(3, ...);
				local paramPacket = {
					FadeTime=fadeTime;
					Weight=weight;
					Speed=speed;
				};

				self.AnimationController:Stop(categoryId, paramPacket);

			end
		end
	end
	
	return self;
end

return Animate;