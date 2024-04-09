local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Immortal = 1;
	};
	
	--== Initialize;
	function self.Initialize()
		coroutine.yield();
	end
	
	--== Components;
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("AvatarFace");
	self:AddComponent("IsInVision");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	self:AddComponent(HumanModule.OnDeath);
	self:AddComponent(HumanModule.OnHealthChanged);
	
	--== Connections;
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
return self end