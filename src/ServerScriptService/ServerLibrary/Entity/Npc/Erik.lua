local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
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
		self.Humanoid.WalkSpeed = 6;
		self.Humanoid.JumpPower = 50;
		
		repeat wait(1) until self.IsDead;
	end
	
	--== Components;
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("AvatarFace");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	
	--== Connections;
	self.Garbage:Tag(self.BindOnTalkedTo.Event:Connect(function(prefab, target, choice)
		if prefab == self.Prefab and target == self.Owner then
			if self.AnimationController:IsPlaying("Scared") then
				self.AnimationController:Play("ScaredPeek", {FadeTime=2});
				
				wait(0.5);
				self.AnimationController:Stop("Scared", {FadeTime=2});
			end
		end
	end))
	
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
return self end
