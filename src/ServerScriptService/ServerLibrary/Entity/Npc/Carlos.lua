local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Immortal = 1;
	};

	local musicParticle1 = script.notes1:Clone(); musicParticle1.Parent = self.Prefab.Head;
	local musicParticle2 = script.notes2:Clone(); musicParticle2.Parent = self.Prefab.Head;
	
	local speeches = {
		"The sorrow days will need some tunes..";
		"♪ You only live once, living miserably around oceans ♪";
		"I dedicate this to those who did not make it..";
		"The music of living is over the past.";
	}
	local playFluteCooldown = tick()+20;
	
	--== Initialize;
	function self.Initialize()
		self.Move:Init();
		self.Think:Fire();

		self.Wield.Equip("flute");
		self.Wield:ToggleIdle(true);
		
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
		if tick() < playFluteCooldown then return end;
		playFluteCooldown = tick() + math.random(120, 300);

		self.Wield:ToggleIdle(false);
		
		local fluteSong = modAudio.Play("FluteSong"..math.random(1, 2), self.RootPart);
		
		self.Wield.PlayAnim("Use");
		self.Chat(game.Players:GetPlayers(), speeches[math.random(1, #speeches)]);
		self.AvatarFace:Set("rbxassetid://2071837798");

		musicParticle1.Enabled = true;
		musicParticle2.Enabled = true;
		task.wait(fluteSong.TimeLength);

		self.AvatarFace:Set("rbxassetid://20418584");
		musicParticle1.Enabled = false;
		musicParticle2.Enabled = false;
		
		fluteSong:Destroy();
		self.Wield.StopAnim("Use");
		self.Wield:ToggleIdle(true);
	end))
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	self.Humanoid.Died:Connect(self.OnDeath);

	return self;
end


--local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--local random = Random.new();

--local HumanModule = script.Parent.Human;
----== Modules
--local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
--local modAudio = require(game.ReplicatedStorage.Library.Audio);

---- Note; Function called for each NPC before parented to workspace;
--return function(npc, spawnPoint)
--	local self = modNpcComponent{
--		Prefab = npc;
--		SpawnPoint = spawnPoint;
--		Immortal = 1;
		
--		Properties = {
--			WalkSpeed={Min=2; Max=16};
--			AttackSpeed=1;
--			AttackDamage=10;
--			AttackRange=3;
--		};
--	};
	
--	--== Initialize;
--	local musicParticle1 = script.notes1:Clone(); musicParticle1.Parent = self.Prefab.Head;
--	local musicParticle2 = script.notes2:Clone(); musicParticle2.Parent = self.Prefab.Head;
	
--	local fluteAnimation;
--	local speeches = {
--		"The sorrow days will need some tunes..";
--		"♪ You only live once, living miserably around oceans ♪";
--		"I dedicate this to those who did not make it..";
--		"The music of living is over the past.";
--	}
	
--	function self.Initialize()
--		repeat until not self.Update();
--	end
	
--	--== Components;
--	self:AddComponent("Movement");
--	self:AddComponent("AvatarFace");
--	self:AddComponent(HumanModule.OnHealthChanged);
--	self:AddComponent(HumanModule.Chat);
	
--	--== NPC Logic;
--	function self.Update()
--		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
--		self.Chat(game.Players:GetPlayers(), speeches[random:NextInteger(1, #speeches)]);
		
--		self.PlayAnimation("PlayFlute", 0.5);
		
--		local fluteSong = modAudio.Play("FluteSong"..random:NextInteger(1, 2), self.RootPart);
--		self.AvatarFace:Set("rbxassetid://2071837798");
		
--		musicParticle1.Enabled = true;
--		musicParticle2.Enabled = true;
--		task.wait(fluteSong.TimeLength);
		
--		self.AvatarFace:Set("rbxassetid://20418584");
--		musicParticle1.Enabled = false;
--		musicParticle2.Enabled = false;
		
--		self.StopAnimation("PlayFlute", 0.5);
--		wait(random:NextNumber(120, 300));
		
--		return true;
--	end
	
--	--== Connections;
--	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
--return self end
