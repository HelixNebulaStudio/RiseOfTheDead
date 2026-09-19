local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

local templatePotArmors
function Component.onRequire()
	templatePotArmors = game.ServerStorage.Prefabs.Objects:WaitForChild("PotArmor"):GetChildren();
end

function Component.new(npcClass: NpcClass)
	local self = {
		NpcClass = npcClass;
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:Setup()
	local npcClass: NpcClass = self.NpcClass;

	local bodyDestructiblesComp =  npcClass:AddComponent("BodyDestructibles");
	local npcChar = npcClass.Character;

	local armorPickPart = templatePotArmors[math.random(1, #templatePotArmors)]
	local armorAtt: Attachment = armorPickPart:FindFirstChildWhichIsA("Attachment");

	local charAtt = npcChar:FindFirstChild(armorAtt.Name, true);
	if charAtt == nil then Debugger:StudioWarn(`{npcChar.Name} does not have {armorAtt.Name} for PotArmor.`);
		return; 
	end;
	
	armorPickPart = armorPickPart:Clone();
	armorAtt = armorPickPart:WaitForChild(armorAtt.Name);

	local armorModel = Instance.new("Model");
	armorModel.Name = "PotArmor";
	armorPickPart.Name = "PrimaryPart";
	armorPickPart.Parent = armorModel;
	armorModel.PrimaryPart = armorPickPart;

	armorModel.Parent = npcChar;

	if armorAtt.Name == "HatAttachment" then
		armorAtt.Orientation = Vector3.new(0, math.random(0, 360), 0);
	end

	local rigidConstraint = Instance.new("RigidConstraint");
	rigidConstraint.Attachment0 = charAtt;
	rigidConstraint.Attachment1 = armorAtt;
	rigidConstraint.Parent = armorPickPart;

	local destructible: DestructibleInstance = bodyDestructiblesComp:Create("PotArmor", armorModel);
	destructible.Name = "Pot Armor";
	destructible.HealthComp:SetMaxHealth((npcClass.Properties.Level or 1) * 600);
end

return Component;