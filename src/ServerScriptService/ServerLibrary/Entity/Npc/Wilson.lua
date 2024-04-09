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
		
--		Properties = {
--			WalkSpeed={Min=2; Max=16};
--		};
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
--	self:AddComponent("IsInVision");
--	self:AddComponent(HumanModule.OnHealthChanged);
--	self:AddComponent(HumanModule.Chat);
--	self:AddComponent(HumanModule.Actions);
	
--	--== NPC Logic;
--	function self.Update()
--		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
--		if self.InMission == nil then
--			self.PlayAnimation("ListenToDevice");
--		else
--			self.StopAnimation("ListenToDevice");
--		end
--		wait(60);
		
--		return true;
--	end
	
--	--== Connections;
--	self.Garbage:Tag(self.BindOnTalkedTo.Event:Connect(function(prefab, target, choice)
--		if prefab == self.Prefab then
--			self.Actions:FaceOwner();
--			if self.Movement.IsMoving then self.Movement:Pause(10); end;
--			repeat until self.RootPart == nil or target:DistanceFromCharacter(self.RootPart.Position) > 15 or not wait(2);
--			if self == nil or self.Movement == nil then return end
--			self.Movement:Resume();
--		end
--	end));
--	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
--return self end