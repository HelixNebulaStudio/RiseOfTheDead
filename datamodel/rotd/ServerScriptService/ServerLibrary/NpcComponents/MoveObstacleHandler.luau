local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
local modPseudoRandom = shared.require(game.ReplicatedStorage.Library.PseudoRandom);

--==
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

function Component:__call(packet: anydict)
	local npcClass = self.NpcClass;
	local properties = self.NpcClass.Properties;
	local humanoidType = self.NpcClass.HumanoidType;

	local moveDirection: Vector3 = packet.MoveDirection;
	local obstacleRayresult: RaycastResult = packet.ObstacleRayresult;
	local interactConfig: Configuration = packet.InteractConfig;


	if packet.LongStuck == true and humanoidType == "Zombie" then
		local dir;

		if moveDirection then
			dir = -moveDirection;
		elseif obstacleRayresult and obstacleRayresult.Normal then
			dir = -obstacleRayresult.Normal;
		elseif obstacleRayresult and obstacleRayresult.Position then
			dir = (npcClass.RootPart.Position - obstacleRayresult.Position).Unit;
		end

		local assemblyRootPart = npcClass.Character.PrimaryPart;
		assemblyRootPart:ApplyImpulse(dir * assemblyRootPart.AssemblyMass * 50);
	end


	if interactConfig == nil then
		if obstacleRayresult == nil or obstacleRayresult.Instance == nil then return end;

		interactConfig = modInteractables.findInteractConfig(obstacleRayresult.Instance);
	end
	if interactConfig == nil then return end;

	local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
	if interactable == nil then return end;

	if interactable.Type == "Door" and interactable.Values.DoorConfig then
		local doorConfig = interactable.Values.DoorConfig;

		local doorInstance: DoorInstance = modDoors.getOrNew(doorConfig);
		if doorConfig:GetAttribute("DoorOpen") == true then return end;

		if humanoidType ~= "Zombie" then
			npcClass:UseInteractable(interactConfig);
			return;
		end

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

end

return Component;