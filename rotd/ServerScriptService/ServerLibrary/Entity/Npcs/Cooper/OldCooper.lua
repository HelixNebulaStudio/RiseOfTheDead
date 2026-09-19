local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = shared.require(game.ServerScriptService.ServerLibrary.Entity.NpcClass);

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnCFrame = spawnPoint;
		Immortal = 1;
		
		Properties = {
			WalkSpeed={Min=2; Max=16};
			AttackSpeed=1;
			AttackDamage=10;
			AttackRange=3;
		};
	};
	self.Speeches = {
		"C'mon David..";
		"No funny stuff, is it just me or is there more and more zombies..";
		"Do we have anything to do today?";
	}
	
	--== Initialize;
	function self.Initialize()
		self.Seat = workspace.Environment:FindFirstChild("CooperSeat");
		
		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("Wield");
	self:AddComponent("AvatarFace");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Chatter);
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		if self.Seat and not self.Humanoid.Sit then
			self.Seat:Sit(self.Humanoid);
		end
		
		wait(random:NextNumber(5, 10));
		return true;
	end
	
	--== Connections;
	
return self end
