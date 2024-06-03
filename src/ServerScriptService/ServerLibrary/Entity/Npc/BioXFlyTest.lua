local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modArcTracing = require(game.ReplicatedStorage.Library.ArcTracing);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Immortal = 1;
	};

	--== Initialize;
	function self.Initialize()
		local arcTracer = modArcTracing.new();
		--arcTracer.DebugArc = true;
		arcTracer.RayRadius = 1;
		arcTracer.Acceleration = Vector3.new(0, -workspace.Gravity, 0);
		arcTracer.Delta = 1/5;
		
		local spawnCf = CFrame.new(95.8006897, -16.549099, -199.868301, -1, 0, 0, 0, 1, 0, 0, 0, -1);
		local destinationPos = Vector3.new(95.888, 11.218, -170.62);
		
		task.spawn(function()
			task.wait(5);
			
			while true do
				self:Teleport(spawnCf);
				task.wait(1);

				
				local duration = math.random(50, 200)/100;
				local velocity = arcTracer:GetVelocityByTime(spawnCf.Position, destinationPos, duration);
				
				local arcPoints = arcTracer:GeneratePath(spawnCf.Position, velocity, function(arcPoint)
					if arcPoint.Hit == nil then return end
					return true;
				end);
				
				self.Move:Fly(arcPoints, arcTracer.Delta);
				task.wait(5);
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
