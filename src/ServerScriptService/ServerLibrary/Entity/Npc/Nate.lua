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
		
		SafehouseId = "Community";
		Enemies = {};
	};
	
	--== Initialize;
	function self.Initialize()
		if modBranchConfigs.IsWorld("TheResidentials") then
			repeat until not self.Update();
		else
			coroutine.yield();
		end
	end
	
	self.BanditMessages = {
		"This is bad..";
		"Can't believe this..";
		"Here to waste our time again..";
		"These bandits...";
	}
	
	self.GoneMessages = {
		"Finally..";
		"Good riddance..";
		"Gone for good.";
	}
	
	self.NpcChat = {
		Zep = {
			{"Hey Zep, how's our supplies at the moment?"; "We're good for now, sir."};
			{"Zep, I might head out later. Do you need anything specific?"; "I'm good. Thanks though!"};
			{"Hey, Kelly needs some help with the pest issue in the basement. Are you free right now?"; "I'm afraid not sir, I'm still finishing up some tasks."};
			{"Hey Zep, what should we look for on our next scavenge?"; "We may be running low on generator fuel, I'll double check and get back to you."};
			{"Zep, have you received any info from your brother?"; "Well, he said the bandits are on high alert because they captured something and they think there's a double agent amongst them."};
		};
		Kelly = {
			{"Why are you looking at me weird, Kelly, do you have a question or something?"; "Yeah, I have a lot of questions. Number one: How dare you?"};
			{"Kelly, I need someone to patrol the east wall."; "Can't you see I'm really busy right now you donkey."};
			{"What exactly do you do around here Kelly?"; "I manage people, like myself, I'm a really hard person to manage alright?"};
			{"Hey, there's a rat behind you."; "AHHH!? Wait what, no there's no rat here you donkey!"};
			{"Hey, Dallas may have scavenge some stuff, can you help him?"; "I am bbbbbbbusy! Shoo."};
		};
		Dallas = {
			{"I see you've been talking to Zep, how's it going?"; "Hahah... It's been all-right."};
			{"Seems like the north is clear for a while. You good to head out?"; "Are you sure? Wasn't there a hoard-call like northwest of here."};
			{"The R.A.T. won't budge. He says Ravas might not like the deal.."; "Unbelievable, they are basically scamming us. What do they actually want?"};
		};
	}
	
	self.RoamOutside = {
		Vector3.new(1220.08044, 57.8646698, -84.2309723);
		Vector3.new(1223.31506, 57.8646698, -9.51721191);
		Vector3.new(1272.66101, 57.8646698, 26.879612);
		Vector3.new(1152.85193, 57.8646698, 25.494751);
		Vector3.new(1091.64258, 57.5146675, -76.0740967);
		Vector3.new(1170.78516, 56.7646942, -12.0181885);
	}
	
	self.RoamSafehome = {
		Vector3.new(1201.277, 61.2, -123.466);
		Vector3.new(1151.049, 75.74, -104.612);
		Vector3.new(1155.465, 61.2, -102.654);
	}
	
	self.BedLocation = Vector3.new(1146.57788, 60.6645851, -137.086426);
	self.SnoozeTexts = {"ZzZzZzZzZ.."};
	self.BedSeat = workspace.Environment:FindFirstChild("NateSleepingSeat", true);
	self.SafehouseDoorEnter = "SafehouseEntranceFront";
	self.SafehouseDoorExit = "SafehouseExitFront"
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead then return false; end;
		
		self.BehaviorTree:RunTree("CommunityNpcTree", true);
		
		--Debugger:Display{
		--	State=tostring(self.BehaviorTree.State);
		--	Status=tostring(self.BehaviorTree.Status);
		--}
		
		task.wait(0.5);
		return true;
	end
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent("BehaviorTree");
	self:AddComponent("ObjectScan");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	
	--== Connections;
	self.Garbage:Tag(self.BindOnTalkedTo.Event:Connect(function(prefab, target, choice)
		if prefab == self.Prefab then
			local rootPart = target.Character and target.Character.PrimaryPart or nil;
			if rootPart then
				self.Movement:Face(rootPart.Position);
			end
			self.AvatarFace:Set();
			self.Logic:SetState("NpcTalk");
			if self.Movement.IsMoving then self.Movement:Pause(10); end;
			repeat until self.RootPart == nil or target:DistanceFromCharacter(self.RootPart.Position) > 15 or not wait(2);
			if self == nil or self.Movement == nil then return end
			self.Movement:Resume();
		end
	end));
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
	
	
return self end
