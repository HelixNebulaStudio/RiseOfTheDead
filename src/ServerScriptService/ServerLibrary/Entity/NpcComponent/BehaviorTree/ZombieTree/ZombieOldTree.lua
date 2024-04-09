local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local modAudio = require(game.ReplicatedStorage.Library.Audio);

return function(self)
	local tree = modLogicTree.new{
	    Root={"Or"; "AggroSequence"; "Idle";};
	    AggroSelect={"Or"; "AttackSequence"; "FollowTarget";};
	    AggroSequence={"And"; "HasTarget"; "AggroSelect";};
	    AttackSequence={"And"; "CanAttackTarget"; "Attack";};
	}
	
	local targetHumanoid, targetRootPart;
	local cache = {};
	cache.AttackCooldown = tick();
	
	cache.IdleCooldown = tick();
	cache.IdleWalkCooldown = tick();
	cache.IdleGrowlCooldown = tick();
	
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
		
		if (self.Enemy.Distance <= self.Properties.AttackRange) 
			and (tick() > cache.AttackCooldown) then
			
			self.AnimationController:Stop("Idle");
			
			return modLogicTree.Status.Success;
		end
		
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("Idle", function()
		self.Movement.DefaultWalkSpeed = 5;

		if tick() < cache.IdleCooldown then
			return modLogicTree.Status.Success;
		end
		cache.IdleCooldown = tick() + math.random(45, 95);
		
		if tick() > cache.IdleGrowlCooldown then
			cache.IdleGrowlCooldown = tick() + math.random(80, 130)/10;
			if math.random(1, 10) > 8 then
				self.PlayAnimation("Idle");
				modAudio.Play("ZombieIdle"..math.random(1, 4), self.RootPart).PlaybackSpeed = math.random(0.8, 1.2);
			end
		end
		
		if tick() > cache.IdleWalkCooldown then
			cache.IdleWalkCooldown = tick() + math.random(90, 150)/10;
			
			local spawnPoint = self.FakeSpawnPoint or self.SpawnPoint;
			if (spawnPoint.p-self.RootPart.Position).Magnitude <= 32 then
				
				if math.random(1, 2) == 1 then
					self.PlayAnimation("Idle");
				else
					self.Movement:IdleMove(20);
				end
			else
				self.Movement:Move(spawnPoint.p);
			end
		end
		
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("Attack", function()
		self.Movement:Face(cache.TargetPosition);
		cache.AttackCooldown = tick() + (self.Properties.AttackSpeed * math.random(90, 110)/100);
		
		if self.HeavyAttack1 and math.random(1, 3) == 1 then
			self.HeavyAttack1(targetHumanoid, 10, 2);
		else
			if self.BasicAttack1 then
				self.BasicAttack1(targetHumanoid);
				
			elseif self.BasicAttack2 then
				self.BasicAttack2(targetHumanoid);
				
			end
		end
		
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("FollowTarget", function()
		targetRootPart = self.Target and self.Target.PrimaryPart;
		self.Movement.DefaultWalkSpeed = math.clamp(self.Enemy.Distance-30, 12, 30);
		self.Follow(targetRootPart, 1);
		
		return modLogicTree.Status.Success;
	end)
	
	return tree;
end
