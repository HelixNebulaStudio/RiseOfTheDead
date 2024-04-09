local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Doors = {};
Doors.__index = Doors;
Doors.Types = {
	Normal="Normal";
	Sliding="Sliding";
}


Doors.ClassName = "Doors";
Doors.Type = Doors.Types.Normal;

local PhysicsService = game:GetService("PhysicsService");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

local remoteDoorInteraction = modRemotesManager:Get("DoorInteraction");

local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
--== Script;
function Doors:Init()
	
end

function Doors:HasAccess(player)
	if self.Script:GetAttribute("Locked") == false then return true end;
	if self.Public then return true; end;
	
	local name;
	if player:IsA("Player") then
		name = player.Name;
	else
		name = "npc_"..player.Name;
	end
	
	local doorAttributes = self.Script:GetAttributes();
	for attKey, attVal in pairs(doorAttributes) do
		if attKey:match("AccessName") and attVal == name then
			return true;
		end
	end
	return false;
end

function Doors:SetAccess(player, value)
	local name;
	if player:IsA("Player") then
		name = player.Name;
	else
		name = "npc_"..player.Name;
	end
	
	if value == true then
		self.Script:SetAttribute("AccessName_"..name, name);
		
	else
		self.Script:SetAttribute("AccessName_"..name, nil);
		
	end
end

function Doors:PlaySlam(playbackSpeed)
	if self.Sounds.Slam then
		modAudio.Play(self.Sounds.Slam, self.Prefab.PrimaryPart).PlaybackSpeed = playbackSpeed;
	end
end

function Doors:Toggle(value, openerCFrame, player)
	if RunService:IsClient() then return end;
	
	if value ~= nil then
		if self.Open == value then return end;
		self.Open = value; 
		
	else
		self.Open = not self.Open;
		
	end;
	
	self.Script:SetAttribute("DoorOpen", self.Open);
	
	self.OnDoorToggle:Fire(player);
	
	if self.ActiveSound then
		self.ActiveSound:Stop();
	end
	if self.Sounds.Toggle then
		self.ActiveSound = modAudio.Play(self.Sounds.Toggle, self.Prefab.PrimaryPart);
	end
	
	local isBehind = false;
	if openerCFrame then
		local dirAngle = modGlobalVars.GetAngleFront(self.Prefab.PrimaryPart.CFrame, openerCFrame);
		isBehind = not (dirAngle < 90 and dirAngle > -90);
	end
	
	local doorMotors = {}
	for _, obj in pairs(self.Prefab.PrimaryPart:GetChildren()) do
		if obj:IsA("Motor6D") and obj.Name:match("Door") then
			table.insert(doorMotors, obj);
		end
	end
	
	for a=1, #doorMotors do
		local dMotor = doorMotors[a];
		
		local doorPrefab = dMotor.Part1.Parent;
		
		local pathfindingMods = {};
		for _, obj in pairs(doorPrefab:GetDescendants()) do
			if obj:IsA("BasePart") and obj.CanCollide == true then
				local pathfindingMod = obj:FindFirstChildWhichIsA("PathfindingModifier");
				if pathfindingMod == nil then
					pathfindingMod = Instance.new("PathfindingModifier");
					pathfindingMod.Label = "Doorway";
					pathfindingMod.Parent = obj;
				end
				
				table.insert(pathfindingMods, pathfindingMod);
			end
		end
		
		local tweenObject;
		local newC1;
		
		if self.Type == Doors.Types.Normal then
			local invert = dMotor.Name == "DoorRBase" and 1 or -1;
			
			invert = invert * (isBehind and 1 or -1);
			
			newC1 = CFrame.Angles(0, self.Open and math.rad(self.OpenAngle or (invert*90)) or 0, 0);
			tweenObject = TweenService:Create(dMotor, self.TweenInfo or tweenInfo, {C1=newC1;});
			
		elseif self.Type == Doors.Types.Sliding then
			local invert = dMotor.Name == "DoorRBase" and 1 or -1;
			
			if self.SlideOneDoorOnly then
				if self.Open then
					if (isBehind and a > 1) or (not isBehind and a <= 1) then
						newC1 = self.OpenCFrame or CFrame.new(0, 0, -3.83);
						tweenObject = TweenService:Create(dMotor, self.TweenInfo or tweenInfo, {C1=newC1});
						
					end

				else
					-- close;
					newC1 = CFrame.new(0,0,0);
					tweenObject = TweenService:Create(dMotor, self.TweenInfo or tweenInfo, {C1=newC1});

				end
				
			else
				newC1 = (self.Open and (self.OpenCFrame or CFrame.new(0, 0, -3.83)) or CFrame.new(0,0,0));
				tweenObject = TweenService:Create(dMotor, self.TweenInfo or tweenInfo, {C1=newC1});
				
			end
		end
		
		if not self.Open then
			for a=1, #pathfindingMods do
				pathfindingMods[a].PassThrough = true;
			end
		end
		
		if tweenObject then
			tweenObject.Completed:Once(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					task.defer(function()
						dMotor.C1 = newC1;
					end)
					
					if self.Open then
						for a=1, #pathfindingMods do
							pathfindingMods[a].PassThrough = false;
						end
					end
				end
			end)
			
			tweenObject:Play();
		end
	end
end

function Doors:RequestDoorToggle()
	if RunService:IsClient() then
		remoteDoorInteraction:FireServer(self.Prefab);
	end
end

function Doors:GetDoor(prefab)
	local doorModule = prefab:FindFirstChild("Door");
	local modDoor = doorModule and doorModule:IsA("ModuleScript") and require(doorModule);
	return modDoor;
end

function Doors.new(prefab)
	local self = {
		Open = false;
		Prefab = prefab;
		Script = prefab:WaitForChild("Door");
		InstanceCache = {};
		OnDoorToggle = modEventSignal.new("OnDoorToggle");
		Sounds = {};
		
		WidthType=(prefab:GetExtentsSize().X > 9) and "Double" or "Single";
	};
	
	Debugger.Expire(prefab:FindFirstChild("NavMeshIgnore"), 0);
	
	if RunService:IsClient() then
		self.Script:GetAttributeChangedSignal("DoorOpen"):Connect(function()
			if self.Interactable then
				self.Interactable:Trigger();
			end
		end)
		
	else
		self.Script:GetAttributeChangedSignal("DoorOpen"):Connect(function()
			if self.Script:GetAttribute("DoorOpen") ~= self.Open then
				self:Toggle(self.Script:GetAttribute("DoorOpen"));
			end
		end)
		
	end
	
	for a=1, 60 do
		if self.Prefab.PrimaryPart == nil then task.wait() else break; end;
	end
	
	if self.CustomSound then
		if self.Sounds.Toggle == nil then self.Sounds.Toggle = self.CustomSound end;
		
	elseif self.Prefab.PrimaryPart.Material == Enum.Material.WoodPlanks or self.Prefab.PrimaryPart.Material == Enum.Material.Wood then
		if self.Sounds.Toggle == nil then self.Sounds.Toggle = "WoodDoorOpen" end;
		if self.Sounds.Slam == nil then self.Sounds.Slam = "WoodSlam" end;
		
	elseif self.Prefab.PrimaryPart.Material == Enum.Material.Metal then
		if self.Sounds.Toggle == nil then self.Sounds.Toggle = "MetalDoorOpen" end;
		if self.Sounds.Slam == nil then self.Sounds.Slam = "MetalSlam" end;
		
	elseif self.Prefab.PrimaryPart.Material == Enum.Material.DiamondPlate then
		if self.Sounds.Toggle == nil then self.Sounds.Toggle = "HeavyMetalDoor" end;
		if self.Sounds.Slam == nil then self.Sounds.Slam = "MetalSlam" end;

	elseif self.Prefab.PrimaryPart.Material == Enum.Material.Glass then
		if self.Sounds.Toggle == nil then self.Sounds.Toggle = "GlassDoorToggle" end;
		if self.Sounds.Slam == nil then self.Sounds.Slam = "GlassDoorSlam" end;
		
	end
	
	setmetatable(self, Doors);
	return self;
end

if RunService:IsServer() then
	remoteDoorInteraction.OnServerEvent:Connect(function(player, prefab)
		local modDoor = Doors:GetDoor(prefab);
		if modDoor and modDoor:HasAccess(player) then
			local allowToggle = true;
			
			local keyItemId = prefab:GetAttribute("KeyRequired");
			if keyItemId then
				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;

				local total, itemList = inventory:ListQuantity(keyItemId, 1);
				if total > 0 then
					local storageItem = inventory:Find(itemList[1].ID);
					
					if storageItem.Values.Uses > 1 then
						inventory:SetValues(storageItem.ID, {Uses=storageItem.Values.Uses-1});
						
					else
						inventory:Remove(storageItem.ID, 1);
						
					end
					prefab:SetAttribute("KeyRequired", nil);
					modAudio.Play("KeyLock", prefab.PrimaryPart).PlaybackSpeed = 2;
					
				else
					allowToggle = false;
					
				end
			end
			
			if allowToggle then
				modDoor:Toggle(nil, player and player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.CFrame, player);
			end
		end
	end);
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(Doors); end

return Doors;