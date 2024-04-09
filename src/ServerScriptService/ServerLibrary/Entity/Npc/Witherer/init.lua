local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local ZombieModule = script.Parent.Zombie;
--== Modules Warn: Don't require(Npc)

local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local modRaycastUtil = require(game.ReplicatedStorage.Library.Util.RaycastUtil);

local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local withererEye = script:WaitForChild("withererEye");
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		
		Properties = {
			BasicEnemy = true;
			WalkSpeed = {Min=5; Max=5};
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=100; Max=200};
			ExperiencePool=30;
			ResourceDrop=modRewardsLibrary:Find("zombie");
		};
	};
	
	local rayParam = RaycastParams.new();
	rayParam.FilterType = Enum.RaycastFilterType.Include;
	rayParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
	rayParam.IgnoreWater = true;
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.MaxHealth = math.max(1024 + 1024*(self.Configuration.Level-1), 1024);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.EyePrefab = withererEye:Clone();
		local eye = self.EyePrefab;
		
		local eyeBase = eye:WaitForChild("base");
		local eyeBall = eye:WaitForChild("eyeball");
		local eyeAtt = eyeBase:WaitForChild("eyeAttachment");
		local defaultEyeCf = eyeAtt.CFrame;
		
		local eyeVisible = true;
		function self.CustomHealthbar:OnDamaged(amount, fromPlayer: Player, storageItem, bodyPart)
			if bodyPart == nil then return end;

			if bodyPart.Name == "eyeball" then
				if not eyeVisible then
					return {
						Amount=0;
						Immunity=1;
					};
				end
				
				if fromPlayer and fromPlayer:DistanceFromCharacter(eyeBase.Position) > 64 then
					return {
						Amount=0;
						Immunity=1;
					}
				end
				
				self:HideGui("Eyeball");
				eyeVisible = false;
				eyeAtt.CFrame = CFrame.identity;
				task.delay(math.random(70, 110)/10, function()
					eyeAtt.CFrame = defaultEyeCf;
					eyeVisible = true;
					self:ShowGui("Eyeball");
				end)
				
				self:TakeDamage("Eyeball", amount);
			end
		end
		
		self.CustomHealthbar:Create("Eyeball", self.Humanoid.MaxHealth, eyeBall);
		self.CustomHealthbar:SetGuiSize("Eyeball", 4, 1);
		self.CustomHealthbar:SetGuiDistance("Eyeball", 64);
		self.CustomHealthbar:ShowGui("Eyeball");

		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			if name == "Eyeball" then
				game.Debris:AddItem(eyeBall, 0);
			end
		end)
		
		local scanDist = 64;
		local scanPoints = 3;
		local spawnSuccess = false;
		
		for a=1, 10 do
			local dirCf = CFrame.lookAt(Vector3.zero, Vector3.yAxis, Vector3.yAxis);
			dirCf = dirCf*CFrame.Angles(0, 0, math.rad(math.random(0, 360))); -- roll cframe
			local gr = modGlobalVars.GaussianRandom()/2.5;
			dirCf = dirCf*CFrame.Angles(math.rad(80*gr), 0, 0); --pitch cframe;

			local dir = dirCf.LookVector;
			local orign = self.RootPart.Position;

			local scanDir = dir*scanDist;
			local rayResult = workspace:Raycast(orign, scanDir, rayParam);

			if rayResult then
				local normal = rayResult.Normal;
				local point = rayResult.Position;

				local pointCf = CFrame.lookAt(point, point + normal) * CFrame.Angles(math.rad(-90), 0, 0);
				local origin = point + (normal*0.1);

				local rayResultList = modRaycastUtil.ConeCast{
					Origin=origin;
					Dir=-normal;
					Points=scanPoints;
					Radius=4;
					RayParam=rayParam;
					OnEachRay=function(origin, dir, rayResult)
						if rayResult == nil then
							return true;
						end;

						local expectedPos = origin + dir;
						local pos = rayResult.Position;
						
						local maxDif = modGlobalVars.MaxDiff({pos.X, expectedPos.X}, {pos.Y, expectedPos.Y}, {pos.Z, expectedPos.Z});
						if maxDif > 1 then
							return true;
						end
					end;
				};


				if #rayResultList >= scanPoints then
					eye:PivotTo(pointCf);
					eye.Parent = self.Prefab;
					spawnSuccess = true;
					break;

				else
					Debugger:Warn("Search spawnpoint failed", #rayResultList);

				end

			else
				Debugger:Warn("Search spawnpoint failed", rayResult);

			end
			task.wait(0.33);
		end
		
		if spawnSuccess then
			eyeBall:AddTag("Witherer");
			repeat until not self.Update();
			eyeBall:RemoveTag("Witherer");
		end
		
		Debugger:Warn("Died");
		game.Debris:AddItem(eye, 0);
		
	end
	
	--== Components;
	self:AddComponent("CustomHealthbar");
	self:AddComponent("DropReward");
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		wait(2);
		
		if workspace.Entity:IsAncestorOf(self.EyePrefab) then
			local origin = self.EyePrefab:GetPivot();
			
			local overlapParam = OverlapParams.new();
			overlapParam.MaxParts = 8;
			overlapParam.FilterType = Enum.RaycastFilterType.Include;
			overlapParam.FilterDescendantsInstances = CollectionService:GetTagged("PlayerRootParts");

			local playerRootParts = workspace:GetPartBoundsInRadius(origin.Position, 64, overlapParam);
			for a=1, #playerRootParts do
				local player = game.Players:FindFirstChild(playerRootParts[a].Parent.Name);
				if player == nil then continue end
				
				modStatusEffects.Withering(player, 30);
			end
		end
		
		return true;
	end
	
	--== Connections;
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
return self end
