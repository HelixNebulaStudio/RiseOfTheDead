local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = shared.require(game.ServerScriptService.ServerLibrary.Entity.NpcClass);

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

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
	
	--== Initialize;
	function self.Initialize()
		
		self.PlayAnimation("lean");
		coroutine.yield();
	end
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent(HumanModule.Chat);
	
	--== Connections;
	
return self end
