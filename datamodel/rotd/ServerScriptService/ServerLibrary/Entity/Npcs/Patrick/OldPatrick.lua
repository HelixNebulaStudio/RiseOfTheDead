local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npcs.Human;
--== Modules
local modNpcComponent = shared.require(game.ServerScriptService.ServerLibrary.Entity.NpcClass);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);

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
	self:AddComponent("Logic");
	self:AddComponent(HumanModule.Chat);
	
	--== Initialize;
	function self.Initialize()
		local triggerPrefab = script:FindFirstChild("Trigger");
		self.Trigger = triggerPrefab:Clone();
		self.Trigger.Parent = workspace.Environment;
		self.Enemies = {};
		
		self.Garbage:Tag(self.Trigger.Touched:Connect(function(basePart)
			local humanoid = basePart.Parent:FindFirstChildWhichIsA("Humanoid")
						or (basePart.Parent and basePart.Parent.Parent:FindFirstChildWhichIsA("Humanoid")) or nil;
						
			if humanoid and humanoid.Name == "Zombie" and humanoid.Health > 0 then
				local npcInstance = humanoid.Parent:FindFirstChild("NpcClassInstance") and shared.require(humanoid.Parent.NpcClassInstance) or nil;
				if npcInstance and npcInstance.NpcClass then
					local exist = false;
					for a=1, #self.Enemies do
						if self.Enemies[a].Prefab == humanoid.Parent then exist = true; break; end;
					end
					if not exist then
						table.insert(self.Enemies, npcInstance.NpcClass);
					end
				end
			end
		end))
		
		self.Garbage:Tag(function()
			game.Debris:AddItem(self.Trigger, 0);
		end)
		
		self.WieldComp:Equip{ ItemId = "ak47" };
		-- Configuration settings no longer needed
		local skinJson = [[{"Plans":{"[Third]":"#965555;;;,,,,,;WornMetal;;;;","[Primary]":"#1b2a35;;0;,,,,,;OldMetal;0;;;","Magazine":";;;,,,,,;;;-50,210,0;87,66,98;","[All]":";;;,,,,,;;;;;","[Secondary]":"#965555;skindeathcamo_v1;0;,,,,,25;RustySpots;0;;;"},"Layers":{"[Third]":"Safety,ChargingHandle"}}]];
		self.WieldComp:SetCustomization("customization", {SkinJson=skinJson});
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
				self.Move:Face(EnemyModule.RootPart);
				local direction = (EnemyModule.RootPart.Position - self.RootPart.Position).Unit;
				self.WieldComp:InvokeToolAction("PrimaryFireRequest", direction);
				break;
			end
		end
		if (self.RootPart.Position-Vector3.new(796.522, 162.68, -730.796)).Magnitude > 3 then
			self.Move:MoveTo(Vector3.new(796.522, 162.68, -730.796));
		end
		if #self.Enemies <= 0 then
			if self.WieldComp.EquipmentClass then
				self.WieldComp:InvokeToolAction("ReloadRequest");
			end
			self.Move:Face(Vector3.new(786.144, 160.768, -729.907));
		end;
		
		self.Logic:Wait(0.5);
		return true;
	end
	
return self end
