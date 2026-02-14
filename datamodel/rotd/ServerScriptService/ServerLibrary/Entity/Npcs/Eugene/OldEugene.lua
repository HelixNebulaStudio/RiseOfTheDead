local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = shared.require(game.ServerScriptService.ServerLibrary.Entity.NpcClass);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnCFrame = spawnPoint;
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
		
		coroutine.yield();
	end
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	
	--== Connections;
	self.Garbage:Tag(self.BindOnTalkedTo.Event:Connect(function(prefab, target, choice)
		if prefab == self.Prefab then
			self.Actions:FaceOwner();
		end
	end));
	
return self end
