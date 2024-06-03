local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

local HumanModule = script.Parent.Human;
local ZombieModule = script.Parent.Zombie;
local BanditModule = script.Parent.Bandit;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local remotes = game.ReplicatedStorage.Remotes;
local remoteOnDoorEnter = remotes.Interactable.OnDoorEnter;

return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		
		Properties = {
			WalkSpeed = {Min=5; Max=5};
		};
	};
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("AvatarFace");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent("RandomClothing");
	
	self:AddComponent(HumanModule.Actions);
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.WalkSpeed = 25;
		self.Humanoid.JumpPower = 60;
		
		if self.Seed == nil then self.Seed = math.random(1, 100000); end;
		self.RandomClothing(self.Name, self.Seed);
		
		delay(5, function()
			if self.IsDead or self.Humanoid.RootPart == nil then return; end;
			if self.FollowingOwner then
				self:AddComponent(HumanModule.AttractZombies);
			end
		end)
		
		repeat until (self.Update == nil or not self.Update());
	end
	
	--== NPC Logic;

	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		if self.Humanoid.Sit then self.Humanoid.Jump = true; end;
		if self.Owner and self.Owner:IsDescendantOf(game.Players) or modBranchConfigs.IsWorld("BioXResearch") then
			local character = self.Owner and self.Owner.Character;
			local rootPart = character and character:FindFirstChild("HumanoidRootPart") or nil;
			if rootPart then
				
				if self.FollowingOwner then
					local distance = self.Owner:DistanceFromCharacter(self.RootPart.Position);
					if distance >= 64 then
						self.Follow();
						self.PlayAnimation("Panic");
						wait(3.4);
						self.StopAnimation("Panic");
						self.Actions:Teleport();
						
					elseif distance >= 16 then
						self.Humanoid.WalkSpeed = 25;
						
					else
						self.Humanoid.WalkSpeed = 10;
						
					end
					self.Follow(rootPart, 5);
					
				else
					self.PlayAnimation("Panic");
					self.Follow();
					
				end
			end
		else
			
			self.Prefab:Destroy();
		end
		wait(1);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(remoteOnDoorEnter.Event:Connect(function(player, interactData)
		if not self.FollowingOwner then return end;
		if self.Owner == player and interactData.Object then
			if interactData.Object then
				self.Follow();
				self.RootPart.CFrame = CFrame.new(interactData.Object.Destination.WorldPosition + Vector3.new(0, 2.35, 0))
									 * CFrame.Angles(0, math.rad(interactData.Object.Destination.WorldOrientation.Y-90), 0);
			end
		end
	end));
	
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(function()
		if self.Owner then
			
			modMission:Progress(self.Owner, 34, function(mission)
				if mission.ProgressionPoint == 2 then
					modMission:FailMission(self.Owner, 34, "You left the stranger to die. Talk to Molly to retry.");
				end
			end)
			modMission:Progress(self.Owner, 48, function(mission)
				if mission.ProgressionPoint == 2 then
					modMission:FailMission(self.Owner, 48, "You left the stranger to die.");
				end
			end)
			
			game.Debris:AddItem(self.Prefab, 20);
		end
		self:KillNpc();
	end);
	
return self end
