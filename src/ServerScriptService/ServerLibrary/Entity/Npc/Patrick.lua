local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

local triggerPrefab = script:WaitForChild("Trigger");
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
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
	self:AddComponent("Logic");
	self:AddComponent("Wield");
	self:AddComponent(HumanModule.Chat);
	
	--== Initialize;
	function self.Initialize()
		self.Trigger = triggerPrefab:Clone();
		self.Trigger.Parent = workspace.Environment;
		self.Enemies = {};
		
		self.Garbage:Tag(self.Trigger.Touched:Connect(function(basePart)
			local humanoid = basePart.Parent:FindFirstChildWhichIsA("Humanoid")
						or (basePart.Parent and basePart.Parent.Parent:FindFirstChildWhichIsA("Humanoid")) or nil;
						
			if humanoid and humanoid.Name == "Zombie" and humanoid.Health > 0 then
				local npcStatus = humanoid.Parent:FindFirstChild("NpcStatus") and require(humanoid.Parent.NpcStatus) or nil;
				if npcStatus and npcStatus:GetModule() then
					local exist = false;
					for a=1, #self.Enemies do
						if self.Enemies[a].Prefab == humanoid.Parent then exist = true; break; end;
					end
					if not exist then
						table.insert(self.Enemies, npcStatus:GetModule());
					end
				end
			end
		end))
		
		self.Garbage:Tag(function()
			game.Debris:AddItem(self.Trigger, 0);
		end)
		
		self.Wield.Equip("ak47");
		pcall(function()
			self.Wield.ToolModule.Configurations.AmmoLimit = 40;
			self.Wield.ToolModule.Properties.ReloadSpeed = 1;
			self.Wield.ToolModule.Configurations.MinBaseDamage = 200;
			self.Wield.SetSkin({
				Textures={
					["Grip"]=102;
					["Stock"]=102;
				};
			});
		end);
		repeat until not self.Update();
	end
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then
			Debugger:Log("Patrick died.");
			return false; 
		end;
		for a=1, #self.Enemies do
			local EnemyModule = self.Enemies[a];
			if EnemyModule.Humanoid and EnemyModule.Humanoid.Health > 0 and EnemyModule.RootPart and (EnemyModule.RootPart.Position - self.RootPart.Position).Magnitude <= 40 then
				EnemyModule:UpdateDropReward(modRewardsLibrary:Find("michaelkills"));
				self.Wield.SetEnemyHumanoid(EnemyModule.Humanoid);
				self.Move:Face(EnemyModule.RootPart);
				self.Wield.PrimaryFireRequest();
				break;
			end
		end
		if (self.RootPart.Position-Vector3.new(796.522, 162.68, -730.796)).Magnitude > 3 then
			self.Move:MoveTo(Vector3.new(796.522, 162.68, -730.796));
		end
		if #self.Enemies <= 0 then
			self.Wield.ReloadRequest();
			self.Move:Face(Vector3.new(786.144, 160.768, -729.907));
		end;
		
		self.Humanoid.Health = self.Humanoid.Health +1;
		self.Logic:Wait(0.5);
		return true;
	end
	
return self end
