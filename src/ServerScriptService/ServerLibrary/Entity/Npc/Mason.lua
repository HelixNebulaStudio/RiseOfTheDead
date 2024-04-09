local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

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
	
	--== Initialize;
	local carLoopConnection;
	function self.Initialize()
		self.Humanoid.WalkSpeed = 10;
		self.Humanoid.JumpPower = 50;
		
		self.SetAnimation("SearchAnim", {script.SearchAnim});
		self.SetAnimation("InspectAnim", {script.InspectAnim});
		
		coroutine.yield();
	end
	
	self.CarLoop = function()
		if carLoopConnection then carLoopConnection:Disconnect(); carLoopConnection = nil end;
		carLoopConnection = modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
			if self.IsDead or self.Humanoid == nil or self.Humanoid.RootPart == nil then carLoopConnection:Disconnect(); return false; end;
			self.CarLooping = true;
			self.Wield.Unequip();
			
			self.Move:SetMoveSpeed("set", "default", 5);
			
			local clock = math.ceil(math.fmod(modSyncTime.GetTime(), 48));
			if clock == 1 then
				self.Move:MoveTo(Vector3.new(28.5209942, 57.8597412, 18.2690334));
				if self.Move.MoveToEnded:Wait(15) ~= nil then
					task.wait(1);
					self.Move:Face(Vector3.new(16.220993, 57.8597412, 17.5690327));
				end
				
			elseif clock == 13 then
				self.Move:MoveTo(Vector3.new(51.2800293, 57.6597404, 40.0281067));
				if self.Move.MoveToEnded:Wait(15) ~= nil then
					task.wait(0.5);
					self.Move:Face(Vector3.new(51.2800293, 57.6597404, 42.4281158));
					task.wait(0.5);
					self.PlayAnimation("SearchAnim");
				else
					self.PlayAnimation("shrug2");
				end
				
			elseif clock == 27 then
				self.Move:MoveTo(Vector3.new(54.1209679, 57.6597404, 13.2690449));
				if self.Move.MoveToEnded:Wait(15) ~= nil then
					task.wait(0.5);
					self.Move:Face(Vector3.new(51.1209717, 57.6597404, 14.3690434));
					task.wait(0.5);
					self.PlayAnimation("InspectAnim");
				else
					self.PlayAnimation("shrug2");
				end
				
			elseif clock == 40 then
				if random:NextInteger(1,10) == 1 and self.Owner then
					self.Chat(self.Owner, "If anyone needs help, I will be pleased to help out.");
				end
				self.PlayAnimation("Idle");
				
			end
		end)
		self.Garbage:Tag(carLoopConnection);
	end
	
	self.StopCarLoop = function()
		if carLoopConnection then carLoopConnection:Disconnect(); carLoopConnection = nil end;
		self.CarLooping = false;
	end;
		
	self.Garbage:Tag(self.BindOnTalkedTo.Event:Connect(function(prefab, target, choice)
		if prefab ~= self.Prefab then return end;
		if not (self.Owner ~= nil and target == self.Owner) then return end;
		
		self.AnimationController:Stop("Lean");
		self.AnimationController:Stop("SearchAnim");
		self.AnimationController:Stop("InspectAnim");
		
		self.TalkPause = tick()+10;
		if choice == "close" then
			self.TalkPause = tick();
			return;
		end
		
		self.Actions:FaceOwner(function()
			self.Move:Pause(2);
			
			local breakReq = false;
			if tick() > self.TalkPause then
				breakReq = true;
			elseif target:DistanceFromCharacter(self.RootPart.Position) > 15 then
				breakReq = true;
			end
			
			return breakReq;
		end);
	end));
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
