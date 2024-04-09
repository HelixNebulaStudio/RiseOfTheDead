local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
--== Modules Warn: Don't require(Npc)
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		Immortal = 1;
		
		Properties = {
			WalkSpeed = {Min=5; Max=5};
		};
	};
	--== Initialize;
	function self.Initialize()
		self.Humanoid.WalkSpeed = 10;
		self.Humanoid.JumpPower = 50;
		
		self.Wield.Equip("lasso");
		self.Wield.PrimaryFireRequest();
		
		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("AvatarFace");
	self:AddComponent("IsInVision");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		wait(1);
		return true;
	end
	
	--== Connections;
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
return self end
