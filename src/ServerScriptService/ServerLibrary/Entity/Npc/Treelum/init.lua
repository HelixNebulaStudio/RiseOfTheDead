local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local CollectionService = game:GetService("CollectionService");

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modExperience = require(game.ServerScriptService.ServerLibrary.Experience);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		PathAgent = {AgentRadius=20; AgentHeight=32;};
		
		Properties = {
			WalkSpeed = {Min=16; Max=20};
			AttackSpeed = 4;
			AttackDamage = 50;
			AttackRange = 20;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=1500; Max=1700};
			ExperiencePool=1000;
		};
		DespawnPrefab = 30;
	};
	
	--== Initialize;
	self:SetClientScript(script:WaitForChild("TreelumEffect"));
	
	function self.Initialize()
		self.Prefab:SetAttribute("EntityHudHealth", true);

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
		
		repeat until not self.Update();
		wait(5);
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
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		if self.Enemy ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			self.Follow(targetRootPart, 5);
			local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
			if targetPlayer then
				--self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
				--if self.Enemy.Distance < self.Properties.AttackRange then
				--	self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
				--end
				--if self.Enemy.Distance < 25 then
				--	modAudio.Play("ZombieAttack"..random:NextInteger(1, 3), self.RootPart).Volume = 2;
				--	self.Logic:Action("Throw", targetHumanoid);
				--	self.Follow();
				--	wait(random:NextNumber(2, 4));
				--end
				--if self.Enemy and self.Enemy.Distance > 50 and self.Properties.Speed and self.Properties.Speed > 5 then
				--	self.Logic:Action("Leap", targetRootPart);
				--end
				
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
	
return self end
