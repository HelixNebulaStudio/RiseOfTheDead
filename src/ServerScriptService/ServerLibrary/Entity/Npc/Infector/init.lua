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
		Infector = true;
		
		Properties = {
			AttackSpeed=2.5;
			AttackDamage=10;
			AttackRange=3;
		};
		
		Configuration = {
			Level=1;
		};
	};
	
	
	--== Initialize;
	function self.Initialize()
		local level = math.max(self.Configuration.Level-1, 0);

		self.Move.SetDefaultWalkSpeed = 22;
		self.Move:Init();
		
		self.Humanoid.Name = "Zombie";
		
		local face = self.Prefab.Head:WaitForChild("face");
		face.Texture = "rbxassetid://5195838286";
		
		game.Debris:AddItem(self.Prefab:FindFirstChild("Interactable"), 0);
		
		CollectionService:AddTag(self.Prefab, "TargetableEntities");
		CollectionService:AddTag(self.RootPart, "Enemies");
		CollectionService:AddTag(self.Prefab, "Zombies");

		self.Think:Fire();
		coroutine.yield();
	end
	
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent(InfectorModule.OnHealthChanged);
	self:AddComponent(InfectorModule.OnDeath);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	
	
	--== Connections;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree(script.InfectorTree, true);

	end));
	
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
return self end
