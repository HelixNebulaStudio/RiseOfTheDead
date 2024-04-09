local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local TweenService = game:GetService("TweenService");

--==
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modAoeHighlight = require(game.ReplicatedStorage.Particles.AoeHighlight);

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local defaultC0 = CFrame.new(0, 0, 0);

return function(self)
	local tree = modLogicTree.new{
	    Root={"Or"; "AggroSequence"; "Idle";};
		AggroSelect={"Or"; "AttackSequence"; "StrikeTarget";};
	    AggroSequence={"And"; "HasTarget"; "AggroSelect";};
	    AttackSequence={"And"; "CanAttackTarget"; "Attack";};
	}
	
	local targetHumanoid, targetRootPart;
	local cache = {};
	cache.AttackCooldown = tick();
	
	cache.IsJawOpen = true;
	cache.LastStrikeCooldown = nil;
	
	cache.ForgetTargetTime = tick();
	
	tree:Hook("HasTarget", function() 
		targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		targetRootPart = self.Target and self.Target.PrimaryPart;
		
		if self.Target and tick() > cache.ForgetTargetTime then
			cache.ForgetTargetTime = tick() + math.random(10, 20)/10;
		end
		
		if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			return modLogicTree.Status.Success;
		end
		
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("CanAttackTarget", function()
		cache.TargetPosition = targetRootPart.CFrame.p;
		
		if not cache.IsJawOpen and (self.Enemy.Distance <= self.Properties.AttackRange) and (tick() > cache.AttackCooldown) and (self.DamageWeakSpotCount < 3) then
			return modLogicTree.Status.Success;
		end
		
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("Idle", function()
		task.wait(1);
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("Attack", function()
		cache.AttackCooldown = tick() + self.Properties.AttackSpeed;
		self.BasicAttack1(targetHumanoid, {
			SkipMeleeDelay=true;
		});
		
		task.wait(1);
		return modLogicTree.Status.Success;
	end)
	
	local diameter = 22;
	local function flashCylinder(cframe)
		local newCylinder = modAoeHighlight.newCylinder(1);
		newCylinder.CFrame = cframe
		newCylinder.Size = Vector3.new(2, 2, 1);
		newCylinder.Parent = workspace.Entities;

		TweenService:Create(newCylinder, TweenInfo.new(0.45), {Size = Vector3.new(diameter, diameter, 1)}):Play();
		task.wait(0.45);
		TweenService:Create(newCylinder, TweenInfo.new(0.45), {Size = Vector3.new(2, 2, 1)}):Play();
		task.wait(0.45);
	end
	
	tree:Hook("StrikeTarget", function()
		targetRootPart = self.Target and self.Target.PrimaryPart;
		local targetPlayer = game.Players:GetPlayerFromCharacter(self.Target);
		
		if targetRootPart == nil then
			return modLogicTree.Status.Failure;
		end

		local distanceFromJaws = (targetRootPart.Position - self.RootPart.Position).Magnitude;
		self.Enemy.Distance = distanceFromJaws;
		
		if not cache.IsJawOpen then
			local isPlayerCaught = self.Enemy.Distance <= self.Properties.AttackRange;
			
			for a=1, #self.JawMotors do
				local motor = self.JawMotors[a];

				TweenService:Create(motor, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					C0=(motor.Name == "RJawMotor" 
						and defaultC0 * CFrame.Angles(0, 0, math.rad(90))
						or defaultC0 * CFrame.Angles(0, 0, math.rad(-90)));
				}):Play();
			end
			cache.IsJawOpen = true;

			task.wait(1);
			if isPlayerCaught then
				modAudio.Play("Burp", self.RootPart).PlaybackSpeed = math.random(8, 10)/10;
				
			end
		end

		if self.Head.Parent == self.Prefab then
			TweenService:Create(self.Head, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame=self.Head.CFrame * CFrame.new(0, -5, 0)}):Play();
		end
		
		self.Head.Parent = nil;
		for a=1, #self.JawPrefabs do
			self.JawPrefabs[a].Parent = nil;
		end
		
		modAudio.Play("RisingRumble", self.RootPart);
		if targetPlayer then
			remoteCameraShakeAndZoom:FireClient(targetPlayer, 2, 2, 5, 0.01);
		end
		task.wait(0.5);
		
		local groundCframe;
		for a=1, 3 do
			groundCframe = modAoeHighlight:Ray(targetRootPart.Position + Vector3.yAxis*4, Vector3.new(0, -16, 0));
			
			if groundCframe then
				flashCylinder(groundCframe);
			end
		end
		
		groundCframe = modAoeHighlight:Ray(targetRootPart.Position + Vector3.yAxis*4, Vector3.new(0, -16, 0));
		if groundCframe == nil then return modLogicTree.Status.Failure; end;
		
		
		local baseCf = CFrame.new(groundCframe.Position) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
		
		local newCylinder = modAoeHighlight.newCylinder(2.3);
		newCylinder.CFrame = groundCframe
		newCylinder.Size = Vector3.new(2, 2, 1);
		newCylinder.Parent = workspace.Entities;
		
		TweenService:Create(newCylinder, TweenInfo.new(0.4), {Size = Vector3.new(diameter, diameter, 1)}):Play();
		task.wait(0.5);
		
		self.Prefab:PivotTo(baseCf);
		self.Head.CFrame = baseCf * CFrame.new(0, -6, 0);
		
		self.Head.Parent = self.Prefab;
		for a=1, #self.JawPrefabs do
			self.JawPrefabs[a].Parent = self.Prefab;
		end
		
		modAudio.Play("JawsChomp", self.RootPart).PlaybackSpeed = math.random(85, 95)/100;
		if targetPlayer then
			remoteCameraShakeAndZoom:FireClient(targetPlayer, 10, 5, 1, 0.01);
		end
		task.wait(0.1);
		TweenService:Create(self.Head, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame=baseCf * CFrame.new(0, 1, 0)}):Play();
		task.wait(0.15);
		
		for a=1, #self.JawMotors do
			local motor = self.JawMotors[a];
			
			motor.C0 = (motor.Name == "RJawMotor"
				and defaultC0 * CFrame.Angles(0, 0, math.rad(90))
				or defaultC0 * CFrame.Angles(0, 0, math.rad(-90)));
			
			TweenService:Create(motor, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				C0=defaultC0;
			}):Play();
		end
		
		task.delay(0.2, function()
			self.Head.CFrame = baseCf * CFrame.Angles(0, math.rad(0.05), 0);
		end)

		cache.IsJawOpen = false;
		distanceFromJaws = (targetRootPart.Position - self.RootPart.Position).Magnitude;
		self.Enemy.Distance = distanceFromJaws;

		if distanceFromJaws < self.Properties.AttackRange then
			self.DamageWeakSpotCount = 0;
			if targetHumanoid then
				local distance = 0;
				if targetHumanoid.RootPart and self.Humanoid.RootPart then
					distance = (targetHumanoid.RootPart.Position - self.Humanoid.RootPart.Position).Magnitude;
				end

				if distance >= self.Properties.AttackRange then
					return modLogicTree.Status.Failure;
				end
				
				local dmgRange = math.pow((1-math.clamp(distance/self.Properties.AttackRange, 0, 1)), 1/2);
				self:DamageTarget(targetHumanoid.Parent, dmgRange * 70);

			end
			
		else
			task.wait(0.35);
			for a=1, #self.JawMotors do
				local motor = self.JawMotors[a];

				TweenService:Create(motor, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					C0=(motor.Name == "RJawMotor" 
						and defaultC0 * CFrame.Angles(0, 0, math.rad(45))
						or defaultC0 * CFrame.Angles(0, 0, math.rad(-45)));
				}):Play();
			end

			task.wait(5);
		end
		task.wait(1);

		return modLogicTree.Status.Success;
	end)
	
	return tree;
end
