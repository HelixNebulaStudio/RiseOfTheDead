local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local modExplosionHandler = require(game.ReplicatedStorage.Library.ExplosionHandler);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRegion = require(game.ReplicatedStorage.Library.Region);

local explosionEffectPrefab = script:WaitForChild("ExplosionEffect");
return function(self)
	local tree = modLogicTree.new{
		IgniteSequence={"And"; "Ignite"; "Detonate";};
		Root={"Or"; "StatusLogic"; "SetAggressSequence"; "AggroSequence"; "SetAggressLevel0"; "Idle";};
		AggroSelect={"Or"; "SetAggressLevel1"; "IgniteSequence"; "FollowTarget"; };
		SetAggressSequence={"And"; "SetAggress";};
		AggroSequence={"And"; "HasTarget"; "AggroSelect";};
	}
	
	local targetHumanoid, targetRootPart;
	local cache = {};

	tree:Hook("StatusLogic", self.StatusLogic);
	
	tree:Hook("HasTarget", function() 
		targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		targetRootPart = self.Target and self.Target.PrimaryPart;
		
		if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			return modLogicTree.Status.Success;
		end

		self.Prefab:SetAttribute("DetonationTime", nil);
		
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

	tree:Hook("Ignite", function()
		if self.Detonated then
			return modLogicTree.Status.Failure;
		end
		
		local detonTime = self.Prefab:GetAttribute("DetonationTime");
		if detonTime == nil then
			if modRegion:InRegion(self.RootPart.Position, self.Target:GetPivot().Position, 30) then
				local duration = 4;
				self.Prefab:SetAttribute("DetonationTime", workspace:GetServerTimeNow()+duration);
				
				local tickingSound = modAudio.Play("ZombieAttack3", self.RootPart);
				tickingSound.Looped = true;
				tickingSound.Volume = 0;
				self.Garbage:Tag(tickingSound);
				
				task.spawn(function()
					detonTime = self.Prefab:GetAttribute("DetonationTime");
					while workspace:GetServerTimeNow() <= detonTime do
						if self.Prefab:GetAttribute("DetonationTime") == nil then return end;
						local timeLeft = self.Prefab:GetAttribute("DetonationTime")-workspace:GetServerTimeNow();
						
						timeLeft = duration-math.clamp(timeLeft, 0, duration);
						
						tickingSound.PlaybackSpeed = 1+ (timeLeft/duration * 8);
						tickingSound.Volume = math.clamp(timeLeft/duration, 0.5, 1);
						task.wait(0.2);
						if self.IsDead then break end;
					end

					game.Debris:AddItem(tickingSound, 0);
					if self.IsDead then return end;
					tree:Call("Detonate");
				end)
			end
			
		end
		
		return modLogicTree.Status.Failure;
	end)

	tree:Hook("Detonate", function()
		if self.Detonated then
			return modLogicTree.Status.Failure;
		end
		self.Detonated = true;
		
		if self.IsDead then return end;
		modAudio.Play("TicksZombieExplode", self.RootPart.Position).PlaybackSpeed = math.random(100,120)/100;
		
		local newEffect = explosionEffectPrefab:Clone();
		local effectMesh = newEffect:WaitForChild("Mesh");
		newEffect.CFrame = self.Head.CFrame;
		newEffect.Parent = workspace.Debris;
		local speed = 0.5;
		local range = 60;

		self.Remote:FireAllClients("Ticks", "detonate", {effectMesh, speed, range});
		Debugger.Expire(newEffect, 1);
		
		local detonatePosition = self.RootPart.Position;

		local damage = self.Properties.AttackDamage * (1-math.clamp(self.GetTargetDistance() or 15, 0, 30)/30);
		if damage >= 1  then
			task.spawn(function()
				local hitLayers = modExplosionHandler:Cast(detonatePosition, {
					Radius = 24;
				});

				modExplosionHandler:Process(detonatePosition, hitLayers, {
					Owner = self.Owner;
					StorageItem = self.StorageItem;
					TargetableEntities = {
						Zombie=1;
						Bandit=1;
						Cultist=1;
						Rat=1;
					};

					Damage = damage;
					ExplosionStun = 1;
					ExplosionStunThreshold = 0;

					DamageOrigin = detonatePosition;
					OnDamagableHit = function(damagable, damage)
						if damagable.Object.ClassName == "NpcStatus" then
							local npcModule = damagable.Object:GetModule();
							local healthInfo = damagable:GetHealthInfo();
							if npcModule.Properties and npcModule.Properties.BasicEnemy then
								damage = healthInfo.MaxHealth * 0.2;
								task.spawn(function()
									if npcModule == self then return end;
									if npcModule.IsDead then return end;
									if npcModule.Name ~= "Ticks" then return end;

									npcModule.BehaviorTree:RunTreeLeaf("TicksTree", "Detonate");
								end)

							else
								damage = healthInfo.MaxHealth * 0.05;
							end
							
						elseif damagable.Object.ClassName == "PlayerClass" then
							local classPlayer = damagable.Object;

							local gasProtection = classPlayer:GetBodyEquipment("GasProtection");
							if gasProtection then
								damage = damage * (1-gasProtection);
							end

							if classPlayer.Properties.tickre then
								return;
							end

							local tickRepellent = classPlayer:GetBodyEquipment("TickRepellent");
							if tickRepellent then
								classPlayer:SetProperties("tickre", {Expires=workspace:GetServerTimeNow()+tickRepellent; Duration=tickRepellent; Amount=tickRepellent;});
							end

						end

						self:DamageTarget(targetHumanoid.Parent, damage);
					end
				});
			end)
		end

		task.spawn(function()
			game.Debris:AddItem(self.Prefab:FindFirstChild("ExplosiveTickBlobs"), 0);
			
			local explosionPoint = self.RootPart.Position + Vector3.new(math.random(-20,20)/100, -0.5, math.random(-20,20)/100);
			for _, obj: BasePart in pairs(self.Prefab:GetChildren()) do
				if not obj:IsA("BasePart") then continue end;
				
				local motor = obj:FindFirstChildWhichIsA("Motor6D")
				if motor and motor:GetAttribute("RagdollJoint") and obj.Name ~= "LowerTorso" then
					self:BreakJoint(motor);
					
					local force = math.random(80, 140);
					local dir = (obj.Position-explosionPoint).Unit;
					local vel = dir * obj.AssemblyMass * force;
					obj:ApplyImpulse(vel);
				end
				
			end
		end)
		self.Humanoid.Health = 0;
		

		local remotes = game.ReplicatedStorage.Remotes;
		local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;
		local player = game.Players:GetPlayerFromCharacter(self.Target);
		local dist = player and player:DistanceFromCharacter(self.RootPart.Position);
		if dist and dist < 32 then
			remoteCameraShakeAndZoom:FireClient(player, 10 * math.clamp(dist/32, 0, 1), 0, 0.5, 0.01, false);
		end
		
		return modLogicTree.Status.Success;
	end)
	
	return tree;
end
