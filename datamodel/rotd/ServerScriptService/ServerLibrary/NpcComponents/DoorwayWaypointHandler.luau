local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modPseudoRandom = shared.require(game.ReplicatedStorage.Library.PseudoRandom);

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;
Component.BreakDoorRandom = modPseudoRandom.new();

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

	local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
	if interactable == nil then return end;
	
	local breakDoorChance = 0.1;

	local hasPerm = interactable:HasPermissions("CanInteract", self.NpcClass.Name);
	if hasPerm == false and properties.EnemyTargetData then
		local enemyHealthComp = properties.EnemyTargetData.HealthComp;
		local enemyNpcClass: NpcClass = enemyHealthComp and enemyHealthComp.CompOwner;
		
		if enemyNpcClass then
			hasPerm = interactable:HasPermissions("CanInteract", enemyNpcClass.Name);
		end
	end
	
	local brokeDoor = self.BreakDoorRandom:PrdRandom(nil, breakDoorChance);
	
	self.NpcClass.PlayAnimation("WallSlam");

	if not hasPerm or not brokeDoor then
		doorInstance:PlaySlam(math.random(130,160)/100);
		return;
	end

	doorInstance:PlaySlam();
	doorInstance:Toggle(true, self.NpcClass:GetCFrame());
end

return Component;