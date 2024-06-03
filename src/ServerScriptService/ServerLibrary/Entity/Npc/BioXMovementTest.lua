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
		
		self.Wield.Equip("broomspear");
		
		task.spawn(function()
			task.wait(5);
			
			while true do
				
				Debugger:Warn("Run to point B");
				self.Move:SetMoveSpeed("set", "default", 22);
				self.Move:MoveTo(Vector3.new(79.979, -17.95, -152.038));
				self.Move.MoveToEnded:Wait();

				task.wait(1);
				
				Debugger:Warn("Climb to point C");
				self.Move:SetMoveSpeed("set", "default", 12);
				self.Move:MoveTo(Vector3.new(88.162, 11.218, -174.824));
				self.Move.MoveToEnded:Wait();

				task.wait(1);
				
				Debugger:Warn("Walk to point A");
				self.Move:SetMoveSpeed("set", "default", 6);
				self.Move:MoveTo(Vector3.new(140.191, -5.95, -167.01));
				self.Move.MoveToEnded:Wait();
				task.wait(1);
			end
			
			
		end)
		
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
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	self.Humanoid.Died:Connect(self.OnDeath);

	return self end
