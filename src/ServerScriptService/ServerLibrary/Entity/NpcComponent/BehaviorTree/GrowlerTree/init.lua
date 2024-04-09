local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRegion = require(game.ReplicatedStorage.Library.Region);

return function(self)
	local tree = modLogicTree.new{
		SetAggressSequence={"And"; "SetAggress";};
		Root={"Or"; "StatusLogic"; "SetAggressSequence"; "AggroSequence"; "SetAggressLevel0"; "Idle";};
		AggroSequence={"And"; "HasTarget"; "AggroSelect";};
		AttackSequence={"And"; "CanAttackTarget"; "Attack";};
		AggroSelect={"Or"; "IsTargetVulnerable"; "AttackSequence"; "FollowTarget";};
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

		if self.HeavyAttack1 and math.random(1, 3) == 1 then
			self.HeavyAttack1(targetHumanoid, 10, 2);
		else
			self.BasicAttack2(targetHumanoid);
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

	tree:Hook("IsTargetVulnerable", function()
		local dist = self.GetTargetDistance();
		if dist > 50 then return modLogicTree.Status.Failure; end;
		
		local targetDir = (self.RootPart.Position-targetRootPart.Position).Unit;

		local angle = targetDir:Angle(targetRootPart.CFrame.LookVector);
		if math.abs(angle) < 1.22 then
			self.Move:SetMoveSpeed("set", "walk", 4, 1);
			self.PlayAnimation("Block");
			
		else
			self.Move:SetMoveSpeed("remove", "walk");
			self.StopAnimation("Block");
			
		end;
		
		return modLogicTree.Status.Failure;
	end)
	
	
	return tree;
end
