local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modAudio = require(game.ReplicatedStorage.Library.Audio);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Immortal = 1;
		
		Properties = {
			WalkSpeed={Min=2; Max=16};
			AttackSpeed=1;
			AttackDamage=10;
			AttackRange=3;
		};
	};
	
	self.Speeches = {
		"Ropes.. check. Ammunition.. check. Guns.. oh..";
		"Hmmm.. should I check the shelves again..? nah.";
		"Maybe this would work.. oh wait, no...";
		"Mixing sulfur with the.. hmm..";
	}
	local seat = script:WaitForChild("Seat");
	seat.Parent = workspace.Environment;
	
	--== Initialize;
	function self.Initialize()
		
		repeat until not self.Update();
		coroutine.yield();
	end
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Chatter);
	
	--== NPC Logic;
	function self.Update()
		if not modBranchConfigs.IsWorld("TheWarehouse") then return false; end;
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		seat:Sit(self.Humanoid);
		self.PlayAnimation("Sit", 1);
		wait(10);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
