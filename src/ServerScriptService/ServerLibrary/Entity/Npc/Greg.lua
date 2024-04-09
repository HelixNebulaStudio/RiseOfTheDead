local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local remotes = game.ReplicatedStorage.Remotes;

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Immortal = 1;
		
		PathIndex = 2;
	};
	
	local pathPoints = {
		self.SpawnPoint.p;
		Vector3.new(-212.43, 62.67, 241.518);
		Vector3.new(-246.074, 62.67, 310.532);
		Vector3.new(-272.843, 63.993, 443.957);
		Vector3.new(-373.806, 63.995, 417.235);
		Vector3.new(-428.913, 63.04, 245.029);
		Vector3.new(-324.338, 63.055, 290.503);
	}
	
	--== Initialize;
	function self.Initialize()
		self.Movement.DefaultWalkSpeed = 6;
		
		self.WalkTimer = tick();
		repeat 
			
			if modSyncTime.IsDay then
				if self.Wield.ToolModule then
					self.Wield.Unequip();
				end
			else
				if self.Wield.ToolModule == nil then
					self.Wield.Equip("lantern");
				end
			end
			
			if tick()-self.WalkTimer >= 60 then
				self.Actions:Teleport(CFrame.new(pathPoints[self.PathIndex]));
			end
			
			self.Movement:Move(pathPoints[self.PathIndex]):OnComplete(function()
				self.PathIndex = self.PathIndex +1;
				if self.PathIndex > #pathPoints then
					self.PathIndex = 1;
				end
				
				self.WalkTimer = tick();
			end)
			
			task.wait(1)
		until self.IsDead;
	end
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	
	self.Garbage:Tag(remotes.Dialogue.OnTalkedTo.Event:Connect(function(prefab, target, choice)
		if prefab == self.Prefab and self.IsTalking == nil then
			self.IsTalking = target.Character.PrimaryPart;
			
			local rootPart = self.IsTalking;
			if rootPart then
				self.Movement:Face(rootPart.Position);
			end
			
			repeat
				if self.Movement.IsMoving then self.Movement:Pause(3); end;
				task.wait(2);
			until self.IsDead or target:DistanceFromCharacter(self.RootPart.Position) > 10;
			
			self.IsTalking = nil;
		end
	end));
		
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
