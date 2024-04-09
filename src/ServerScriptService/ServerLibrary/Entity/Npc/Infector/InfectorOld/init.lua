local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local InfectorModule = script;
local HumanModule = script.Parent.Human;
local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local CollectionService = game:GetService("CollectionService");

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		--Immortal = false;
		Infector = true;
		
		Properties = {
			WalkSpeed={Min=2; Max=16};
			AttackSpeed=1;
			AttackDamage=20;
			AttackRange=3;
		};
		
		Configuration = {};
	};
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.WalkSpeed = 35;
		self.Humanoid.JumpPower = 50;
		
		self.Humanoid.Name = "Zombie";
		
		local face = self.Prefab.Head:WaitForChild("face");
		face.Texture = "rbxassetid://5195838286";
		
		game.Debris:AddItem(self.Prefab:FindFirstChild("Interactable"), 0);
		
		CollectionService:AddTag(self.Prefab, "TargetableEntities");
		CollectionService:AddTag(self.RootPart, "Enemies");
		CollectionService:AddTag(self.Prefab, "Zombies");
		
		repeat until not self.Update();
	end
	
	function self.Update()
		if self == nil or self.IsDead or self.Humanoid.RootPart == nil then return false end;
		
		if self.Target then
		else
			self.Logic:SetState("Idle");
		end
		
		if self.Logic.State == "Idle" then
			self.Logic:Timeout("Idle", 1);
			
		elseif self.Logic.State == "Aggro" then
			
			if self.Target and self.Target:IsDescendantOf(workspace) then
				self.BehaviorTree:RunTree("AggroTree", true);
				self.Logic:Timeout("Aggro");
				
			else
				self.Target = nil;
				self.NextTarget();
				self.Logic:SetState("Idle");
				
			end
			
		else
			Debugger:Warn("Unknown state",self.Logic.State);
			return false;
		end
		
		--Debugger:Display{
		--	LogicState=tostring(self.Logic.State);
		--	State=tostring(self.BehaviorTree.State);
		--	Status=tostring(self.BehaviorTree.Status);
		--}
		
		return true;
	end
	
	--== Components;
	self:AddComponent("Logic");
	self:AddComponent("AvatarFace");
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent("BehaviorTree");
	self:AddComponent(InfectorModule.OnHealthChanged);
	self:AddComponent(InfectorModule.OnDeath);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
return self end
