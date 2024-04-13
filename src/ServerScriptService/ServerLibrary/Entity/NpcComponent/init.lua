local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local RunService = game:GetService("RunService");

local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modLayeredVariable = require(game.ReplicatedStorage.Library.LayeredVariable);
local modEntityStatus = require(game.ReplicatedStorage.Library.EntityStatus);
local modPhysics = require(game.ReplicatedStorage.Library.Util.Physics);

local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

local npcHidden = game.ServerStorage.PrefabStorage:WaitForChild("Objects"):WaitForChild("NpcHidden"); -- for :TeleportHide();
npcHidden.Parent = workspace;

local remotes = game.ReplicatedStorage.Remotes;
local bindOnTalkedTo = remotes.Dialogue.OnTalkedTo;

local SafeKeys = {
	IsDestroyed = true;
	Id = true;
	IsDead = true;
	Name = true;
};
local componentsCache = {};
--==

local NpcComponent = {};
NpcComponent.__index = NpcComponent;

-- properties;
NpcComponent.ClassName = "NpcModule";
NpcComponent.BindOnTalkedTo = bindOnTalkedTo;

-- methods;
function NpcComponent:AddComponent(componentModule)
	local componentName;
	if type(componentModule) == "string" then
		componentName = componentModule;
		if componentsCache[componentName] == nil then
			local findModule = script:FindFirstChild(componentName);
			if findModule == nil then error("NpcComponent "..tostring(componentName).." does not exist."); end;
			componentsCache[componentName] = require(findModule);
		end
		if componentsCache[componentName] then
			self[componentName] = componentsCache[componentName].new(self);
			return self[componentName];
		end;
	elseif type(componentModule) == "userdata" and componentModule.ClassName == "ModuleScript" then
		componentName = componentModule.Name;
		self[componentName] = require(componentModule).new(self);
		return self[componentName];
	end
	error(self.Name..">>  Component Module is not a module.");
end

function NpcComponent:SetClientScript(localScript)
	self.ClientScript = localScript;
end

function NpcComponent:LoadClientScript(players)
	if self.ClientScript == nil then return end;
	players = typeof(players) == "table" and players or {players};


	for _, player in pairs(players) do
		if player.Character == nil then continue end;

		local exist = false;
		for _, obj in pairs(player.Character:GetChildren()) do
			if obj:IsA("LocalScript") and obj:GetAttribute("EntityId") == self.Prefab:GetAttribute("EntityId") then
				exist = true;
				break;
			end
		end

		if not exist then
			local clientEffects = self.ClientScript:Clone();
			clientEffects:SetAttribute("EntityId", self.Prefab:GetAttribute("EntityId"));
			local prefabTag = clientEffects:WaitForChild("Prefab");
			prefabTag.Value = self.Prefab;
			clientEffects.Parent = player.Character;

			self.Prefab.Destroying:Connect(function()
				game.Debris:AddItem(clientEffects, 0);
			end)
		end
	end
end

function NpcComponent:KillNpc()
	local rootPart: BasePart = self.RootPart;
	local prefab: Model = self.Prefab;
	local humanoid: Humanoid = self.Humanoid;
	
	humanoid.PlatformStand = true;
	humanoid.EvaluateStateMachine = false;
	humanoid.HealthDisplayDistance = 0;
	humanoid:SetAttribute("IsDead", true);
	self.IsDead = true;

	if self.Animator then
		for _, track: AnimationTrack in pairs(self.Animator:GetPlayingAnimationTracks()) do
			track:Stop();
		end
	end

	if self.BehaviorTree then
		self.BehaviorTree.Disabled = true;
		self.BehaviorTree:StopTree();
	end
	if self.InitializeThread and coroutine.status(self.InitializeThread) == "suspended" then
		task.spawn(function()
			local killS, killE = coroutine.resume(self.InitializeThread);
			if not killS then
				modAnalytics:ReportError("Kill Npc", self.Name..": "..(killE or "No error"), "warning");
			end
		end)
	end
	
	self:SetNetworkOwner("auto", true);

	task.spawn(function()
		if rootPart then
			for _, tag in pairs(rootPart:GetTags()) do
				rootPart:RemoveTag(tag);
			end
		end

		if prefab then
			for _, tag in pairs(prefab:GetTags()) do
				prefab:RemoveTag(tag);
			end
			prefab:SetAttribute("DeadbodyTick", tick());
			prefab:AddTag("Deadbody");
			task.delay(0.5, function()
				if not workspace.Entity:IsAncestorOf(prefab) then return end;
				prefab.Parent = workspace.Entities;
			end)
			task.delay(5, function()
				for _, obj in pairs(prefab:GetChildren()) do
					if not obj:IsA("BasePart") or obj.AssemblyRootPart == nil then continue end;
					obj.AssemblyRootPart.Anchored = true;
					obj.CanCollide = false;
				end
			end)
		end
		
		if self.Wield then
			for _, obj in pairs(self.Wield.Instances) do
				if obj:IsA("Model") then
					if obj.PrimaryPart then
						local handle: BasePart = obj.PrimaryPart;
						handle.Massless = false;
						handle.CustomPhysicalProperties = PhysicalProperties.new(4, 0.5, 1, 0.3, 1);
					end
					for _, weaponPart in pairs(obj:GetChildren()) do
						if weaponPart:IsA("BasePart") then
							weaponPart.CanCollide = true;
						end
					end
					if game:IsAncestorOf(obj) then
						obj.Parent = workspace.Debris;
					end
					game.Debris:AddItem(obj, 10);
					
				elseif obj:IsA("Motor6D") then
					obj:Destroy();
					
				end
			end
		end
	end)

	--game.Debris:AddItem(prefab, 1);
end

function NpcComponent:BreakJoint(motor: Motor6D)
	if motor == nil then return end;

	local part0 :BasePart, part1 :BasePart = motor.Part0 :: BasePart, motor.Part1 :: BasePart;
	motor:Destroy();
	if self.JointsDestroyed == nil then
		self.JointsDestroyed = {};
	end;
	self.JointsDestroyed[motor.Name] = true;

	local assemblyRoots = {};
	if part0 then
		table.insert(assemblyRoots, part0.AssemblyRootPart);
	end
	if part1 then
		table.insert(assemblyRoots, part1.AssemblyRootPart);
	end
	
	for a=1, #assemblyRoots do
		if assemblyRoots[a] == self.RootPart then continue end;
		
		local assemblyRoot = assemblyRoots[a];
		local connParts = assemblyRoot:GetConnectedParts(true);
		
		for b=1, #connParts do
			if self.Prefab:IsAncestorOf(connParts[b]) then continue end;
			table.remove(connParts, b);
		end
		
		task.spawn(function()
			table.insert(connParts, assemblyRoot);
			
			for _, bodyPart in pairs(connParts) do
				bodyPart.CanCollide = true;

				if bodyPart:FindFirstChild("WeakpointTarget") then
					bodyPart.WeakpointTarget:Destroy();
				end
			end
			
			task.wait(1);
			modPhysics.WaitForSleep(assemblyRoot);
			
			if workspace:IsAncestorOf(assemblyRoot) then
				for _, bodyPart :BasePart in pairs(connParts) do
					bodyPart.Anchored = true;
					bodyPart.CanCollide = false;
					bodyPart.CanQuery = false;
					bodyPart:SetAttribute("IgnoreWeaponRay", true);
				end
			end
		end)
		
		break;
	end
	
	return assemblyRoots;
end

function NpcComponent:Destroy()
	if self.IsDestroyed then return end;
	self.IsDestroyed = true;
	
	task.delay(10, function()
		for key, _ in pairs(self) do
			if SafeKeys[key] == nil then
				if typeof(self[key]) == "table" then
					if self[key].Destroy then
						self[key]:Destroy();
					end
				end

				self[key] = nil;
			end
		end

	end)

	self:KillNpc();

	if self.Garbage then
		local garbage = self.Garbage;
		self.Garbage = nil;
		garbage:Destruct();
	end
	if self.Logic then
		self.Logic:ClearAll();
		for k,_ in pairs(self.Logic) do
			self.Logic.Actions[k] = nil;
		end
	end

	self.Think:Destroy();
	self.Status = nil;
	setmetatable(self, {__mode="kv"; __index=getmetatable(self)});

end

function NpcComponent:AddDialogueInteractable()
	if self.Prefab:FindFirstChild("Interactable") == nil then
		local new = script.Interactable:Clone();
		new.Parent = self.Prefab;
	end
end

function NpcComponent:ToggleInteractable(value)
	if self.Interactable == nil then 
		self.Interactable = self.Prefab:FindFirstChild("Interactable");
	end;
	if self.Interactable == nil then return end;

	self.Interactable.Name = value and "Interactable" or "InteractableDisabled";
end

function NpcComponent:SetNetworkOwner(value, lock)
	if typeof(value) == "Instance" and not value:IsA("Player") then return end;
	if self.LockNo == true then return end;
	if lock then self.LockNo = true end;

	local rootPart: BasePart = self.RootPart;
	local function setNO(v)
		if not rootPart:CanSetNetworkOwnership() then return end;

		if v == "auto" then
			local players = game.Players:GetPlayers();
			if #players > 0 then
				local closestDist, closestPlayer = math.huge, nil;
				for a=1, #players do
					local playerDist = players[a]:DistanceFromCharacter(rootPart.Position);
					if playerDist < closestDist then
						closestDist = playerDist;
						closestPlayer = players[a];
					end
				end
				
				rootPart:SetNetworkOwner(closestPlayer);
				
			else
				rootPart:SetNetworkOwnershipAuto();
				
			end
			
		else
			rootPart:SetNetworkOwner(v);

		end
	end

	if not workspace:IsAncestorOf(rootPart) then return end;
	if self.IsDestroyed then return end;

	setNO(value);
end

function NpcComponent:SendActorMessage(...)
	if self.Actor == nil then return end;
	if not workspace:IsAncestorOf(self.Prefab) then return end;
	self.Prefab:SendMessage(...);
end

function NpcComponent:DamageTarget(model, damage, character, dmgSrc, dmgCate)
	if self.Humanoid == nil or self.Humanoid.Health <= 0 or self.IsDead then return end;
	local player = game.Players:GetPlayerFromCharacter(character);

	if self.NetworkOwners then
		if player then
			if table.find(self.NetworkOwners, player) == nil then
				return;
			end
		end
	end

	local visibleParts = {};
	for _, obj in pairs(model:GetChildren()) do
		if obj:IsA("BasePart") and obj.Transparency <= 0.1 then
			table.insert(visibleParts, obj);
		end
	end

	local damagable = modDamagable.NewDamagable(model);
	if damagable then
		dmgSrc = dmgSrc or modDamagable.NewDamageSource{};

		dmgSrc.Damage = damage;
		dmgSrc.DamageCate = dmgCate;
		dmgSrc.Dealer = self.Prefab;
		dmgSrc.TargetModel = model;
		dmgSrc.TargetPart = (#visibleParts > 0 and visibleParts[math.random(1, #visibleParts)] or nil);

		damagable:TakeDamagePackage(dmgSrc);
	end
end

function NpcComponent:Teleport(cframe: CFrame, cfAngle: CFrame)
	if self.Humanoid and self.Humanoid.SeatPart and self.Humanoid.SeatPart:FindFirstChild("SeatWeld") then 
		self.Humanoid.SeatPart.SeatWeld:Destroy();
	end
	if cframe then
		local cfAng = cframe.Rotation;
		if cfAng == CFrame.Angles(0, 0, 0) then
			cfAng = self.RootPart.CFrame.Rotation;
		end
		if cfAngle then
			cfAng = cfAngle;
		end
		self.RootPart.CFrame = CFrame.new(cframe.Position) * cfAng;
		
	else
		if self.Owner and self.Owner.Character and self.Owner.Character.PrimaryPart and self.Owner.Character.PrimaryPart:IsDescendantOf(workspace) then
			self.RootPart.CFrame = self.Owner.Character.PrimaryPart.CFrame;
		end
	end
end

function NpcComponent:TeleportHide()
	Debugger:Warn("TeleportHide> "..self.Name);
	if self.Humanoid and self.Humanoid.SeatPart and self.Humanoid.SeatPart:FindFirstChild("SeatWeld") then 
		self.Humanoid.SeatPart.SeatWeld:Destroy();
	end
	if self.RootPart and self.RootPart:IsDescendantOf(workspace) then
		self.RootPart.CFrame = CFrame.new(10000, 270, 10000);
	end
	if self.Follow then
		self.Follow();
	end
end

function NpcComponent:GetHealth(valueType: string, bodyPart: BasePart)
	if bodyPart and self.CustomHealthbar then
		local healthObj = self.CustomHealthbar:GetFromPart(bodyPart);
		if healthObj then
			if valueType == "MaxHealth" then
				return healthObj.MaxHealth;
			end
			return healthObj.Health;
		end
	end
	
	if valueType == "MaxHealth" then
		return self.Humanoid.MaxHealth;
	end
	return self.Humanoid.Health
end
--==

-- MARK: NpcModule Type
export type NpcModule = {
	Name: string;
	IsDead: boolean;

	Prefab: Model | Actor;
	RootPart: BasePart;
	Head: BasePart;
	Humanoid: Humanoid;

	Actor: Actor?;
	ActorEvent: BindableEvent;

	PathAgent: {[any]: any};

	Think: modEventSignal.EventSignal;
	Garbage: modGarbageHandler.GarbageHandler;

	EntityStatus: modEntityStatus.EntityStatus;

	Properties: {};
	JointRotations: {
		WaistRot: modLayeredVariable.LayeredVariable;
		NeckRot: modLayeredVariable.LayeredVariable;
	};

	LastDamageTaken: number;

	[any]: any;
} & typeof(NpcComponent);

--& typeof(NpcComponent);

return function(self) : NpcModule
	self.Name = self.Prefab.Name;
	self.Head = self.Prefab:FindFirstChild("Head") :: BasePart;
	self.Humanoid = self.Prefab:FindFirstChildWhichIsA("Humanoid") :: Humanoid;
	self.RootPart = self.Humanoid.RootPart :: BasePart;

	self.Actor = self.Prefab:GetActor();
	self.Think = modEventSignal.new(self.Name.."Think");

	local actorEvent: BindableEvent = Instance.new("BindableEvent");
	actorEvent.Name = "ActorEvent";
	actorEvent.Parent = self.Prefab;
	self.ActorEvent = actorEvent;
	
	local isHuman = self.Humanoid.Name == "Human"
	
	self.PathAgent = {
		AgentRadius=1;
		AgentHeight=6;
		
		AgentCanClimb=true;
		
		WaypointSpacing = math.huge;--isHuman and 4 or 10;
		
		Costs={
			Climb = 4;
			Water = 10;
			Avoid = 10;
			Barricade = 100;
			DefinePath = isHuman and 0.25 or 0.5;
			Walkway = isHuman and 0.5 or 0.75;
			Slowpath = isHuman and 2 or nil;
			DoorPortal = isHuman and 1 or nil;
		};
	};
	
	self.Garbage = modGarbageHandler.new();

	if self.Properties == nil then
		self.Properties = {};
	end
	self.EntityStatus = modEntityStatus.new(self.Properties);
	
	self.LastDamageTaken = tick();
	
	self.JointRotations = {
		WaistRot = modLayeredVariable.new(0);
		NeckRot = modLayeredVariable.new(0);
	};
	
	self.JointRotations.WaistRot.Changed:Connect(function()
		local value = self.JointRotations.WaistRot:Get();
		local NpcWaist = self.Prefab and self.Prefab:FindFirstChild("Waist", true);
		if NpcWaist then
			NpcWaist.C1 = CFrame.new(NpcWaist.C1.p) * CFrame.Angles(0, value, 0);
			NpcWaist.Parent:SetAttribute("WaistRot", value);
		end
	end)
	self.JointRotations.NeckRot.Changed:Connect(function()
		local value = self.JointRotations.NeckRot:Get();
		local NpcNeck = self.Prefab and self.Prefab:FindFirstChild("Neck", true);
		if NpcNeck then
			NpcNeck.C0 = CFrame.new(NpcNeck.C0.p) * CFrame.Angles(0, value, 0);
		end
	end)
	
	setmetatable(self, NpcComponent);
	-- initialized;
	self.Garbage:Tag(function()
		for _, jointLV in pairs(self.JointRotations) do
			jointLV:Destroy();
		end
	end)
	
	self:AddComponent("Move");
	self:AddComponent("ThreatSense");
	self:AddComponent("StatusLogic");
	self:AddComponent("BehaviorTree");
	
	if modConfigurations.SpecialEvent.Christmas then
		self:AddComponent("Christmas")();
	end
	
	if self.Prefab:GetAttribute("HasRagdoll") == true then
		self:AddComponent("Ragdoll")();
	end
	
	return self;
end