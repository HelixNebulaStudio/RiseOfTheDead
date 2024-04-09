local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRegion = require(game.ReplicatedStorage.Library.Region);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);

return function(self)
	local tree = modLogicTree.new{
		AggroSequence={"And"; "HasTarget"; "AggroSelect";};
		Root={"Or"; "StatusLogic"; "SetAggressSequence"; "AggroSequence"; "SetAggressLevel0"; "Idle";};
		SetAggressSequence={"And"; "SetAggress";};
		AttackSequence={"And"; "CanAttackTarget"; "Attack";};
		AggroSelect={"Or"; "AttackSequence"; "BurpConfusionGas"; "FollowTarget";};
	}
	
	local targetHumanoid, targetRootPart: BasePart;
	local cache = {};
	cache.AttackCooldown = tick();

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

	tree:Hook("BurpConfusionGas", function()
		if cache.LastBurp and tick()-cache.LastBurp <= 4 then return modLogicTree.Status.Failure end;
		cache.LastBurp = tick();
		
		if not self.IsInVision(targetRootPart) then return modLogicTree.Status.Failure end;
		
		self.Move:SetMoveSpeed("set", "burp", 0, 9);
		task.wait(0.1);
		self.Move:Face(targetRootPart);
		
		self.PlayAnimation("Burp");
		task.wait(math.random(350,450)/1000);
		
		local level = (self.Configuration.Level-1);
		for a=1, math.random(4,6) do
			local headCframe = self.Head.CFrame;
			local origin = headCframe.Position + headCframe.LookVector;
			
			local aimDir = (targetRootPart.Position-origin).Unit;
			local burpSpeed = 10 + (level/25);
			local velocity = modMath.CFrameSpread(aimDir, 5) * (burpSpeed+ math.random(0,2));

			local projectileObject = modProjectile.Fire("confusionGas", CFrame.new(origin));
			projectileObject.Owner = self.Prefab;
			
			modProjectile.ServerSimulate(projectileObject, origin, velocity, {CollectionService:GetTagged("PlayerCharacters")});
			
			task.wait(math.random(500,700)/1000);
		end
		
		task.wait(math.random(250,350)/1000);
		self.Move:SetMoveSpeed("remove", "burp");

		cache.LastBurp = tick();
		return modLogicTree.Status.Failure;
	end)
	
	return tree;
end
