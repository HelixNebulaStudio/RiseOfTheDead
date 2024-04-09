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
	
	local seat = script:WaitForChild("Seat");
	seat.Parent = workspace.Environment;
	
	--== Initialize;
	function self.Initialize()
		spawn(function()
			repeat
				if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
				self.Chat(game.Players:GetPlayers(), "Zzzz.., zzz.., zz..");
			until not wait(random:NextNumber(600,1200));
		end)
		
		self.Wield.Equip("bunnyplush");
		
		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("Wield");
	self:AddComponent("AvatarFace");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		seat:Sit(self.Humanoid);
		self.PlayAnimation("Sit");
		wait(60);
		return true;
	end
	
	--== Connections;
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
return self end
