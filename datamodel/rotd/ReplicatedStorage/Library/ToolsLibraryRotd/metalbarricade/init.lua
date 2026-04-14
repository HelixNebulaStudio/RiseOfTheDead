local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
--==

local toolPackage = {
	ItemId = script.Name;
	Class = "Tool";
	HandlerType = "StructureTool";

	Animations = {
		Core={Id=4379418967;};
		Placing={Id=4379471624};
	};
	Audio = {};

	Configurations = {
		WaistRotation = math.rad(85);
		PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
		
		BuildDuration = 1;
	};

	Properties = {};
};

function toolPackage.BuildStructure(prefab: Model, optionalPacket)
	optionalPacket = optionalPacket or {};

	if modConfigurations.ExpireDeployables == true then
		Debugger.Expire(prefab, 300);
	end
	
	modAudio.Play("Repair", prefab.PrimaryPart);
	
	local size = prefab:GetExtentsSize();
	local enemyClip = Instance.new("Part");
	enemyClip.Name = "_enemyClip";
	enemyClip.Anchored = true;
	enemyClip.CanCollide = true;
	enemyClip.Transparency = 1;
	enemyClip.Size = Vector3.new(1, size.Y+2, size.Z+0.2);
	enemyClip.CFrame = prefab:GetPivot() * CFrame.new(-1, 4, 0);
	local pathfindingMod = Instance.new("PathfindingModifier");
	pathfindingMod.Label = "Destructible";
	pathfindingMod.PassThrough = true;
	pathfindingMod.Parent = enemyClip;
	enemyClip.Parent = workspace.Clips;
	
	prefab.Destroying:Connect(function()
		enemyClip:Destroy();
	end)
	
	local destructibleConfig = modDestructibles.createDestructible("Generic");
	destructibleConfig:SetAttribute("MaxHealth", 3000);
	destructibleConfig:SetAttribute("DebrisName", prefab.Name);
	destructibleConfig.Parent = prefab;

	local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
	destructible.HealthComp.OnIsDeadChanged:Connect(function(isDead)
		if not isDead then return end;
		Debugger.Expire(enemyClip, 0);
	end)

	local hitBox: BasePart = prefab:WaitForChild("Hitbox") :: BasePart;
	hitBox.Touched:Connect(function(hitPart)
		if not workspace.Entity:IsAncestorOf(hitPart) 
		or not workspace.Entity:IsAncestorOf(hitPart.Parent) then return end;
		local hitParent = hitPart.Parent;

		local healthComp: HealthComp? = modHealthComponent.getByModel(hitParent);
		if healthComp == nil or healthComp.CompOwner.ClassName ~= "NpcClass" then return end;
		
		local npcClass: NpcClass = healthComp.CompOwner :: NpcClass;
		local targetHandlerComp = npcClass:GetComponent("TargetHandler");

		targetHandlerComp:AddTarget(destructible.Model);
	end)

end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;