local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local CollectionService = game:GetService("CollectionService");

local RatModule = script;
local EnemyModule = script.Parent.Enemy;
local HumanModule = script.Parent.Human;
--== Modules
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

local fireCooldown = tick();
modOnGameEvents:ConnectEvent("OnTouchEvent", function(touchEventId, hitPart)
	if tick() <= fireCooldown+0.5 then return end;
	fireCooldown = tick();

	local model = hitPart.Parent;
	if not model:IsA("Model") then return end;

	local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	
	local playerDamageable = modDamagable.NewDamagable(model);
	if playerDamageable then
		local classPlayer = playerDamageable.Object;
		if classPlayer.ClassName == "PlayerClass" and classPlayer.Humanoid.Health > 0 then
			local player = classPlayer:GetInstance();
			
			local missionCache = modEvents:GetEvent(player, "MissionCache");
			local isEnemy = false;
			if missionCache and missionCache.Value then
				if missionCache.Value.BanditsAllied == true then
					isEnemy = true;
				end
				if missionCache.Value.RatsAllied == true then
					isEnemy = false;
				end
			end
			local missionChoice = modEvents:GetEvent(player, "mission58choice");
			if missionChoice and missionChoice.Rats == true then
				isEnemy = false;
			end
			
			if not isEnemy then return end;
			
			
			local rats = CollectionService:GetTagged("Rats");
			for a=1, #rats do
				local ratNpcModule = modNpc.GetNpcModule(rats[a]);
				
				if ratNpcModule.Enemies and playerDamageable:CanDamage(ratNpcModule) then
					local exist = false;
					for b=1, #ratNpcModule.Enemies do
						if ratNpcModule.Enemies[b].Character == model then
							exist = true;
							break;
						end
					end

					if not exist then
						ratNpcModule.OnTarget(model);
					end
				end
			end
		end
	end
end)

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Rat");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		Smart = true;
		
		Properties = {
			BasicEnemy=true;
			Hostile=false;
			WalkSpeed={Min=8; Max=20};
			AttackSpeed=2;
			AttackRange={Min=16; Max=32};
			TargetableDistance=50;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=40;
			Audio={Hurt=false;};
			ResourceDrop=modRewardsLibrary:Find("bandit");
		};
	};
	
	self.Speeches = {"";}
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.MaxHealth = 400 + 200*(self.Configuration.Level-1);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		if self.Properties.AttackDamage == nil then
			self.Properties.AttackDamage = math.clamp(200 + 50*(self.Configuration.Level-1), 200, 600);
		end
		
		self.RandomSkin();
		self.Properties.AttackCooldown = tick();
		self.Properties.FeelsSafe = tick();
		self.Properties.AttractCooldown = tick();
		
		local weaponChoices = {"m4a4";};
		
		if self.Properties.WeaponId == nil then
			self.Properties.WeaponId = weaponChoices[random:NextInteger(1, #weaponChoices)];
		end
		
		if self.Wield.Targetable.Humanoid == nil then
			self.Wield.Targetable.Humanoid = 0.01;
		end
		self.Wield.Targetable.Bandit = 0.1;
		
		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent("IsInVision");
	self:AddComponent("DropReward");
	self:AddComponent("Wield");
	
	self:AddComponent(HumanModule.AttractZombies);
	self:AddComponent(HumanModule.Chat);
	
	self:AddComponent(EnemyModule.OnHealthChanged);
	self:AddComponent(EnemyModule.OnDeath);
	self:AddComponent(EnemyModule.OnDamaged);
	self:AddComponent(RatModule.OnTarget);
	
	self:AddComponent(RatModule.RandomSkin);
	self:AddComponent(RatModule.Idle);
	
	--== NPC Logic;
	self.Logic:AddAction("Idle", self.Idle.Begin, self.Idle.Cancel);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false end;
		if self.Disabled then wait(0.1) return true end;
		
		local followGap = random:NextNumber(self.Properties.AttackRange.Min, self.Properties.AttackRange.Max);
		
		if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.Health > 0 then
			self.Logic:SetState("Aggro");
			
			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Max, self.Properties.WalkSpeed.Max+5);
			self.Follow(self.Enemy.Humanoid.RootPart, followGap, 10);
			
			if self.Enemy.Distance <= (self.Properties.TargetableDistance or 50) then
				if self.Wield.ToolModule == nil then
					self.Wield.Equip(self.Properties.WeaponId);
					pcall(function()
						self.Wield.ToolModule.Configurations.MinBaseDamage = self.Properties.AttackDamage;
					end);
				end
					
				self.Wield:ToggleIdle(false);
				
				repeat
					local follow = true;
					if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.RootPart and self.Enemy.Humanoid.Health > 0 then
						self.NextTarget();
						
						if self.Wield.ToolModule and not self.Wield.ToolModule.Properties.Reloading 
						and self.Enemy and self.IsInVision(self.Enemy.Humanoid.RootPart) then
							if self.Enemy.NpcModule and self.Enemy.NpcModule.UpdateDropReward then self.Enemy.NpcModule:UpdateDropReward(); end
							self.Wield.SetEnemyHumanoid(self.Enemy.Humanoid);
							self.Movement:Face(self.Enemy.Humanoid.RootPart.Position);
							self.Wield.PrimaryFireRequest();
							
							if self.Enemy.Distance > 12 then
								self.Follow();
								follow = false;
							end
						end
					else
						self.Enemy = nil;
					end
					
					if follow and self.Enemy then self.Follow(self.Enemy.Humanoid.RootPart, followGap, 10); end
					self.Logic:Timeout("Aggro", 0.1);
				until self.IsDead or self.Enemy == nil or self.Enemy.Distance >= (self.Properties.TargetableDistance or 50);
				
				self.Properties.FeelsSafe = tick();
				self.Wield:ToggleIdle();
				
			else
				if self.Wield.ToolModule then
					self.Wield.ReloadRequest();
				end
			end
			
			self.Logic:Timeout("Aggro", 1);
			
		else
			self.Logic:SetState("Idle");
			self.Wield:ToggleIdle();
			
			if tick()-self.Properties.FeelsSafe >= 30 then
				self.Wield.Unequip();
			end
			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Min, self.Properties.WalkSpeed.Min+5);
			self.Follow();
			self.Logic:Action("Idle");
			
		end

		self.Logic:Timeout("Idle", 10);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
return self end
