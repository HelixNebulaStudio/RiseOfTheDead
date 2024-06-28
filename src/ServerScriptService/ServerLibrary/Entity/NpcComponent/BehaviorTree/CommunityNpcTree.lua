local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

return function(self)
	local tree = modLogicTree.new{
	    DangerSelect={"Or"; "WakeUpSequence"; "ExitSafehomeSequence"; "KillEnemies";};
	    DaySafehomeSelect={"Or"; "WakeUpSequence"; "HeliAttackHomeSequence"; "ExitSafehome";};
	    DayOutsideSelect={"Or"; "HeliAttackSequence"; "NpcTalkSequence"; "RoamOutside";};
	    WakeUpSequence={"And"; "IsSleeping"; "WakeUp";};
	    DayInSafehomeSequence={"And"; "InSafehome"; "SleepSelect";};
	    HeliAttackSequence={"And"; "IsHeliAttack"; "EnterSafehome";};
	    AlertSequence={"And"; "DangerInSafehouse"; "NotIsHeliAttack"; "DangerSelect";};
	    SafeSelect={"Or"; "NightSequence"; "DaySelect";};
	    SleepSelect={"Or"; "SleepSequence"; "WakeSelect";};
	    NpcTalkSequence={"And"; "CanChat"; "NpcTalk";};
	    NightSequence={"And"; "IsNight"; "NightSelect";};
	    Root={"Or"; "AlertSequence"; "SafeSelect";};
	    NightSelect={"Or"; "DayInSafehomeSequence"; "EnterSafehome";};
	    NotIsHeliAttack={"Not"; "IsHeliAttack";};
	    HeliAttackHomeSequence={"And"; "IsHeliAttack"; "RoamSafehome";};
	    WakeSelect={"Or"; "WakeUpSequence"; "RoamSafehome";};
	    NightInSafehomeSequence={"And"; "InSafehome"; "DaySafehomeSelect";};
	    DaySelect={"Or"; "NightInSafehomeSequence"; "DayOutsideSelect";};
	    ExitSafehomeSequence={"And"; "InSafehome"; "ExitSafehome";};
	    SleepSequence={"And"; "IsSleepTime"; "WalkToSleep"; "Sleep";};
	}
	
	local cache = {
		RoamIdleTimer=nil;
		HuntIndex=nil;
		NpcToTalkTo=nil;
	};
	cache.InSafehome = false;
	cache.SafehomeRoamIndex = 1;
	cache.OutsideRoamIndex = 1;
	cache.SleepTimer = tick();
	cache.IsSleeping = false;
	cache.HuntTimer = tick();
	cache.ChatTimer = tick();
	cache.IsHeliAttack = false;
	cache.HeliChat = cache.IsHeliAttack;
	
	
	tree:Hook("IsNight", function()
		if not modSyncTime.IsDay then
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)
	
	
	tree:Hook("InSafehome", function()
		if cache.InSafehome then
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)
	
	
	tree:Hook("IsSleepTime", function()
		if game.Lighting.ClockTime > 0 and game.Lighting.ClockTime < 7 then
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)
	
	
	tree:Hook("WalkToSleep", function()
		if cache.IsSleeping then return modLogicTree.Status.Success; end;
		
		self.Movement:Move(self.BedLocation):OnComplete(function()
			cache.NextToSeat = true;
		end)
		
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("Sleep", function()
		if not cache.NextToSeat then return modLogicTree.Status.Success; end;
		if tick() > cache.SleepTimer then
			cache.SleepTimer = tick() + math.random(50, 80);
			self.Chat(game.Players:GetPlayers(), self.SnoozeTexts[math.random(1, #self.SnoozeTexts)]);
			
			self.AvatarFace:Set("Unconscious");
			self.BedSeat:Sit(self.Humanoid);
		end
		cache.IsSleeping = true;
		
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("IsSleeping", function()
		if cache.IsSleeping then
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)
	
	
	tree:Hook("WakeUp", function()
		self.AvatarFace:Set();
		self.Actions:Unsit();
		cache.NextToSeat = false;
		cache.IsSleeping = false;
		
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("RoamSafehome", function()
		self.Movement.DefaultWalkSpeed = 7;
		self.AvatarFace:Set();
		
		self.Movement:Move(self.RoamSafehome[cache.SafehomeRoamIndex]):OnComplete(function()
			if cache.RoamIdleTimer == nil then
				if cache.SafehomeRoamIndex ~= 3 then
					self.PlayAnimation("OpenStorage");
				end
				cache.RoamIdleTimer = tick() + math.random(10, 20);
				
			elseif tick() > cache.RoamIdleTimer then
				cache.RoamIdleTimer = nil;
				cache.SafehomeRoamIndex = math.random(1, #self.RoamSafehome);
				
			end
		end)
		
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("EnterSafehome", function()
		local doorInstance = workspace.Interactables:FindFirstChild(self.SafehouseDoorEnter);
		
		self.Movement:Move(doorInstance and doorInstance.Position or self.RootPart.Position):OnComplete(function()
			cache.InSafehome = true;
			self.Movement.DefaultWalkSpeed = 7;
			self.Actions:EnterDoor(self.SafehouseDoorEnter);
		end)
		
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("IsHeliAttack", function()
		if workspace.Entity:FindFirstChild("Bandit Pilot") then
			cache.IsHeliAttack = true;
			self.Movement.DefaultWalkSpeed = cache.InSafehome and 7 or 17;
			
			if cache.HeliChat ~= cache.IsHeliAttack then
				cache.HeliChat = cache.IsHeliAttack;
				self.Chat(game.Players:GetPlayers(), self.BanditMessages[math.random(1, #self.BanditMessages)]);
			end
			
			return modLogicTree.Status.Success;
		end
		
		cache.IsHeliAttack = false;
		if cache.HeliChat ~= cache.IsHeliAttack then
			cache.HeliChat = cache.IsHeliAttack;
			self.Chat(game.Players:GetPlayers(), self.GoneMessages[math.random(1, #self.GoneMessages)]);
		end
			
		return modLogicTree.Status.Failure;
	end)
	
	
	tree:Hook("ExitSafehome", function()
		local doorInstance = workspace.Interactables:FindFirstChild(self.SafehouseDoorExit);
		
		self.Movement:Move(doorInstance and doorInstance.Position or self.RootPart.Position):OnComplete(function()
			cache.InSafehome = false;
			self.Actions:EnterDoor(self.SafehouseDoorExit);
		end)
		
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("DangerInSafehouse", function()
		if #self.Enemies > 0 or tick() < cache.HuntTimer then
			self.Movement.DefaultWalkSpeed = 17;
			
			return modLogicTree.Status.Success;
		end
		
		self.Wield.Unequip();
		return modLogicTree.Status.Failure;
	end)
	
	
	tree:Hook("KillEnemies", function()
		if self.Wield.ToolModule == nil then
			self.Wield.Equip("m4a4");
			pcall(function()
				self.Wield.ToolModule.Configurations.MinBaseDamage = 50;
			end);
			
			self.AvatarFace:Set("Angry");
		end
		
		local target = self.Enemies[cache.HuntIndex or 1];
		
		local function updateTarget()
			if target then
				table.remove(self.Enemies, table.find(self.Enemies, target));
			end
			if #self.Enemies > 0 then
				cache.HuntIndex = math.random(1, #self.Enemies);
			end
		end
		
		if target then
			local enemyHumanoid = target:FindFirstChildWhichIsA("Humanoid");
			if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.RootPart then
				self.Movement:Follow(enemyHumanoid.RootPart.Position);
				
				if self.IsInVision(enemyHumanoid.RootPart) then
					self.Wield.SetEnemyHumanoid(enemyHumanoid);
					self.Movement:Face(enemyHumanoid.RootPart.Position);
					self.Wield.PrimaryFireRequest();
					
					cache.HuntTimer = tick() + (math.random(8,12)/10);
				else
					if #self.Enemies > 1 then
						updateTarget();
					end
				end
			else
				updateTarget();
			end
		else
			self.Wield.ReloadRequest();
			updateTarget();
		end
		
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("CanChat", function()
		if self.IsTalking then
			return modLogicTree.Status.Success;
			
		elseif cache.NpcToTalkTo then
			return modLogicTree.Status.Success;
			
		elseif tick() > cache.ChatTimer then
			local scanlist = self.NpcService.EntityScan(self.RootPart.Position, 32, 2);
			local talkableNpcs = {};
			
			for a=1, #scanlist do
				if scanlist[a].Name ~= self.Name and scanlist[a].NpcChat then
					table.insert(talkableNpcs, scanlist[a]);
				end
			end
			
			cache.NpcToTalkTo = #talkableNpcs > 0 and talkableNpcs[math.random(1, #talkableNpcs)] or nil;
			
			return modLogicTree.Status.Success;
		end
		
		return modLogicTree.Status.Failure;
	end)
	
	
	tree:Hook("NpcTalk", function()
		local otherNpcModule = cache.NpcToTalkTo;
		
		if self.IsTalking and self.IsTalking.Face and self.IsTalking.Reply then
			self.Movement:Face(self.IsTalking.Face);
			task.wait(1);
			self.Chat(game.Players:GetPlayers(), self.IsTalking.Reply);
			self.IsTalking = nil;
			
			cache.NpcToTalkTo = nil;
			cache.ChatTimer = tick() + math.random(30, 60);
			
			return modLogicTree.Status.Success;
			
		elseif otherNpcModule and self.NpcChat[otherNpcModule.Name] then
			if otherNpcModule.IsTalking == nil then
				local talkOptions = self.NpcChat[otherNpcModule.Name];
				
				self.Movement.DefaultWalkSpeed = 7;
				self.Movement:Follow(otherNpcModule.RootPart.Position, 8);
				
				local diff = self.RootPart.Position - otherNpcModule.RootPart.Position
				local distanceSq = diff.X^2 + diff.Y^2 + diff.Z^2;
				if distanceSq <= 80 then
					self.Movement:Face(otherNpcModule.RootPart.Position);
					
					if tick() > cache.ChatTimer then
						task.wait(1);
						cache.TalkIndex = math.random(1, #talkOptions); 
						
						self.Chat(game.Players:GetPlayers(), talkOptions[cache.TalkIndex][1]);
						otherNpcModule.IsTalking = {Face=self.RootPart.Position, Reply=talkOptions[cache.TalkIndex][2];};
						
						cache.NpcToTalkTo = nil;
						cache.ChatTimer = tick() + math.random(30, 60);
						
					end
				end
				
			else
				cache.NpcToTalkTo = nil;
				cache.ChatTimer = tick() + math.random(30, 60);
			end
			return modLogicTree.Status.Success;
		end
		
		return modLogicTree.Status.Failure;
	end)
	
	
	tree:Hook("RoamOutside", function()
		self.Movement.DefaultWalkSpeed = 7;
		self.AvatarFace:Set();
		
		self.Movement:Move(self.RoamOutside[cache.OutsideRoamIndex]):OnComplete(function()
			if cache.RoamIdleTimer == nil then
				self.PlayAnimation("Idle");
				cache.RoamIdleTimer = tick() + math.random(10, 20);
				
			elseif tick() > cache.RoamIdleTimer then
				cache.RoamIdleTimer = nil;
				cache.OutsideRoamIndex = math.random(1, #self.RoamOutside);
				
			end
		end)
		
		return modLogicTree.Status.Success;
	end)
	
	return tree;
end
