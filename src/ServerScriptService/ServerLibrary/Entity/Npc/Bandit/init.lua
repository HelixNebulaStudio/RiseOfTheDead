local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local BanditModule = script;
local EnemyModule = script.Parent.Enemy;
local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Bandit");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		Smart = true;
		
		Properties = {
			BasicEnemy=true;
			Hostile=false;
			WalkSpeed={Min=8; Max=20};
			AttackSpeed=2;
			AttackRange={Min=36; Max=64};
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
	
	self.Speeches = {
		"Back off, zombies!";
		"Can't catch me, losers!";
		"Brain check, uh oooh, brain dead!";
		"Who wants a piece of this?!";
		"Another one bites the dust!";
		"You better be worthy of my bullet!";
		"Look ma, no hands! Literally!";
		"Slice and dice ya!";
		"..and stay dead!";
	}
	
	--== Initialize;
	function self.OnAttracted(character)
		local player = game.Players:GetPlayerFromCharacter(character);
		if player then
			local missionChoice = modEvents:GetEvent(player, "mission58choice");
			if missionChoice and missionChoice.Rats == true and missionChoice.Bandits ~= true then
				return true;
			end
			
			--local missionCache = modEvents:GetEvent(player, "MissionCache");
			--if missionCache and missionCache.Value and missionCache.Value.BanditsAllied ~= true then
			--	return true;
			--end
		end
		
		return self.Properties.Hostile ~= false;
	end
	
	function self.Initialize()
		self.Humanoid.MaxHealth = 400 + 200*(self.Configuration.Level-1);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		if self.Properties.AttackDamage == nil then
			self.Properties.AttackDamage = math.clamp(200 + 60*(self.Configuration.Level-1), 250, 800);
		end
		
		self.RandomSkin();
		self.Properties.AttackCooldown = tick();
		self.Properties.FeelsSafe = tick();
		self.Properties.AttractCooldown = tick();
		
		local weaponChoices = {"tec9"; "xm1014";};
		if self.Configuration.Level > 5 then
			table.insert(weaponChoices, "ak47");
			
		elseif self.Configuration.Level > 10 then
			table.insert(weaponChoices, "dualp250");
			
		elseif self.Configuration.Level > 20 then
			table.insert(weaponChoices, "fnfal");
			
		end
		if self.Properties.WeaponId == nil then
			self.Properties.WeaponId = weaponChoices[random:NextInteger(1, #weaponChoices)];
		end
		
		if self.Wield.Targetable.Humanoid == nil then
			self.Wield.Targetable.Humanoid = 0.01;
		end
		self.Wield.Targetable.Rat = 0.1;
		
		task.delay(0.5,function()
			while self.DeploySeat do
				self.RootPart:SetNetworkOwner(nil);
				self.DeploySeat:Sit(self.Humanoid);
				task.wait(0.1);
			end
			self:AddComponent("AntiSit");
		end)

		if game:GetService("RunService"):IsStudio() then
			self.BaseArmor = 100;
			self:AddComponent("ArmorSystem");

			local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);
			local banditarmorLib = modClothingLibrary:Find("banditarmor");
			for _, accessory in pairs(banditarmorLib.Accessories) do
				local newAccessory: Accessory = accessory:Clone();

				self.ArmorSystem.OnArmorChanged:Connect(function()
					if self.ArmorSystem.Armor > 0 then return end;
					local handle = newAccessory:FindFirstChildWhichIsA("BasePart");
					if handle then 
						local cf = handle.CFrame;
						handle.Parent = workspace.Debris;
						handle.CanCollide = true;
						handle.CFrame = cf;
					end;
					game.Debris:AddItem(handle, 10);
					newAccessory:Destroy();

				end)

				newAccessory.Parent = npc;
			end

		end

		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent("IsInVision");
	self:AddComponent("DropReward");
	self:AddComponent("Wield");
	
	self:AddComponent(HumanModule.AttractZombies);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Chatter);
	
	self:AddComponent(EnemyModule.OnHealthChanged);
	self:AddComponent(EnemyModule.OnDeath);
	self:AddComponent(EnemyModule.OnDamaged);
	self:AddComponent(BanditModule.OnTarget);
	
	self:AddComponent(BanditModule.RandomSkin);
	self:AddComponent(BanditModule.Idle);
	
	--== NPC Logic;
	self.Logic:AddAction("Idle", self.Idle.Begin, self.Idle.Cancel);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false end;
		if self.Disabled then wait(0.1); return true end;
		
		local maxFollowDist = random:NextNumber(self.Properties.AttackRange.Min, self.Properties.AttackRange.Max);
		
		if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.Health > 0 then
			self.Logic:SetState("Aggro");
			
			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Max, self.Properties.WalkSpeed.Max+5);
			self.Move:Follow(self.Enemy.Humanoid.RootPart, maxFollowDist, 16);
			
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
						
						local targetIsInVision = self.Enemy and self.IsInVision(self.Enemy.Humanoid.RootPart);
						if self.Wield.ToolModule and not self.Wield.ToolModule.Properties.Reloading and targetIsInVision then
							if self.Enemy.NpcModule and self.Enemy.NpcModule.UpdateDropReward then self.Enemy.NpcModule:UpdateDropReward(); end
							
							self.Wield.SetEnemyHumanoid(self.Enemy.Humanoid);
							self.Move:HeadTrack(self.Enemy.Humanoid.RootPart, 1);
							self.Move:Face(self.Enemy.Humanoid.RootPart, 64);
							
							self.LostVisionOfTargetTick = nil;
							self.Wield.PrimaryFireRequest();
							
							if self.Enemy.Distance > 12 then
								self.Move:Stop();
								follow = false;
							end
							
						else
							if self.LostVisionOfTargetTick == nil then
								self.LostVisionOfTargetTick = tick();
							end
							
							if self.Wield.ToolModule and tick()-self.LostVisionOfTargetTick >= math.random(20,30)/10 then
								self.Wield.Controls.Mouse1Down = false;
							end
							
						end
					else
						self.Enemy = nil;
					end
					
					if follow and self.Enemy then
						self.Move:Follow(self.Enemy.Humanoid.RootPart, maxFollowDist, 16);
					end
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
			self.Wield:ToggleIdle();
			self.Logic:SetState("Idle");
			
			if tick()-self.Properties.FeelsSafe >= 30 then
				self.Wield.Unequip();
			end
			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Min, self.Properties.WalkSpeed.Min+5);
			self.Move:Stop();
			self.Logic:Action("Idle");
			
		end

		self.Logic:Timeout("Idle", 10);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
return self end
