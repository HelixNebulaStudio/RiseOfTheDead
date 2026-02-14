local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npcs.Human;
--== Modules
local modNpcComponent = shared.require(game.ServerScriptService.ServerLibrary.Entity.NpcClass);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnCFrame = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		Immortal = 1;
		
		Properties = {
			WalkSpeed = {Min=0; Max=0};
		};
	};
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent("Movement");
	self:AddComponent(HumanModule.Chat);
	
	--== Initialize;
	function self.Initialize()
		self.Trigger = script:WaitForChild("Trigger");
		self.Trigger.Parent = workspace.Environment;
		self.Enemies = {};
		
		local chatCooldown = tick();
		self.Trigger.Touched:Connect(function(basePart)
			local prefab = basePart.Parent
			local humanoid = prefab and prefab:FindFirstChildWhichIsA("Humanoid")
						or (basePart.Parent and prefab.Parent:FindFirstChildWhichIsA("Humanoid")) or nil;
						
			if humanoid and humanoid.Name == "Zombie" and humanoid.Health > 0 then
				local exist = false;
				
				if prefab:GetAttribute("Leashed") then
					local leashPlayer = game.Players:FindFirstChild(prefab:GetAttribute("Leashed"));
					if leashPlayer then
						local mission = modMission:Progress(leashPlayer, 53);
						if mission == nil or mission.ProgressionPoint < 8 then
							if tick()-chatCooldown > 5 then
								chatCooldown = tick();
								self.Chat(leashPlayer, "Hey! What are you trying to do?!");
							end
							modMission:Progress(leashPlayer, 53, function(mission)
								if mission.ProgressionPoint == 6 then
									mission.ProgressionPoint = 7;
								end
							end)
						else
							exist = true;
						end
					end
				end
				
				
				for a=1, #self.Enemies do
					if self.Enemies[a] == humanoid.Parent then exist = true; break; end;
				end
				if not exist then
					table.insert(self.Enemies, prefab);
				end
			end
		end)
		self.WieldComp:Equip{ ItemId = "ak47" };
		-- Configuration settings no longer needed
		local skinJson = [[{"Plans":{"[All]":"#111111;;;,,,,,;WornMetal;;;;","[Diamonds]":";skindiamonds_v1;;#12eed4,,,,,19;;;;;"},"Layers":{"[Diamonds]":"Stock,Grip"}}]];
		self.WieldComp:SetCustomization("customization", {SkinJson=skinJson});
		repeat until not self.Update();
	end
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead then return false; end;
		for a=1, #self.Enemies do
			local prefab = self.Enemies[a];
			
			local humanoid = prefab:FindFirstChildWhichIsA("Humanoid");
			
			if humanoid and humanoid.Health > 0 and humanoid.RootPart and (humanoid.RootPart.Position - self.RootPart.Position).Magnitude <= 40 then
				
				local npcInstance = prefab:FindFirstChild("NpcClassInstance") and shared.require(prefab.NpcClassInstance) or nil;
				if npcInstance and npcInstance.NpcClass then
					npcInstance.NpcClass:UpdateDropReward(modRewardsLibrary:Find("michaelkills"));
				end
				
				self.Movement:Face(humanoid.RootPart.Position);
				local direction = (humanoid.RootPart.Position - self.RootPart.Position).Unit;
				self.WieldComp:InvokeToolAction("PrimaryFireRequest", direction);
				break;
			end
		end
		if (self.RootPart.Position-Vector3.new(645.012, 55.8, 9.048)).Magnitude > 3 then
			self.Movement:Move(Vector3.new(645.012, 55.8, 9.048));
		end
		if #self.Enemies <= 0 then
			if self.WieldComp.EquipmentClass then
				self.WieldComp:InvokeToolAction("ReloadRequest");
			end
			self.Movement:Face(Vector3.new(621.2, 55.8, 14.6));
		end;
		
		self.Humanoid.Health = self.Humanoid.Health +1;
		wait(0.5);
		return true;
	end
	
return self end
