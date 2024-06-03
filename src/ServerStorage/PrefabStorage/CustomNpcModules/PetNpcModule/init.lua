local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local remotes = game.ReplicatedStorage.Remotes;
local remoteOnDoorEnter = remotes.Interactable.OnDoorEnter;

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Immortal = 0.2;
	};
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.WalkSpeed = 25;
		self.Humanoid.JumpPower = 60;
		self.Humanoid.MaxHealth = 500;
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.Move:Init();
		self.Think:Fire();

		self.Chat(self.Owner, "I am at your service!");
		self:ToggleInteractable(false);
		
		local rangedWeapons = {"mp7"; "m4a4"; "xm1014"; "ak47";};
		self.ActiveRangedWeapon = rangedWeapons[math.random(1, #rangedWeapons)];
		
		local healTools = {"medkit";};
		self.ActiveHealTool = healTools[math.random(1, #healTools)];
		
		local meleeWeapons = {"machete"; "spikedbat"; "broomspear";};
		self.ActiveMeleeWeapon = meleeWeapons[math.random(1, #meleeWeapons)];

		coroutine.yield();
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("Wield");
	self:AddComponent("AvatarFace");
	self:AddComponent("IsInVision");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	self:AddComponent(HumanModule.OnDeath);
	self:AddComponent(HumanModule.OnHealthChanged);
	
	--== Connections;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree(script.PetNpcTree, true);
	end))
	self.Garbage:Tag(remoteOnDoorEnter.Event:Connect(function(player, interactData)
		if self.Owner == player and interactData.Object then
			if interactData.Object then
				self.RootPart.CFrame = CFrame.new(interactData.Object.Destination.WorldPosition + Vector3.new(0, 2.35, 0))
					* CFrame.Angles(0, math.rad(interactData.Object.Destination.WorldOrientation.Y-90), 0);
				self.Move:Recompute();
			end
		end
	end));
	
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end