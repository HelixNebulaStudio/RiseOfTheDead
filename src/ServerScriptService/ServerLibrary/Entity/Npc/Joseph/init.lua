local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Immortal = 1;
		
	};
	
	--== Initialize;
	self:SetClientScript(script:WaitForChild("JosephClient"));
	function self.Initialize()
		self.Humanoid.WalkSpeed = 6;
		self.Humanoid.JumpPower = 50;
		
		if modBranchConfigs.IsWorld("TheResidentials") then
			repeat until not self.Update();
		else
			coroutine.yield();
		end
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("AvatarFace");
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	
	local banditMessages = {
		"Not again...";
		"These bandits..";
		"My lettuces!!";
		"Darn these bandits..";
	}
	
	local goneMessages = {
		"Hallelujah, they are gone!";
		"Thank the lord, that's over..";
		"They better be gone for good.";
	}
	--== NPC Logic;
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		if workspace.Entity:FindFirstChild("Bandit Pilot") then
			if not self.HideFromAttack then
				self.HideFromAttack = true;
				
				self.Humanoid.WalkSpeed = 18;
				self.Movement:Move(Vector3.new(1166.46814, 60.6696892, -107.040077)):Wait(10);
				self.Actions:Teleport(CFrame.new(1166.46814, 60.6696892, -107.040077, -0.034896221, 0, 0.99939996, 0, 1, 0, -0.99939996, 0, -0.034896221));
				wait(1);
				self.Humanoid.WalkSpeed = 6;
				self.Actions:Teleport(CFrame.new(1158.96814, 60.6696892, -107.040077, -0.034896221, 0, 0.99939996, 0, 1, 0, -0.99939996, 0, -0.034896221));
				self.Movement:Move(Vector3.new(1147.40295, 60.6696892, -101.79776)):Wait(5);
				self.Actions:Teleport(CFrame.new(1147.40295, 60.6696892, -101.79776, -0.99939096, 0, -0.0348956846, 0, 1, 0, 0.0348956846, 0, -0.99939096));
				
				self.Chat(game.Players:GetPlayers(), banditMessages[math.random(1, #banditMessages)]);
			end
			
		else
			if self.HideFromAttack then
				self.HideFromAttack = false;
				
				self.Humanoid.WalkSpeed = 6;
				self.Movement:Move(Vector3.new(1159.03516, 60.6696892, -107.062309)):Wait(5);
				self.Actions:Teleport(CFrame.new(1159.03516, 60.6696892, -107.062309, 0.0348960012, 0, -0.999391019, 0, 1, 0, 0.999391019, 0, 0.0348960012));
				wait(1);
				self.Humanoid.WalkSpeed = 13;
				self.Actions:Teleport(CFrame.new(1166.17505, 60.6696892, -107.062309, 0.0348960012, 0, -0.999391019, 0, 1, 0, 0.999391019, 0, 0.0348960012));
				self.Movement:Move(Vector3.new(1225.89795, 57.8096771, -69.6500931)):Wait(10);
				self.Actions:Teleport(CFrame.new(1225.89795, 57.8096771, -69.6500931, -0.034896221, 0, 0.99939996, 0, 1, 0, -0.99939996, 0, -0.034896221));
				
				self.Chat(game.Players:GetPlayers(), goneMessages[math.random(1, #goneMessages)]);
			end
		end
		
		
		wait(5);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.BindOnTalkedTo.Event:Connect(function(prefab, target, choice)
		if prefab == self.Prefab then
			local originalFaceDir = self.RootPart.Position + self.RootPart.CFrame.LookVector;
			local rootPart = target.Character and target.Character.PrimaryPart or nil;
			if rootPart then
				self.Movement:Face(rootPart.Position);
			end
			if self.Movement.IsMoving then self.Movement:Pause(10); end;
			repeat until self.RootPart == nil or target:DistanceFromCharacter(self.RootPart.Position) > 15 or not wait(2);
			if self == nil or self.Movement == nil then return end
			self.Movement:Resume();
			self.Movement:Face(originalFaceDir);
		end
	end));
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
