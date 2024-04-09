local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

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
		self.Humanoid.WalkSpeed = 10;
		self.Humanoid.JumpPower = 50;
		
		coroutine.yield();
	end
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	
	--== Connections;
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
return self end
