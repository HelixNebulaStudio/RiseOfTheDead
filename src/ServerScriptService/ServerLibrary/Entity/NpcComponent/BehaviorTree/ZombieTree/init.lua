local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modVector = require(game.ReplicatedStorage.Library.Util.Vector);

return function(self)
	local tree = modLogicTree.new{
		LoseAggroSequence={"And"; "IsAggressLevel2"; "TryForgetFarTarget";};
		AggressLevelSelect={"Or"; "AggressLevel1Sequence"; "SetAggressLevel2"; "AggressLevel2Sequence"; "DamagedAggressSequence"; "LoseAggroSequence"; "FollowTarget";};
		NotIsDamaged={"Not"; "IsDamaged";};
		Root={"Or"; "StatusLogic"; "SetAggressSequence"; "AggroSequence"; "SetAggressLevel0"; "Idle";};
		AggressLevel2Sequence={"And"; "IsAggressLevel2"; "IsTargetOld"; "SetAggressLevel3";};
		DamagedAggressSequence={"And"; "IsDamaged"; "SetAggressLevel3";};
		NotIsDocile={"Not"; "IsDocile";};
		SetAggressSequence={"And"; "SetAggress";};
		AggroSelect={"Or"; "SetAggressLevel1"; "AttackSequence"; "AggressLevelSelect";};
		AggroSequence={"And"; "HasTarget"; "AggroSelect";};
		AggressLevel1Sequence={"And"; "NotIsDamaged"; "IsAggressLevel1"; "NotIsDocile";};
		AttackSequence={"And"; "CanAttackTarget"; "Attack";};
	}
	
	local targetHumanoid, targetRootPart;
	local cache = {};
	cache.AttackCooldown = tick();
	
	cache.IdleCooldown = tick();
	cache.IdleWalkCooldown = tick();
	cache.IdleGrowlCooldown = tick();
	cache.TriggerHostileTick = nil;
	cache.HasTargetTick = nil;
	
	cache.TryForgetTick = nil;
	cache.StartForgetTick = nil;
	
	tree:Hook("StatusLogic", self.StatusLogic);
	
	tree:Hook("HasTarget", function() 
		targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		targetRootPart = self.Target and self.Target.PrimaryPart;
		
		if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			cache.HasTargetTick = tick();
			return modLogicTree.Status.Success;
		end
		
		cache.TriggerHostileTick = nil;
		cache.TryForgetTick = nil;
		cache.StartForgetTick = nil;
		cache.HasTargetTick = nil;
		
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("CanAttackTarget", function()
		
		cache.TargetPosition = targetRootPart.CFrame.p;
		
		local isInRange = modVector:InCenter(self.RootPart.Position, self.Target:GetPivot().Position, self.Properties.AttackRange);
		if isInRange and (tick() > cache.AttackCooldown) then
			return modLogicTree.Status.Success;
		end
		
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("Attack", function()
		local relativeCframe = self.RootPart.CFrame:ToObjectSpace(CFrame.new(cache.TargetPosition));

		local dirAngle = math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z));
		if math.abs(dirAngle) > 50 then
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

	tree:Hook("Idle", function()
		local spawnPoint = self.SpawnPoint.Position;
		
		if self.FakeSpawnPoint then
			spawnPoint = self.FakeSpawnPoint.Position;
		end
		
		if (self.RootPart.Position-spawnPoint).Magnitude >= 16 then
			self.Move:MoveTo(spawnPoint);
			
		else
			cache.TriggerHostileTick = nil;
			
		end
		
		if self.Move.IsMoving == false then
			
			if math.random(1, 10) == 1 then
				self.PlayAnimation("Idle");
				modAudio.Play("ZombieIdle"..math.random(1,4), self.RootPart).PlaybackSpeed = math.random(80, 120)/100;
				
			elseif math.random(1, 10) == 2 then
				self.Move:MoveTo(spawnPoint + Vector3.new(
					(math.random(1, 2) == 1 and 1 or -1) * math.random(4, 16),
					0,
					(math.random(1, 2) == 1 and 1 or -1) * math.random(4, 16)
					));
				
			end
			
		end
		
		return modLogicTree.Status.Success;
	end)

	tree:Hook("FollowTarget", function()
		targetRootPart = self.Target and self.Target.PrimaryPart;
		
		self.Move:Follow(targetRootPart);
		
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("IsDamaged", function()
		if self.Humanoid.Health < self.Humanoid.MaxHealth then
			return modLogicTree.Status.Success; 
		end
		return modLogicTree.Status.Failure;
	end)

	tree:Hook("IsDocile", function()
		if self.DocileDuration and self.DocileDuration <= 0 then
			return modLogicTree.Status.Success;
		end
		if cache.TriggerHostileTick and tick() >= cache.TriggerHostileTick then
			return modLogicTree.Status.Success; 
		end

		local isInRange = modVector:InCenter(self.RootPart.Position, self.Target:GetPivot().Position, math.random(20, 40));
		if isInRange then
			if cache.TriggerHostileTick == nil then
				local docileDuration = self.DocileDuration;

				local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
				if modBranchConfigs.WorldInfo.PublicWorld then
					docileDuration = (docileDuration or 1) + math.random(0,300)/100;

					if self.HordeAttack == true then
						docileDuration = 0;

					elseif modVector:InCenter(self.RootPart.Position, self.Target:GetPivot().Position, 15) then
						docileDuration = math.random(0, 30)/100;
						
					end

				else
					task.wait(math.random(0, 30)/100);
					return tree.Success;
					
				end
				
				
				cache.TriggerHostileTick = tick() + docileDuration;
			end
		end
		
		self.Move:Face(targetRootPart);
		
		return modLogicTree.Status.Failure;
	end)
		
	tree:Hook("IsAggressLevel1", function()
		if self.AggressLevel == 1 then
			return modLogicTree.Status.Success; 
		end
		return modLogicTree.Status.Failure;
	end)

	tree:Hook("IsAggressLevel2", function()
		if self.AggressLevel == 2 then
			return modLogicTree.Status.Success; 
		end
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("SetAggressLevel0", function()
		if self.AggressLevel ~= 0 then
			self.AggressLevel = 0;
			self.Move:SetMoveSpeed("set", "walk", 10, 1);
		end

		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("SetAggressLevel1", function()
		if self.AggressLevel < 1 then
			self.AggressLevel = 1;
			self.Move:SetMoveSpeed("set", "walk", 10, 1);
		end

		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("SetAggressLevel2", function()
		if self.AggressLevel < 2 then
			self.AggressLevel = 2;
			self.Move:SetMoveSpeed("set", "walk", 10, 1);
		end
		
		return modLogicTree.Status.Failure;
	end)

	tree:Hook("SetAggressLevel3", function()
		if self.AggressLevel < 3 then
			self.AggressLevel = 3;
			self.Move:SetMoveSpeed("remove", "walk");
		end
		
		return modLogicTree.Status.Failure;
	end)

	tree:Hook("TryForgetFarTarget", function()
		if self.ForgetEnemies == false then
			return modLogicTree.Status.Failure; 
		end;
		
		local newThread = cache.TryForgetTick == nil;
		cache.TryForgetTick = tick();
		
		if newThread then
			cache.StartForgetTick = tick();
			
			task.spawn(function()
				while (self.Target ~= nil) do
					if self.IsDead then return; end
					if cache.StartForgetTick == nil then return end;
					
					local t = tick();
					local timeSinceLastUpdate = cache.TryForgetTick and t-cache.TryForgetTick or 999;
					local checkCycleDuration = math.clamp((t-cache.StartForgetTick)/3, 5, 15);
					
					if timeSinceLastUpdate >= checkCycleDuration then
						self.Target = nil;
						self.Enemy = nil;
						cache.TryForgetTick = nil;
						cache.StartForgetTick = nil;

						self.Move:Stop();
						
						break;
						
					else
						task.wait(checkCycleDuration);
					end
				end
				
				if self.IsDead then return; end
			end)
			
		end

		return modLogicTree.Status.Failure;
	end)

	tree:Hook("IsTargetOld", function()
		if tick() - cache.HasTargetTick >= 60 then
			return modLogicTree.Status.Success;
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
	
	
	return tree;
end
