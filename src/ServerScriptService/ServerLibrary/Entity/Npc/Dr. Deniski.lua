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
	
	local speeches = {
		"Only if there's some way I can help..";
		"Невероятно!";
		"я скучаю по дому..";
		"We may be running out of supplies..";
		"I wonder how is it in mother Russia..";
	}
	
	--== Initialize;
	function self.Initialize()
		spawn(function()
			repeat
				if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
				self.Chat(game.Players:GetPlayers(), speeches[random:NextInteger(1, #speeches)]);
			until not wait(random:NextNumber(32,350));
		end)
		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent("AvatarFace");
	self:AddComponent(HumanModule.DanceRadio);
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		wait(random:NextNumber(5,22));

		if not self.AnimationController:IsPlaying("Dance") then
			self.PlayAnimation("Idle");
		end;
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
