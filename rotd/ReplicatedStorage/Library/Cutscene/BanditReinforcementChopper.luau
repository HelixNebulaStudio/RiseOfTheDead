local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modRaycastUtil = shared.require(game.ReplicatedStorage.Library.Util.RaycastUtil);

local cutscenePackage = {};
--==

-- /playcutscene BanditReinforcementChopper
-- shared.modCutscene:PlayCutscene("BanditReinforcementChopper", {SpawnPosition=Vector3.zero;});

--MARK: run
function cutscenePackage.run(CutsceneSequence)
	local BANDIT_HELICOPTERS = {
		BASE = {
			Model = game.ServerStorage.Prefabs.Objects:WaitForChild("BanditHelicopterRig");
			CenterOffset = Vector3.new(-15, -2.75, 0);
			BoundSize = Vector3.new(73.522, 15.758, 41.169);
		};
	};
	local HOVER_GROUND_HEIGHT = 3;
	local DESCENT_HEIGHT = 100;

	local function getLandingZone(spawnPosition: Vector3, centerOffset: Vector3, boundSize: Vector3): CFrame?
		local groundHit = modRaycastUtil.getGround(spawnPosition, 16);
		if groundHit == nil then
			Debugger:Warn("No ground found at spawnPosition", spawnPosition);
			return nil;
		end

		local checkOrigin = spawnPosition + Vector3.new(0, -spawnPosition.Y + groundHit.Position.Y + HOVER_GROUND_HEIGHT + boundSize.Y/2, 0);
		local maxFootprint = math.max(boundSize.X, boundSize.Z);
		local openCf = modRaycastUtil.findOpenSpace(checkOrigin, {
			BoundSize = Vector3.new(maxFootprint, boundSize.Y, maxFootprint);
			Radius = maxFootprint;
			RingStep = 8;
		});
		if openCf == nil then
			Debugger:Warn("No open space found around spawnPosition", spawnPosition);
			return nil;
		end

		return openCf * CFrame.Angles(0, math.rad(math.random(0, 360)), 0) * CFrame.new(-centerOffset);
	end

	CutsceneSequence:Initialize(function(params)
		local spawnPosition = params.SpawnPosition;
		if typeof(spawnPosition) ~= "Vector3" and typeof(params.CmdPlayerCFrame) == "CFrame" then
			spawnPosition = params.CmdPlayerCFrame.Position;
		end

		if typeof(spawnPosition) ~= "Vector3" then
			Debugger:Warn("Invalid SpawnPosition", spawnPosition);
			return;
		end

		local bindNpcSpawnCallback = params.BindNpcSpawnCallback or function(npcClass: NpcClass)
		end;

		local spawnModel = "BASE";
		local banditHeliInfo = BANDIT_HELICOPTERS[spawnModel]

		local boundSize = banditHeliInfo.BoundSize;
		local lzCFrame = getLandingZone(spawnPosition, banditHeliInfo.CenterOffset, boundSize);
		if lzCFrame == nil then
			Debugger:Warn("Failed to find a valid landing zone for", spawnPosition);
			return;
		end

		local maxFootprint = math.max(boundSize.X, boundSize.Z);
		local rayResults = modRaycastUtil.RingCast(
			lzCFrame.Position, 
			Vector3.yAxis * DESCENT_HEIGHT, 
			nil, maxFootprint, nil);

		if #rayResults > 0 then
			Debugger:Warn("Landing zone not clear.", rayResults);
			return;
		end

		local skyCFrame = lzCFrame * CFrame.new(0, DESCENT_HEIGHT, 0);
		local flyInCFrame = (skyCFrame * CFrame.new(0, DESCENT_HEIGHT, 0)) -skyCFrame.RightVector * 256;


		local newHeliModel = banditHeliInfo.Model:Clone();
		newHeliModel.Name = "BanditReinforcementHelicopter";
		local heliRp = newHeliModel:WaitForChild("Root");
		heliRp.Anchored = true;
		newHeliModel:SetAttribute("DynamicPlatform", true);
		newHeliModel:PivotTo(flyInCFrame);

		local dropOriginAtt = {};
		
		for _, obj in pairs(heliRp:GetChildren()) do
			if obj.Name ~= "DropOrigin" then continue end;
			obj:ClearAllChildren();
			table.insert(dropOriginAtt, obj);
		end

		local function setHeliCanCollide(v)
			for _, part in pairs(newHeliModel:GetDescendants()) do
				if not part:IsA("BasePart") then continue end;
				part.CanCollide = v;
			end
		end
		setHeliCanCollide(false);

		local heliSpinOut, heliYaw = nil, 0;
		local tweenValueInstance = Instance.new("CFrameValue");
		tweenValueInstance.Name = "RootCFrame";
		tweenValueInstance.Parent = heliRp;

		tweenValueInstance.Value = flyInCFrame;
		newHeliModel.Parent = workspace.Environment;

		task.spawn(function()
			while workspace:IsAncestorOf(newHeliModel) do
				task.wait();

				if heliSpinOut then
					local spinOutTl = tick()-heliSpinOut;
					local mapSpin = 1-math.clamp(spinOutTl/4, 0.1, 1);
					heliYaw += (math.pi/(mapSpin * 3) /60);
				end

				local newCFrame = tweenValueInstance.Value;
				local swayRot = CFrame.Angles(math.sin(tick()/2)/8, heliYaw, math.sin(tick()/2)/8);

				newCFrame = newCFrame * swayRot;

				newHeliModel:PivotTo(newCFrame);
			end
		end)

		local animationController = newHeliModel:WaitForChild("AnimationController");
		local animationsFolder = newHeliModel:WaitForChild("Animations");

		local topRotorAnimation = animationController:LoadAnimation(animationsFolder:WaitForChild("TopRotor"));
		topRotorAnimation:Play();
		modAudio.Play("HelicopterCore", heliRp);

		local openDoorsAnimation = animationController:LoadAnimation(animationsFolder:WaitForChild("OpenDoors"));


		local destructConfig: Configuration = modDestructibles.createDestructible("Helicopter");
		destructConfig:SetAttribute("MaxHealth", 5000);
		destructConfig.Parent = newHeliModel;

		local heliDestructible: DestructibleInstance = modDestructibles.getOrNew(destructConfig);
		heliDestructible:SetEnabled(false);
		local heliHealthComp: HealthComp = heliDestructible.HealthComp;

		heliHealthComp.OnIsDeadChanged:Connect(function(isDead)
			if not isDead then return end;
			setHeliCanCollide(true);
		end)

		local tweenA: Tween, tweenB: Tween, tweenC: Tween;
		tweenA = TweenService:Create(
			tweenValueInstance, 
			TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
			{
				Value = skyCFrame;
			}
		);
		tweenB = TweenService:Create(
			tweenValueInstance, 
			TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
			{
				Value = lzCFrame;
			}
		);
		tweenC = TweenService:Create(
			tweenValueInstance, 
			TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
			{
				Value = skyCFrame;
			}
		);

		local tweenADone = false;
		tweenA.Completed:Connect(function(state)
			if heliHealthComp.IsDead then return end;
			if tweenADone then return end;
			tweenADone = true;

			heliDestructible:SetEnabled(true);

			for a=1, 6 do
				local seatPart = newHeliModel:FindFirstChild(`Seat{a}`);
				if seatPart == nil then continue end;

				local spawnFunc = function(spawnCf, bindSetupHook) 
					return shared.modNpcs.spawn2{
						Name = "Bandit";
						CFrame = spawnCf;
						Properties = {
							IsOnVehicle = true;
							IsHostile = true;
							OpponentsThreshold = math.random(1, 3);
						};
						BindSetup = bindSetupHook;
					};
				end
				if typeof(params.CustomNpcSpawn) == "function" then
					spawnFunc = params.CustomNpcSpawn;
				end

				spawnFunc(seatPart.CFrame, function(npcClass: NpcClass)
					if npcClass == nil then return end;

					npcClass.Properties.IsOnVehicle = true;
					npcClass.RootPart.Anchored = true;
					
					npcClass.Properties.Seat = seatPart;
					npcClass.RootPart.Massless = true;
					npcClass.Humanoid.PlatformStand = true;

					local function leaveHeli()
						npcClass:Sit(nil);
						npcClass.Properties.Seat = nil;
						
						local exitPos = dropOriginAtt[math.random(1, #dropOriginAtt)].WorldPosition;
						npcClass.Move:MoveTo(exitPos);

						npcClass.Properties.IsOnVehicle = nil;
					end

					tweenB.Completed:Connect(function()
						task.wait(math.random(10,100)/100);
						leaveHeli();
					end)
					heliHealthComp.OnIsDeadChanged:Connect(function(isDead)
						if not isDead then return end;
						leaveHeli();
					end)
				end);
			end


			local pilotProperties = typeof(params.PilotProperties) == "table" and params.PilotProperties or {};
			pilotProperties.IsOnVehicle = true;

			local pilotSeat = newHeliModel:WaitForChild("PSeat1");
			bindNpcSpawnCallback(shared.modNpcs.spawn2{
				Name = "Bandit Pilot";
				CFrame = pilotSeat.CFrame;
				PackageOverride = "Bandit";
				Properties = pilotProperties;
				BindSetup = function(npcClass: NpcClass)
					npcClass.RootPart.Anchored = true;
					
                    npcClass.Properties.Seat = pilotSeat;
					npcClass.RootPart.Massless = true;
					npcClass.Humanoid.PlatformStand = true;

					npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
						if not isDead then return end;
						if not workspace:IsAncestorOf(newHeliModel) then return end;

						heliSpinOut = tick();
						heliDestructible.HealthComp:TakeDamage(DamageData.new{
                            Damage = heliDestructible.HealthComp.MaxHealth * 0.8;
                            DamageType = "IgnoreArmor";
                        })
					end)

					newHeliModel.Destroying:Connect(function()
						npcClass:Destroy();
					end)
				end;
			});

			tweenB:Play();
		end)

		tweenC.Completed:Connect(function()
			if heliHealthComp.IsDead then return end;
			newHeliModel:Destroy();

			if typeof(params.CompleteCallback) == "function" then
				task.spawn(params.CompleteCallback);
			end
		end)

		local tweenBDone = false;
		tweenB.Completed:Connect(function()
			if tweenBDone then return end;
			tweenBDone = true;

			if heliHealthComp.IsDead then return end;

			setHeliCanCollide(true);
			task.wait(0.5);
			openDoorsAnimation:Play();

			task.wait(10);
			openDoorsAnimation:Stop();
			task.wait(1);
			setHeliCanCollide(false);

			tweenC:Play();
		end)

		tweenA:Play();
	end)
	
	return CutsceneSequence;
end;

return cutscenePackage;