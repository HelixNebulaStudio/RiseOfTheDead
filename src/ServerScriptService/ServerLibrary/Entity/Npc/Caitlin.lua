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
		self.IsIdle = true;
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
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));

	return self;
end

--local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--local random = Random.new();

--local HumanModule = script.Parent.Human;
----== Modules
--local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

---- Note; Function called for each NPC before parented to workspace;
--return function(npc, spawnPoint)
--	local self = modNpcComponent{
--		Prefab = npc;
--		SpawnPoint = spawnPoint;
--		Immortal = 1;
--	};
	
--	--== Initialize;
--	function self.Initialize()
--		self.Humanoid.WalkSpeed = 6;
--		self.Humanoid.JumpPower = 50;
--		repeat until not self.Update();
--	end
	
--	--== Components;
--	self:AddComponent("AvatarFace");
--	self:AddComponent("Follow");
--	self:AddComponent("Movement");
--	self:AddComponent("Wield");
--	self:AddComponent(HumanModule.OnHealthChanged);
--	self:AddComponent(HumanModule.Chat);
--	self:AddComponent(HumanModule.Actions);
	
--	--== NPC Logic;
--	function self.Update()
--		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
--		wait(10);
		
--		local distance = self.Actions:DistanceFrom(self.SpawnPoint.p);
--		if distance > 10 and self.ReturnToBase and (tick()-self.ReturnToBase) >= 60 then
--			self.Actions:Teleport(self.SpawnPoint);
			
--		elseif distance > 30 then
--			self.ReturnToBase = tick();
--			self.Humanoid.WalkSpeed = distance < 60 and 17 or 22;
--			self.Movement:Move(self.SpawnPoint.p);
			
--		elseif distance < 3 then
--			self.Movement:Face(self.SpawnPoint.p + self.SpawnPoint.LookVector*10);
--			self.ReturnToBase = nil;
			
--		end
		
--		return true;
--	end
	
--	--== Connections;
--	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
--return self end
