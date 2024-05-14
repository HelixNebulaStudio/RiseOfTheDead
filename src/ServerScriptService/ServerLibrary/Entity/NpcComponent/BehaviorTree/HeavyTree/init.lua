local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local CollectionService = game:GetService("CollectionService");

local modArcTracing = require(game.ReplicatedStorage.Library.ArcTracing);

return function(self)
	local tree = modLogicTree.new{
		AttackSequence={"And"; "CanAttackTarget"; "Attack";};
		Root={"Or"; "StatusLogic"; "SetAggressSequence"; "AggroSequence"; "SetAggressLevel0"; "Idle";};
		AggroSelect={"Or"; "AttackSequence"; "ThrowZombie"; "FollowTarget";};
		SetAggressSequence={"And"; "SetAggress";};
		AggroSequence={"And"; "HasTarget"; "AggroSelect";};
	}
	
	local targetHumanoid, targetRootPart: BasePart;
	local cache = {};
	cache.AttackCooldown = tick();
	cache.LastThrowZombie = nil;

	tree:Hook("StatusLogic", self.StatusLogic);
	
	tree:Hook("HasTarget", function() 
		targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		targetRootPart = self.Target and self.Target.PrimaryPart;
		
		if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			return modLogicTree.Status.Success;
		end

		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("FollowTarget", function()
		targetRootPart = self.Target and self.Target.PrimaryPart;
		
		self.Move:Follow(targetRootPart);
		
		return modLogicTree.Status.Success;
	end)

	tree:Hook("Idle", function()
		return modLogicTree.Status.Success;
	end)

	tree:Hook("CanAttackTarget", function()

		cache.TargetPosition = targetRootPart.CFrame.Position;

		if (self.GetTargetDistance() <= self.Properties.AttackRange) and (tick() > cache.AttackCooldown) then
			return modLogicTree.Status.Success;
		end

		return modLogicTree.Status.Failure;
	end)

	tree:Hook("Attack", function()
		local relativeCframe = self.RootPart.CFrame:ToObjectSpace(CFrame.new(cache.TargetPosition));

		local dirAngle = math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z));
		if math.abs(dirAngle) > 40 then
			cache.AttackCooldown = tick() + math.random(10, 20)/100;
			return modLogicTree.Status.Success;
		end;

		cache.AttackCooldown = tick() + (self.Properties.AttackSpeed * math.random(90, 110)/100);
		self.HeavyAttack1(targetHumanoid, 10, 2);
		
		return modLogicTree.Status.Success;
	end)

	tree:Hook("SetAggressLevel0", function()
		if self.AggressLevel ~= 0 then
			self.AggressLevel = 0;
		end

		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("SetAggressLevel1", function()
		if self.AggressLevel < 1 then
			self.AggressLevel = 1;
		end

		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("SetAggress", function()
		if self.SetAggression then
			tree:Call("SetAggressLevel"..self.SetAggression);
			self.SetAggression = nil;
		end
		
		return modLogicTree.Status.Failure;
	end)

	local arcTracer = modArcTracing.new();
	arcTracer.DebugArc = false;
	arcTracer.RayRadius = 0.5;
	arcTracer.Acceleration = Vector3.new(0, -workspace.Gravity+90, 0);
	arcTracer.Delta = 1/7;
	
	tree:Hook("ThrowZombie", function()
		local rightHand: BasePart = self.Prefab:FindFirstChild("RightHand");
		if rightHand == nil or rightHand.AssemblyRootPart ~= self.RootPart then
			return tree.Failure;
		end;
		
		if cache.LastThrowZombie and tick()-cache.LastThrowZombie <= 7 then return modLogicTree.Status.Failure end;
		cache.LastThrowZombie = tick();
		
		local maxRange = 16;
		local maxScan = 16;
		local rootPos = self.RootPart.Position;
		local npcModulesList = self.NpcService.EntityScan(rootPos, maxRange, maxScan);
		
		local sortedNpcModules = {};
		for a=1, #npcModulesList do
			local npcModule = npcModulesList[a];

			local validNpcModule = (npcModule ~= nil
				and npcModule ~= self
				and npcModule.SinisterImmunity ~= true
				and npcModule.Humanoid ~= nil
				and npcModule.Humanoid.Name == "Zombie" 
				and npcModule.Humanoid.Health > 0
				and npcModule.Properties ~= nil
				and npcModule.Properties.BasicEnemy == true
				and npcModule.Name == "Zombie");
			
			local healthRatio = npcModule.Humanoid.Health/npcModule.Humanoid.MaxHealth;

			if validNpcModule then
				local prefab = npcModule.Prefab;
				local prefabPosition = prefab:GetPivot().Position;

				local dist = (prefabPosition-rootPos).Magnitude;
				
				table.insert(sortedNpcModules, {
					NpcModule=npcModule;
					SortValue=((dist * 0.3) + math.clamp(1-healthRatio, 0, 1)*0.7);
				});
			end
		end
		table.sort(sortedNpcModules, function(a, b) return a.SortValue < b.SortValue; end);
		
		local throwNpcModule = sortedNpcModules[1] and sortedNpcModules[1].NpcModule or nil;
		table.clear(sortedNpcModules);

		local newGrip, stunStatus, throwDiedConn;
		
		local function cancel(force)
			local isCancelled = false;
			if self.IsDead == true then
				isCancelled = true;
			end
			if throwNpcModule == nil 
				or throwNpcModule.Humanoid == nil 
				or throwNpcModule.Humanoid.Health <= 0 
				or throwNpcModule.IsDead 
			then
				isCancelled = true;
			end;
			if rightHand == nil or rightHand.AssemblyRootPart ~= self.RootPart or not self.Prefab:IsAncestorOf(rightHand) then
				isCancelled = true;
			end;
			
			if force == true or isCancelled then
				Debugger.Expire(newGrip, 0);
				
				if throwDiedConn then
					throwDiedConn:Disconnect();
				end
				if stunStatus then
					stunStatus.Expires=tick();
				end
				if self.IsDead ~= true then
					self.StopAnimation("ThrowCore");
					self.Move:SetMoveSpeed("remove", "throw");
					self.Move:Stop();
				end

				if throwNpcModule then
					if throwNpcModule.IsDead ~= true then
						throwNpcModule.Humanoid.PlatformStand = false;
						throwNpcModule.RootPart.Massless = false;
					end
				end
			end
			
			return isCancelled;
		end

		if cancel() then return modLogicTree.Status.Failure; end;

		throwDiedConn = throwNpcModule.Humanoid.Died:Connect(function()
			cancel(true);
		end)
		
		local stunDuration = 5;
		stunStatus = throwNpcModule.EntityStatus:GetOrDefault("Stun", {
			Expires=tick()+stunDuration;
		});
		
		throwNpcModule.Move:Follow(self.RootPart);
		self.Move:Follow(throwNpcModule.RootPart);
		
		local reachDist = 5;
		for a=1, (4 *10) do
			local dist = (throwNpcModule.RootPart.Position-self.RootPart.Position).Magnitude;
			if dist <= reachDist then
				break;
			else
				task.wait(0.1);
			end
			if cancel() then
				break;
			end
		end
		
		if cancel() then return modLogicTree.Status.Failure; end;
		
		local dist = (throwNpcModule.RootPart.Position-self.RootPart.Position).Magnitude;
		if dist > reachDist then
			cancel(true);
			return modLogicTree.Status.Failure; 
		end;

		self.Move:SetMoveSpeed("set", "throw", 0, 9);
		task.wait(0.3);
		if cancel() then return modLogicTree.Status.Failure; end;
		
		self.PlayAnimation("Grab");
		task.wait(0.2);
		if cancel() then return modLogicTree.Status.Failure; end;
		
		self.PlayAnimation("ThrowCore", 0.3);

		if not self.IsDead then
			self:SetNetworkOwner(nil);
		end
		if not self.IsDead then
			throwNpcModule:SetNetworkOwner(nil);
		end
		
		throwNpcModule.RootPart.Massless = true;
		throwNpcModule.Humanoid.PlatformStand = true;
		
		newGrip = script:WaitForChild("ThrowGrip"):Clone();
		throwNpcModule.Garbage:Tag(newGrip);
		self.Garbage:Tag(newGrip);
		newGrip.Parent = rightHand;
		newGrip.Part0 = rightHand;
		newGrip.Part1 = throwNpcModule.RootPart;
		newGrip.Enabled = true;
		
		task.wait(0.3);
		if cancel() then return modLogicTree.Status.Failure; end;
		
		self.Move:Face(targetRootPart, 32, 4);
		
		self.PlayAnimation("Throw");
		task.wait(0.8);
		if cancel() then return modLogicTree.Status.Failure; end;
		
		arcTracer.RayWhitelist = CollectionService:GetTagged("PlayerCharacters");
		table.insert(arcTracer.RayWhitelist, workspace.Environment);

		local origin = self.RootPart.Position;
		local targetPoint = targetRootPart.CFrame.Position + Vector3.new(0,5,0);

		local speed = 50;
		local duration = dist/speed;
		duration = math.clamp(duration, 0.5, 3);
		local velocity = arcTracer:GetVelocityByTime(origin, targetPoint, duration);

		local arcPoints = arcTracer:GeneratePath(origin, velocity, function(arcPoint)
			if (arcPoint.Point.Y-origin.Y) > 64 then return true end;

			if arcPoint.Hit == nil then return end
			
			return true;
		end);
		
		if #arcPoints > 1 then
			newGrip:Destroy();
			task.wait(0.1);

			throwNpcModule.RootPart.Massless = false;
			
			local downAng = CFrame.Angles(-math.pi/2, 0, 0);
			local lastVelocity: Vector3;
			throwNpcModule.Move:Fly(arcPoints, arcTracer.Delta, function(index, arcPoint)
				if index >= (#arcPoints-1) then return true; end;

				throwNpcModule.Humanoid.PlatformStand = true;
				arcPoint.AlignCFrame = arcPoint.AlignCFrame * downAng;
				stunStatus.Expires=tick()+0.2;
				lastVelocity = arcPoint.Velocity;

				return;
			end);

			throwNpcModule.SetAggression = 3;
			task.spawn(function()
				throwNpcModule.RootPart.Massless = false;
				if lastVelocity then
					throwNpcModule.RootPart:ApplyImpulse(lastVelocity);
				end
				
				task.wait(0.3);
				if throwNpcModule.IsDead then return end;
				
				throwNpcModule.Humanoid.PlatformStand = false;
				throwNpcModule.Move:Recompute();
			end)
		end
		
		task.wait(1);
		if cancel() then return modLogicTree.Status.Failure; end;
		self.StopAnimation("ThrowCore");
		
		task.wait(1);
		if cancel() then return modLogicTree.Status.Failure; end;
		self.Move:SetMoveSpeed("remove", "throw");
		
		cancel(true);
		
		return modLogicTree.Status.Failure;
	end)
	
	return tree;
end
