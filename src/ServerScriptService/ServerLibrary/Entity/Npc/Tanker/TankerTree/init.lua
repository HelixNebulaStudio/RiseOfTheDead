local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modParticleSprinkler = require(game.ReplicatedStorage.Particles.ParticleSprinkler);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

return function(self)
	local tree = modLogicTree.new{
		Root={"Or"; "StatusLogic"; "AggroSequence"; "Idle";};
		AggroSelect={"Or"; "RebarSlam"; "RebarTornado"; "FollowTarget";};
		AggroSequence={"And"; "HasTarget"; "AggroSelect";};
	}
	
	--==
	local targetHumanoid: Humanoid;
	local targetRootPart: BasePart;
	
	local cache = {};
	cache.NextAction = "";
	cache.AttackCooldown = tick();
	cache.RebarSlamCooldown = tick()+5;
	cache.RebarSpinCooldown = tick()+5;
	
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
	
	tree:Hook("RebarSlam", function()
		if cache.NextAction ~= "RebarSlam" or tick() < cache.RebarSlamCooldown then
			return modLogicTree.Status.Failure;
		end
		cache.RebarSlamCooldown = tick()+10;
		
		self.Move:Stop();
		task.wait(0.5);
		if self.IsDead then return modLogicTree.Status.Failure; end;
		
		local toolModel = self.Wield.Instances[1];
		local handle = toolModel.PrimaryPart;
		local impactPointAtt = handle.ImpactPoint;
		local impactOrigin = Vector3.new(impactPointAtt.WorldPosition.X, self.RootPart.Position.Y, impactPointAtt.WorldPosition.Z);
		
		self.Move:Face(self.Target.PrimaryPart);

		self.Wield.PlayAnim("SlamAttack");
		task.delay(0.9, function()
			if self.IsDead then return end;
			local raycastPreset = RaycastParams.new();
			raycastPreset.FilterType = Enum.RaycastFilterType.Include;
			raycastPreset.CollisionGroup = "Raycast";
			raycastPreset.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
			
			local rootPart = self.RootPart;
			local dir = rootPart.CFrame.LookVector * Vector3.new(1, 0, 1);
			
			local fencePrefab = script.Parent:WaitForChild("barbedFence");
			
			
			local slamOrigin = impactOrigin + dir*3.5;
			local origin = slamOrigin;
			
			local wallLength = 10;
			for a=1, wallLength do

				local wallRayResult = workspace:Raycast(origin, dir*3.459, raycastPreset);
				local floorRayResult = workspace:Raycast(origin, -Vector3.yAxis*4, raycastPreset);
				
				if floorRayResult then
					local rayPos, rayNorm = floorRayResult.Position, floorRayResult.Normal;

					local particlePacket = {
						Type=1;
						Origin=CFrame.new(rayPos);
						SpreadRange={Min=-0.5; Max=0.5};
						Velocity=Vector3.new(0, 1, 0);
						SizeRange={Min=0.3; Max=0.6};
						Material=Enum.Material.Slate;
						DespawnTime=3;
						Speed=30;
						Color = Color3.fromRGB(65, 46, 33);

						MinSpawnCount=3;
						MaxSpawnCount=4;
					};
					modParticleSprinkler:Emit(particlePacket);
					
					
					local newPrefab: Model = fencePrefab:Clone();
					newPrefab:PivotTo(CFrame.lookAt(rayPos, rayPos + dir) * CFrame.Angles(0, math.rad(90), 0))
					newPrefab.Parent = workspace.Environment;
					
					local fencePart: BasePart = newPrefab:WaitForChild("Fence");
					fencePart.CollisionGroup = "PlayerClips";
					Debugger.Expire(newPrefab, self.HardMode and 35 or 20);
					
				else
					break;
				end

				if wallRayResult then
					break;
				end
				
				origin = origin + dir*3.459;
				task.wait(0.1);
			end
			
		end)
		task.delay(0.8, function()
			if self.IsDead then return end;
			modAudio.Play("Explosion4", self.RootPart).TimePosition = 1;
			for a=1, #self.Enemies do
				local enemyPrefab: Model = self.Enemies[a].Character;
				local enemyPivot = enemyPrefab:GetPivot();
				
				local disp = (enemyPivot.Position-impactPointAtt.WorldPosition);
				local dir = disp.Unit;
				local dist = Vector3.new(disp.X, disp.Y*4, disp.Z).Magnitude;
				
				local damageRange = (self.HardMode and 16 or 12);
				local dmgScaling = modMath.MapNum(math.clamp(dist, 0, damageRange), 
					0, (self.HardMode and 32 or 24), 
					(self.HardMode and 200 or 45), (self.HardMode and 95 or 25)
				);
				
				if dist > damageRange then continue end;
				
				local enemyPlayer = game.Players:GetPlayerFromCharacter(enemyPrefab);
				if enemyPlayer then
					remoteCameraShakeAndZoom:FireClient(enemyPlayer, 10, 5, math.max(4 * (dist/(self.HardMode and 32 or 24)), 1), 0.01, true);
				end
				
				if dmgScaling > (self.HardMode and 95 or 25) then
					if enemyPlayer then
						self:DamageTarget(enemyPlayer.Character, self.HardMode and 200 or 45, nil, nil, "Melee");
					end

					modStatusEffects.Throw(enemyPlayer, dir);
				end
			end
		end)
		
		task.wait(5);
		
		cache.NextAction = "RebarTornado";
		
		return modLogicTree.Status.Success;
	end)

	local hitDebounce = {};
	tree:Hook("RebarTornado", function()
		if cache.NextAction ~= "RebarTornado" or tick() < cache.RebarSpinCooldown then 
			return modLogicTree.Status.Failure;
		end
		cache.RebarSpinCooldown = tick()+20;

		self.Move:Follow(targetRootPart, 4);
		
		self.Wield.PlayAnim("SpinAttack");
		local spinDuration = self.HardMode and math.random(9, 12) or 5;
		
		self.Move:SetMoveSpeed("set", "sprint", self.HardMode and 22 or 18, 2, (spinDuration-2));

		local toolModel = self.Wield.Instances[1];
		local collider = toolModel.Collider;

		if collider:GetAttribute("CollideConn") == nil then
			collider:SetAttribute("CollideConn", true);
			
			local attackSpeed = self.Wield.ToolHandler.ToolConfig.Configurations.PrimaryAttackSpeed;
			
			if self.HardMode then
				self.Wield.ToolHandler.ToolConfig.Configurations.BaseDamage = 15;
			else
				self.Wield.ToolHandler.ToolConfig.Configurations.BaseDamage = 5;
			end
			
			collider.Touched:Connect(function(hitPart)
				if not self.Wield.ToolModule.Properties.Attacking then return end;
				local damagable = modDamagable.NewDamagable(hitPart.Parent);

				if damagable then
					local enemyPrefab: Model = damagable.Model;
					
					if hitDebounce[enemyPrefab] == nil or (tick()-hitDebounce[enemyPrefab]) > attackSpeed then
						hitDebounce[enemyPrefab] = tick();
						
						self.Wield.VictimsList[enemyPrefab] = {Model=enemyPrefab; Damagable=damagable; HitPart=hitPart; HitTick=tick()};
						self.Wield.ToolHandler:PrimaryAttack(damagable, hitPart);
						
						modAudio.Play(math.random(1, 2) == 1 and "BulletBodyImpact" or "BulletBodyImpact2", collider);

						local enemyPlayer = game.Players:GetPlayerFromCharacter(enemyPrefab);
						if enemyPlayer then
							remoteCameraShakeAndZoom:FireClient(enemyPlayer, 10, 5, 0.5, 0.01, true);

							if self.HardMode then
								local dir = (enemyPrefab:GetPivot().Position-self.RootPart.Position).Unit;
								modStatusEffects.Slowness(enemyPlayer, 5, 0.5);
							end
						end
					end
					
				end
			end)
		end
		
		
		local trackData = self.Wield.GetAnim("SpinAttack");
		trackData.CustomSpeed = true;
		
		local track: AnimationTrack = trackData.Track;
		
		if track:GetAttribute("LoopConn") == nil then
			track:SetAttribute("LoopConn", true);
			
			local d=0.4167;
			local isSpinning = false;
			track:GetMarkerReachedSignal("Event"):Connect(function(paramString)
				if paramString == "SpinStart" then
					if isSpinning then return end;
					isSpinning = true;
					
					self.Wield.ToolModule.Properties.Attacking = true;
					local totalA = spinDuration * 10;
					
					local speedStep = (15-10)/totalA;
					local currSpeed = 10
					
					for a=1, totalA do
						self.Wield.ToolModule.Properties.Attacking = true;
						self.Move:Face(self.RootPart.CFrame.Position - self.RootPart.CFrame.RightVector*64, currSpeed);
						task.wait(0.1);
						if self.IsDead then break; end;
						currSpeed = currSpeed + speedStep;
					end

					self.Wield.ToolModule.Properties.Attacking = false;
					track:AdjustSpeed(1);
					isSpinning = false;
				
				elseif paramString == "SpinEnd" then
					track:AdjustSpeed(0);
					
				end

			end)
		end
		
		task.wait(spinDuration+1);

		cache.NextAction = "RebarSlam";

		return modLogicTree.Status.Success;
	end)
	
	
	
	--tree:Hook("CanAttackTarget", function()

	--	cache.TargetPosition = targetRootPart.CFrame.Position;

	--	if (self.GetTargetDistance() <= self.Properties.AttackRange) and (tick() > cache.AttackCooldown) then
	--		return modLogicTree.Status.Success;
	--	end

	--	return modLogicTree.Status.Failure;
	--end)

	--tree:Hook("Attack", function()
	--	local relativeCframe = self.RootPart.CFrame:ToObjectSpace(CFrame.new(cache.TargetPosition));

	--	local dirAngle = math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z));
	--	if math.abs(dirAngle) > 40 then
	--		cache.AttackCooldown = tick() + math.random(10, 20)/100;
	--		return modLogicTree.Status.Failure;
	--	end;

	--	cache.AttackCooldown = tick() + (self.Properties.AttackSpeed * math.random(90, 110)/100);

	--	if self.Wield.Handler then
	--		self.Wield.PrimaryFireRequest();
	--	else
	--		self.BasicAttack2(targetHumanoid);
	--	end

	--	return modLogicTree.Status.Success;
	--end)
	
	
	
	tree:Hook("FollowTarget", function()
		targetRootPart = self.Target and self.Target.PrimaryPart;

		self.Move:Follow(targetRootPart, 4);
		
		if cache.NextAction == "" then
			cache.NextAction = "RebarSlam";
		end
		
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("Idle", function()
		return modLogicTree.Status.Success;
	end)


	return tree;
end
