local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

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
		self.Move:Init();
		self.Think:Fire();
		
		coroutine.yield();
	end

	--== Components;
	self:AddComponent("Wield");
	self:AddComponent("AvatarFace");
	self:AddComponent("IsInVision");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	self:AddComponent(HumanModule.OnDeath);
	self:AddComponent(HumanModule.OnHealthChanged);

	--== Connections;
	self.Garbage:Tag(self.Think:Connect(function()
		if self.InMission == true then
			if self.Wield.ItemId == "walkietalkie" then
				self.Wield.Unequip();
			end
			
		else
			if self.Wield.ItemId ~= "walkietalkie" then
				self.Wield.Equip("walkietalkie");
				self.Wield.PrimaryFireRequest(true);
			end
			
		end
	end))
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	self.Humanoid.Died:Connect(self.OnDeath);

	return self;
end
