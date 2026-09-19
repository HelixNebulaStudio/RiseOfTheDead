local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

function Component.new(npcClass: NpcClass)
	local self = {
		NpcClass = npcClass;
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:__call(pathFindingLink: PathfindingLink, position: Vector3)
	if pathFindingLink == nil 
	or pathFindingLink.Parent == nil
	or pathFindingLink.Parent.Parent == nil then
		return;
	end;
	
	local doorConfig = pathFindingLink.Parent.Parent:FindFirstChild("Door");
	if doorConfig == nil or not doorConfig:IsA("Configuration") then return end;

	local doorInstance: DoorInstance = modDoors.getOrNew(doorConfig);
	if doorConfig:GetAttribute("DoorOpen") == true then return end;

	local interactConfig = pathFindingLink.Parent.Parent:FindFirstChild("Interactable");
	if interactConfig == nil or not interactConfig:IsA("Configuration") then return end;
	
	local properties = self.NpcClass.Properties;
	local humanoidType = self.NpcClass.HumanoidType;

	if humanoidType ~= "Zombie" then
		-- Human use door
		self.NpcClass:UseInteractable(interactConfig);
		return;	
	end

	local obstacleHandler = self.NpcClass:GetComponent("MoveObstacleHandler");
	if obstacleHandler then
		obstacleHandler{
			InteractConfig = interactConfig;
		};
	end
end

return Component;