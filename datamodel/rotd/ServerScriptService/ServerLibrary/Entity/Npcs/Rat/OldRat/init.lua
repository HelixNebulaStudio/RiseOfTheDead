local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local CollectionService = game:GetService("CollectionService");

local RatModule = script;
local EnemyModule = script.Parent.Enemy;
local HumanModule = script.Parent.Human;
--== Modules
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modNpcComponent = shared.require(game.ServerScriptService.ServerLibrary.Entity.NpcClass);

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);

local fireCooldown = tick();
modOnGameEvents:ConnectEvent("OnTouchEvent", function(touchEventId, hitPart)
	if tick() <= fireCooldown+0.5 then return end;
	fireCooldown = tick();

	local model = hitPart.Parent;
	if not model:IsA("Model") then return end;

	local modNpcs = shared.modNpcs
	
	local player = game.Players:GetPlayerFromCharacter(model);
	if player then
		local playerClass = shared.modPlayers.get(player);
		if playerClass and playerClass.HealthComp and playerClass.HealthComp.CurHealth > 0 then
			
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
				local ratNpcModule = modNpcs.getByModel(rats[a]);
				
				if ratNpcModule.Enemies then
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
		
		-- Targetable configuration removed - not part of WieldComp
		
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
				if self.WieldComp.ToolHandler == nil then
					self.WieldComp:Equip{
						ItemId = self.Properties.WeaponId;
					};
				end
					
				self.WieldComp:InvokeToolAction("ToggleIdle", false);
				
				repeat
					local follow = true;
					if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.RootPart and self.Enemy.Humanoid.Health > 0 then
						self.NextTarget();
						
						if self.WieldComp.ToolHandler and self.Enemy and self.IsInVision(self.Enemy.Humanoid.RootPart) then
							if self.Enemy.NpcModule and self.Enemy.NpcModule.UpdateDropReward then self.Enemy.NpcModule:UpdateDropReward(); end
							self.Movement:Face(self.Enemy.Humanoid.RootPart.Position);
							self.WieldComp:InvokeToolAction("PrimaryFireRequest");
							
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
				self.WieldComp:InvokeToolAction("ToggleIdle", true);
				
			else
				if self.WieldComp.ToolHandler then
					self.WieldComp:InvokeToolAction("ReloadRequest");
				end
			end
			
			self.Logic:Timeout("Aggro", 1);
			
		else
			self.Logic:SetState("Idle");
			self.WieldComp:InvokeToolAction("ToggleIdle", true);
			
			if tick()-self.Properties.FeelsSafe >= 30 then
				self.WieldComp:Unequip();
			end
			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Min, self.Properties.WalkSpeed.Min+5);
			self.Follow();
			self.Logic:Action("Idle");
			
		end

		self.Logic:Timeout("Idle", 10);
		return true;
	end
	
	
return self end
