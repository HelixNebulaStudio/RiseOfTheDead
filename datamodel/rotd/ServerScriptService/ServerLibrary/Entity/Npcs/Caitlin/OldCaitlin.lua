local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npcs.Human;
--== Modules
local modNpcComponent = shared.require(game.ServerScriptService.ServerLibrary.Entity.NpcClass);

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
		self.IsIdle = true;
		coroutine.yield();
	end

	--== Components;
	self:AddComponent("Wield");
	self:AddComponent("AvatarFace");
	self:AddComponent("IsInVision");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);

	--== Connections;
	self.Garbage:Tag(self.Think:Connect(function()
		if self.IsIdle == true then
			local distance = self.Actions:DistanceFrom(self.SpawnPoint.Position);
			if distance > 10 and self.ReturnToBase and (tick()-self.ReturnToBase) >= 60 then
				self.Actions:Teleport(self.SpawnPoint);

			elseif distance > 30 then
				self.ReturnToBase = tick();
				self.Humanoid.WalkSpeed = distance < 60 and 17 or 22;
				self.Move:MoveTo(self.SpawnPoint.Position);

			elseif distance < 3 then
				self.Move:Face(self.SpawnPoint.Position + self.SpawnPoint.LookVector*10);
				self.ReturnToBase = nil;

			end
		end
		
	end))

	return self;
end
