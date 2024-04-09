local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;


return function(self)
	local tree = modLogicTree.new{
		AggroSelect={"Or"; "AttackSequence"; "MoveSequence"; "DangerSequence";};
		AggroSequence={"And"; "HasTarget"; "AggroSelect";};
		Root={"Or"; "StatusLogic"; "AggroSequence";};
		AttackSequence={"And"; "CanAttackTarget"; "Attack";};
		DangerSequence={"And"; "IsInDanger"; "MoveToSafety";};
		MoveSequence={"And"; "MoveToTarget"; "Sprint";};
	}
	
	local targetHumanoid, targetRootPart: BasePart;
	local cache = {};
	cache.AttackCooldown = tick();
	cache.MoveToCooldown = tick();
	cache.SprintCooldown = tick();
	cache.DangerTick = tick();
	cache.DangerStartTick = tick();

	local projsOverlapParams = OverlapParams.new();
	projsOverlapParams.FilterType = Enum.RaycastFilterType.Include;
	projsOverlapParams.MaxParts = 1;
	--==
	
	tree:Hook("StatusLogic", self.StatusLogic);

	tree:Hook("HasTarget", function() 
		targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		targetRootPart = self.Target and self.Target.PrimaryPart;

		if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			return modLogicTree.Status.Success;
		end

		return modLogicTree.Status.Failure;
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
			return modLogicTree.Status.Failure;
		end;

		cache.AttackCooldown = tick() + (self.Properties.AttackSpeed * math.random(90, 110)/100);


		local targetHumanoid = self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		self.PlayAnimation("Attack",0.05, nil, 2);

		local enemyName = self.Target.Name;
		local enemyPlayer = game.Players:FindFirstChild(enemyName);
		if enemyPlayer then
			remoteCameraShakeAndZoom:FireClient(enemyPlayer, 10, 5, 4, 0.01, true);

			local dir = self.RootPart.CFrame.LookVector;
			modAudio.Play("Punch", self.RootPart);
			modStatusEffects.Launch(enemyPlayer, (dir+Vector3.new(0, 1, 0))*100);

			self:DamageTarget(targetHumanoid.Parent, 10);

		else
			self:DamageTarget(targetHumanoid.Parent, targetHumanoid.MaxHealth*0.1);

		end

		Debugger:Warn("Attack");

		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("MoveToTarget", function()
		if tick() < cache.MoveToCooldown then
			return modLogicTree.Status.Failure;
		end
		cache.MoveToCooldown = tick()+math.random(10,20)/10;
		
		
		local targetRootPart = self.Target.PrimaryPart;
		self.Move:MoveTo(targetRootPart);
		
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("Sprint", function()
		if tick() < cache.SprintCooldown then
			return modLogicTree.Status.Failure;
		end
		cache.SprintCooldown = tick()+math.random(50, 60)/10;
		
		task.delay(1, function()
			self.Move:SetMoveSpeed("set", "sprint", 100, 2, 2);
		end) 

		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("IsInDanger", function()
		if tick() - cache.DangerTick < 10 then return modLogicTree.Status.Failure end;

		local danger = nil
		for a=1, #self.Enemies do
			local rootPart = self.Enemies[a] and self.Enemies[a].Humanoid and self.Enemies[a].Humanoid.Health > 0 and self.Enemies[a].Humanoid.RootPart;
			if rootPart and (self.RootPart.Position-rootPart.Position).Magnitude <= 16 then
				danger = rootPart;
				break;
			end
		end

		local projectileList = CollectionService:GetTagged("Projectile");
		projsOverlapParams.FilterDescendantsInstances = projectileList;
		local hitList = workspace:GetPartBoundsInRadius(self.RootPart.Position, 64, projsOverlapParams);

		if #hitList >= 1 then
			danger = hitList[1];
		end

		if danger and danger ~= cache.DangerPart then
			cache.DangerStartTick = tick();
			cache.DangerPart = danger

			return modLogicTree.Status.Success;
		end


		return modLogicTree.Status.Failure;
	end)

	tree:Hook("MoveToSafety", function()
		local displace = (self.RootPart.Position - cache.DangerPart.Position);
		local runDir = displace.Unit;
		

		self.Move:MoveTo(self.RootPart.Position + runDir * 8);
		
		if displace.Magnitude > 17 or tick()-cache.DangerStartTick > 4 then
			cache.DangerTick = tick();
			cache.DangerPart = nil;

		end

		Debugger:Warn("runToSafety");

		return modLogicTree.Status.Success;
	end)
	
	return tree;
end
