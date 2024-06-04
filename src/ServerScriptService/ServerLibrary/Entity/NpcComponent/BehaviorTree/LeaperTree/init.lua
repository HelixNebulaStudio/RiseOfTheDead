local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRegion = require(game.ReplicatedStorage.Library.Region);
local modArcTracing = require(game.ReplicatedStorage.Library.ArcTracing);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local modVector = require(game.ReplicatedStorage.Library.Util.Vector);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);

return function(self)
	local tree = modLogicTree.new{
		AggroSequence={"And"; "HasTarget"; "AggroSelect";};
		Root={"Or"; "StatusLogic"; "SetAggressSequence"; "AggroSequence"; "SetAggressLevel0"; "Idle";};
		AggroSelect={"Or"; "SetAggressLevel1"; "AttackSequence"; "Leap"; "FollowTarget";};
		SetAggressSequence={"And"; "SetAggress";};
		AttackSequence={"And"; "CanAttackTarget"; "Attack";};
	}
	
	local targetHumanoid, targetRootPart: BasePart;
	local cache = {};
	cache.LastLeap = nil;
	cache.LeapFailCounter = nil;
	cache.AttackCooldown = tick();
	
	local linVel: LinearVelocity = Instance.new("LinearVelocity");
	linVel.Enabled = false;
	linVel.ForceLimitsEnabled = false;
	linVel.Attachment0 = self.RootPart.RootRigAttachment;
	linVel.Parent = self.RootPart;
	
	local alignOri: AlignOrientation = Instance.new("AlignOrientation");
	alignOri.Enabled = false;
	alignOri.Responsiveness = 100;
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment;
	alignOri.Attachment0 = self.RootPart.RootRigAttachment;
	alignOri.Parent = self.RootPart;

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
		if math.abs(dirAngle) > 60 then
			cache.AttackCooldown = tick() + math.random(10, 20)/100;
			return modLogicTree.Status.Success;
		end;

		cache.AttackCooldown = tick() + (self.Properties.AttackSpeed * math.random(90, 110)/100);

		if self.HeavyAttack1 and math.random(1, 3) == 1 then
			self.HeavyAttack1(targetHumanoid, 10, 2);
		else
			self.BasicAttack2(targetHumanoid);
		end
		
		local lastLeapTime = cache.LastLeap and tick()-cache.LastLeap;
		if lastLeapTime <= 0.5 then
			local player = game.Players:GetPlayerFromCharacter(self.Target);
			if player then
				modStatusEffects.Knockback(player, self.RootPart, 30, 0.5);

			else
				local kbDir = (self.RootPart.Position-targetRootPart.Position).Unit;
				targetRootPart:ApplyImpulse(kbDir*100);
				
			end
		end
		
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
	--arcTracer.DebugArc = true;
	arcTracer.RayRadius = 1;
	arcTracer.Acceleration = Vector3.new(0, -workspace.Gravity, 0);
	arcTracer.Delta = 1/7;
	
	local downAng = CFrame.Angles(-math.pi/2, 0, 0);
	
	tree:Hook("Leap", function()		
		if cache.LastLeap and tick()-cache.LastLeap <= 5 then return modLogicTree.Status.Failure end;
		cache.LastLeap = tick();
		if self.Humanoid.FloorMaterial == Enum.Material.Air then return modLogicTree.Status.Failure end;

		local dist = self.GetTargetDistance();
		if dist < 16 then return modLogicTree.Status.Failure end;
		
		arcTracer.RayWhitelist = CollectionService:GetTagged("PlayerCharacters");
		table.insert(arcTracer.RayWhitelist, workspace.Environment);
		
		local tarVec = targetRootPart.AssemblyLinearVelocity;
		local origin = self.RootPart.Position;
		local targetPoint = targetRootPart.CFrame.Position + Vector3.new(0,5,0) + Vector3.new(math.clamp(tarVec.X,-30,30), 0, math.clamp(tarVec.Z,-30,30));
		
		local speed = 100;
		local duration = math.clamp(dist/speed, 0.4, 1.6);
		local velocity = arcTracer:GetVelocityByTime(origin, targetPoint, duration);

		local angle = Vector3.yAxis:Angle(velocity);
		if angle >= 1.3 or angle <= 0.1 then return tree.Failure end;
		
		local velMagnitude = velocity.Magnitude;
		if velMagnitude > 200 then return tree.Failure end;
		if not self.IsInVision(targetRootPart) then return tree.Failure end;

		self.Move:SetMoveSpeed("set", "leap", 0, 9);
		
		local hitPart, hitPos;
		local arcPoints = arcTracer:GeneratePath(origin, velocity, function(arcPoint)
			if (arcPoint.Point.Y-origin.Y) > 32 then return true end;
			
			if arcPoint.Hit == nil then return end
			hitPart = arcPoint.Hit;
			hitPos = hitPart.Position;
			
			return true;
		end);
		cache.LastLeap = tick();
		
		if #arcPoints > 0 then
			self.PlayAnimation("LeapStart");
			task.wait(0.3);
			
			if self.IsDead then return end;
			self.PlayAnimation("Leap", 0);
			
			self.Move:Fly(arcPoints, arcTracer.Delta, function(index, arcPoint)
				if index >= (#arcPoints-1) then return true; end;

				self.Humanoid.PlatformStand = true;
				arcPoint.AlignCFrame = arcPoint.AlignCFrame * downAng;
				cache.LastLeap = tick();

				return;
			end);
			self.Humanoid.PlatformStand = false;
		end
		
		if self.IsDead then return modLogicTree.Status.Failure; end;
		self.StopAnimation("Leap");
		self.Move:Recompute();
		
		self.Move:SetMoveSpeed("remove", "leap");
		self.Humanoid.PlatformStand = false;
		
		return modLogicTree.Status.Failure;
	end)
	
	return tree;
end
