local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Immortal = 1;
		
		Properties = {
			WalkSpeed={Min=2; Max=16};
			AttackSpeed=1;
			AttackDamage=10;
			AttackRange=3;
		};
	};
	self.Speeches = {
		"Hmmmm.. Honestly, what should I do..";
		"You can't be honestly winning..";
		"Cooper, I know you're hiding the money somewhere aren't you..";
	}
	
	--== Initialize;
	function self.Initialize()
		self.Seat = workspace.Environment:FindFirstChild("DavidSeat");
		
		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent(HumanModule.OnHealthChanged);
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
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
return self end
