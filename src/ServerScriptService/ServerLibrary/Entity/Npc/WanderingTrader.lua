local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Immortal = 1;
		WanderingTrader=true;
	};
	
	--== Initialize;
	function self.Initialize()
		repeat until not self.Update();
	end
	
	function self.Update()
		if self.IsDead then return false; end;
		
		self.BehaviorTree:RunTree("WandererTree", true);
		
		if self.BehaviorTree.State == "Travel" and self.CurrentNav == nil then
			
			if math.random(1, 5) == 1 and self.HuntKillCount > self.KillRequirement then
				self.HuntKillCount = 0;
			end
			
			local scanlist = self.NpcService.EntityScan(self.RootPart.Position, 32, 5);
			local targetPrefabs = {};
			for a=1, #scanlist do
				if scanlist[a].Humanoid and scanlist[a].Humanoid.Name == "Zombie" then
					table.insert(targetPrefabs, scanlist[a].Prefab);
				end
			end
			
			if #targetPrefabs > 0 and self.HuntKillCount <= self.KillRequirement then
				
				if self.Wield.ToolModule == nil then
					self.Wield.Equip("mariner590");
				end
				
				local target = table.remove(targetPrefabs, 1);
				repeat
					if target then
						local enemyHumanoid = target:FindFirstChildWhichIsA("Humanoid");
						if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.RootPart then
							pcall(function()
								self.Wield.ToolModule.Configurations.MinBaseDamage = math.max(enemyHumanoid.MaxHealth * 0.1, 50);
								
								if target.Name == "Winter Treelum" then
									self.Wield.ToolModule.Configurations.MinBaseDamage = 10000;
								end
							end);
							
							if self.IsInVision(enemyHumanoid.RootPart) then
								self.Movement:Follow(enemyHumanoid.RootPart.Position);
								
								self.Wield.SetEnemyHumanoid(enemyHumanoid);
								self.Movement:Face(enemyHumanoid.RootPart.Position);
								self.Wield.PrimaryFireRequest();
							else
								target = nil;
							end
						else
							self.HuntKillCount = self.HuntKillCount +1;
							
							target = nil;
						end
					else
						self.Wield.ReloadRequest();
						target = table.remove(targetPrefabs, 1);
					end
					task.wait(0.1);
					if #targetPrefabs <= 0 and target == nil then break; end;
				until self.IsDead;
				
			end
		end
		
		task.wait(0.5);
		return true;
	end
	
	--== Components;
	self:AddComponent("ObjectScan");
	self:AddComponent("AvatarFace");
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent("BehaviorTree");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	
	--== Connections;
	self.Garbage:Tag(self.BindOnTalkedTo.Event:Connect(function(prefab, target, choice)
		if prefab == self.Prefab and self.IsTalking == nil then
			self.IsTalking = target.Character.PrimaryPart;
			
			local rootPart = self.IsTalking;
			if rootPart then
				self.Movement:Face(rootPart.Position);
			end
			
			repeat
				if self.Movement.IsMoving then self.Movement:Pause(3); end;
				task.wait(2);
			until self.IsDead or target:DistanceFromCharacter(self.RootPart.Position) > 15;
			
			self.IsTalking = nil;
		end
	end));
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
return self end
