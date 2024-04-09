local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

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
	self:AddComponent("AntiSit");
	self:AddComponent("Wield");
	self:AddComponent("AvatarFace");
	self:AddComponent("IsInVision");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	self:AddComponent(HumanModule.OnDeath);
	self:AddComponent(HumanModule.OnHealthChanged);

	--== Connections;
	self.Garbage:Tag(self.Think:Connect(function()
		
		if modBranchConfigs.IsWorld("TheWarehouse") then
			local standOutside = false;
			for _, player in pairs(game.Players:GetPlayers()) do
				if player:GetAttribute("FrankStandsOutside") == true then
					standOutside = true;
				end
			end
			
			if self.StandOutsideFlag ~= standOutside then
				self.StandOutsideFlag = standOutside;
				
				if standOutside then
					self.Actions:Teleport(CFrame.new(621.30304, 57.6994781, -63.9319839, -0.99862963, 0, -0.0523349829, 0, 1, 0, 0.0523349829, 0, -0.99862963));

					self.Move:MoveTo(Vector3.new(626.24646, 57.7509804, -71.2312393));
					self.Move.MoveToEnded:Wait(3);

					task.wait(0.3);
					
					self.Actions:Teleport(CFrame.new(635.752258, 57.7509804, -57.9237518, -0.882947564, 0, 0.469471574, 0, 1, 0, -0.469471574, 0, -0.882947564));
					
					self.Move:MoveTo(Vector3.new(632.439, 57.791, -56.184));
					self.Move.MoveToEnded:Wait(3);
					self.Actions:Teleport(CFrame.new(632.439026, 57.7910004, -56.1839981, -0.998630524, 0, -0.0523351468, 0, 1, 0, 0.0523351468, 0, -0.998630524));
					
					self.Move:Face(Vector3.new(632.755554, 57.7509804, -54.2100067));
					
				else
					
					self.Actions:Teleport(CFrame.new(632.439026, 57.7910004, -56.1839981, -0.998630524, 0, -0.0523351468, 0, 1, 0, 0.0523351468, 0, -0.998630524));
					self.Move:MoveTo(Vector3.new(636.303, 57.791, -60.539));
					self.Move.MoveToEnded:Wait(2);

					task.wait(0.3);
					self.Actions:Teleport(CFrame.new(626.618, 57.791, -72.355));

					self.Move:MoveTo(Vector3.new(621.303, 57.699, -63.932));
					self.Move.MoveToEnded:Wait(3);
					
					self.Actions:Teleport(CFrame.new(621.303, 57.699, -63.932, -0.99862963, 0, -0.0523349829, 0, 1, 0, 0.0523349829, 0, -0.99862963));
					
				end
				
			end
			
		end
		
	end))
	
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));

	return self end


--local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--local random = Random.new();

--local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
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
--		repeat
--			wait(1);
			
--			local standOutside = false;
			
--			for _, player in pairs(game.Players:GetPlayers()) do
--				if player:GetAttribute("FrankStandsOutside") == true then
--					standOutside = true;
--				end
--			end
			
--			if self.IsStandingOutSide ~= standOutside then
--				self.IsStandingOutSide = standOutside;
				
--				if standOutside then
--					self.Actions:Teleport(CFrame.new(621.30304, 57.6994781, -63.9319839, -0.99862963, 0, -0.0523349829, 0, 1, 0, 0.0523349829, 0, -0.99862963));
					
--					self.Move:MoveTo(Vector3.new(626.24646, 57.7509804, -71.2312393));
--					self.Move.MoveToEnded:Wait(5);
					
--					task.wait(0.3);
--					self.Actions:Teleport(CFrame.new(635.752258, 57.7509804, -57.9237518, -0.882947564, 0, 0.469471574, 0, 1, 0, -0.469471574, 0, -0.882947564));
--					self.Move:Face(Vector3.new(632.755554, 57.7509804, -54.2100067));
					
--				else
--					self.Actions:Teleport(CFrame.new(635.752258, 57.7509804, -57.9237518, -0.882947564, 0, 0.469471574, 0, 1, 0, -0.469471574, 0, -0.882947564));
					
--					self.Move:MoveTo(Vector3.new(636.23, 59.786, -62.127));
--					self.Move.MoveToEnded:Wait(5);
					
--					task.wait(0.3);

--					self.Move:MoveTo(Vector3.new(621.30304, 57.6994781, -63.9319839));
--					self.Move.MoveToEnded:Wait(5);
					
--					self.Actions:Teleport(CFrame.new(621.30304, 57.6994781, -63.9319839, -0.99862963, 0, -0.0523349829, 0, 1, 0, 0.0523349829, 0, -0.99862963));
					
--				end
--			end
			
--		until self.IsDead;
--	end
	
--	--== Components;
--	self:AddComponent("Wield");
--	self:AddComponent("AvatarFace");
--	self:AddComponent("IsInVision");
--	self:AddComponent(HumanModule.Chat);
--	self:AddComponent(HumanModule.Actions);
--	self:AddComponent(HumanModule.OnDeath);
--	self:AddComponent(HumanModule.OnHealthChanged);
	
--	--== Connections;
--	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
--	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
--return self end
