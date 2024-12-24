local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local ZombieModule = script.Parent.Zombie;
--== Modules
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modWorldClipsHandler = require(game.ReplicatedStorage.Library.WorldClipsHandler);

local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);


-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		PathAgent = {AgentRadius=5; AgentHeight=8;};
		
		Properties = {
			WalkSpeed = {Min=20; Max=22};
			AttackSpeed = 4;
			AttackDamage = 50;
			AttackRange = 16;
			
			TargetableDistance=300;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=1500; Max=1700};
			ExperiencePool=1000;
			CrateId="wintertreelum";
		};
		
		KnockbackResistant = 1;
		DespawnPrefab = 30;
	};
	
	--== Initialize;
	self:SetClientScript(script:WaitForChild("TreelumEffect"));
	
	function self.Initialize()
		self.Prefab:SetAttribute("EntityHudHealth", true);

		modWorldClipsHandler:LoadClipId("BarbClips");
		modAudio.Play("TreelumGrowl", self.RootPart);
		
		local xmasParticles = self.Prefab:WaitForChild("LeavesCone"):WaitForChild("XmasParticles");
		xmasParticles.Enabled = true;
		xmasParticles:Emit(64);
		
		--self.CustomHealthbar:Create("Left Arm", 15000, self.Prefab:WaitForChild("LeftArm"));
		
		function self.CustomHealthbar:OnDamaged(amount, fromPlayer, storageItem, bodyPart)
			if bodyPart == nil then return end;
			--if bodyPart.Name == "LeftHand" or bodyPart.Name == "LeftArm" or bodyPart.Name == "LeftShoulder" then
			--	self:TakeDamage("Left Arm", amount);
			--end
		end
		
		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			--if name == "Left Arm" then
			--	self.Prefab.LeftArm.Color = Color3.fromRGB(50, 50, 50);
			--end
		end)
		
		if game:GetService("RunService"):IsStudio() then
			self.Humanoid.MaxHealth = 500;
			self.Humanoid.Health = self.Humanoid.MaxHealth;
		end
		
		function self:DropReward()
			if self.CrateReward then
				local dropRayHit, dropRayPos = workspace:FindPartOnRayWithWhitelist(Ray.new(self.DeathPosition, Vector3.new(0, -64, 0)), {workspace.Environment; workspace.Terrain}, true);
				local spawnCFrame = CFrame.new(dropRayPos) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);

				local cratePrefab, crateInteractable = self:CrateReward(spawnCFrame, game.Players:GetPlayers());
				Debugger.Expire(cratePrefab, 180);
			end
		end
		
		repeat until not self.Update();

		shared.Notify(game.Players:GetPlayers(), "A Winter Treelum has been defeated!", "BossDefeat");
		Debugger:Log("Dead");
		task.wait(2);
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("CustomHealthbar");
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Logic");
	self:AddComponent("CrateReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.Throw);
	self:AddComponent(ZombieModule.Leap);
	self:AddComponent(ZombieModule.BasicAttack1);
	self:AddComponent(ZombieModule.LevelVisuals);
	
	--== NPC Logic;
	self.SpikeTimerCooldown = tick();
	self.RootsCooldown = tick();
	self.Movement.DefaultJumpPower = 75;
	self.RootsSpawns = {};
	self.RootsDebris = {};
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		if self.LastDamageTaken and tick()-self.LastDamageTaken >= 300 then
			game.Debris:AddItem(self.Prefab, 0);
			self:Destroy();
		end
		
		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		if self.Enemy ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			self.Follow(targetRootPart, 5);
			
			local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
			if targetPlayer then
				self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
				
				if tick()-self.RootsCooldown >= 10 then
					self.RootsCooldown = tick();
					Debugger:Log("Roots");
					
					self.RootsSpawns = {};
					local traceTime = 5;
					
					for a=1, #self.Enemies do
						local player = game.Players:GetPlayerFromCharacter(self.Enemies[a].Character);
						local humanoid = self.Enemies[a].Humanoid;
						local rootPart = self.Enemies[a].RootPart;

						if player and rootPart then
							task.spawn(function()
								local trackTimer = tick();
								local lastPosition = rootPart.Position;
								
								repeat
									if humanoid.FloorMaterial ~= Enum.Material.Air and humanoid.FloorMaterial ~= Enum.Material.Water then
										local distChange = (lastPosition- rootPart.Position).Magnitude;
										
										if distChange >= 6 then
											local dropRayHit, dropRayPos = workspace:FindPartOnRayWithWhitelist(
												Ray.new(rootPart.Position, Vector3.new(0, -64, 0)), 
												{workspace.Environment; workspace.Terrain}, true);

											lastPosition = rootPart.Position;
											
											table.insert(self.RootsSpawns, dropRayPos);
										end
									end
									
									task.wait(0.5);
									if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
								until tick()-trackTimer >= traceTime;
							end)
						end
					end

					task.wait(traceTime);
					if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
					
					
					self.Follow();
					self.Humanoid:MoveTo(self.RootPart.Position);
					
					self.PlayAnimation("Shake");
					
					Debugger:Log("self.RootsSpawns", self.RootsSpawns);
					for a=1, #self.RootsSpawns do
						local spawnPosition = self.RootsSpawns[a];
						
						local newRoot = script.SpikeRoots:Clone();
						newRoot.CFrame = CFrame.new(spawnPosition) * CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
						task.spawn(function()
							for a=1, 3 do
								task.wait(0.05);
								newRoot.CFrame = CFrame.new(spawnPosition) * CFrame.new(0, 0.5*a, 0) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
							end
						end)
						newRoot.Parent = workspace.Entities;
						table.insert(self.RootsDebris, newRoot);
						game.Debris:AddItem(newRoot, 30);

						modAudio.Play("ShovelDig", newRoot).PlaybackSpeed = 6;

						local touchHandler = modTouchHandler.get("BarbClips")
						if touchHandler then
							touchHandler:AddObject(newRoot);
						end
						
						task.wait(0.25);
					end
					
					self.StopAnimation("Shake");
					task.wait(1);
				end
				
				if tick()-self.SpikeTimerCooldown >= 14 then
					self.SpikeTimerCooldown = tick();
					Debugger:Log("Spiking time");

					self.Follow();
					self.Humanoid:MoveTo(self.RootPart.Position);
					
					for a=1, 3 do
						task.wait(1);
						self.Humanoid.Jump = true;
						task.wait(0.5);
						modAudio.Play("HeavyThump", self.RootPart).PlaybackSpeed = 0.8;
						task.wait(0.1);
					end
					
					for a=1, #self.Enemies do
						local player = game.Players:GetPlayerFromCharacter(self.Enemies[a].Character);
						local rootPart = self.Enemies[a].RootPart;

						if player and rootPart then
							
							task.spawn(function()
								local spawnPoint = rootPart.CFrame * CFrame.new(0, -3, 0) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
								
								local newSpike = script.Spike:Clone();
								
								newSpike:PivotTo(spawnPoint);
								
								newSpike.Parent = workspace.Environment;
								
								local spikePart = newSpike:WaitForChild("Spike");

								modAudio.Play("ShovelDig", spikePart).PlaybackSpeed = 1.6;
								task.wait(0.05);
								
								local touchedPlayer = {};
								local touchConn;
								touchConn = spikePart.Touched:Connect(function(hitPart)
									local player = game.Players:GetPlayerFromCharacter(hitPart and hitPart.Parent);
									
									if player and touchedPlayer[player] == nil then
										touchedPlayer[player] = true;
										self.Throw(player.Character, 100, 20);
									end
								end)

								remoteCameraShakeAndZoom:FireClient(player, 10, 5, 1, 0.01, true);
								TweenService:Create(spikePart, TweenInfo.new(0.3), {
									Size=Vector3.new(14, 28, 14);
									CFrame=spawnPoint * CFrame.new(0, 14, 0);
								}):Play();
								
								task.wait(0.26);
								touchConn:Disconnect();
								table.clear(touchedPlayer);

								table.insert(self.RootsDebris, newSpike);
								game.Debris:AddItem(newSpike, 20);
							end)
						end
					end

				end
				
				
				if self.Enemy.Distance < self.Properties.AttackRange then
					self.Throw(targetHumanoid.Parent, 150, 30);
					
				end
				
			end
		else
			self.Follow();
			
		end
		
		self.NextTarget();
		self.Logic:Wait(1);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
	self.Garbage:Tag(function()
		for _, obj in pairs(self.RootsDebris) do
			game.Debris:AddItem(obj, 0);
		end
	end)
	
return self end
