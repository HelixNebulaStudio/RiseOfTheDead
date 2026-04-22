local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClothingLibrary = shared.require(game.ReplicatedStorage.Library.ClothingLibrary);

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

function Component:__call(maxArmor)
	local npcClass: NpcClass = self.NpcClass;
	local npcChar = npcClass.Character;

	if npcClass.HumanoidType == "Zombie" then
		npcClass.Properties.PresetShirt = {Id="rbxassetid://9686627232"};
		npcClass.Properties.PresetPants = {Id="rbxassetid://1106996955"};
		npcClass:UpdateClothing();
	end

	local armorModel = Instance.new("Model");
	armorModel.Name = "Armor";
	armorModel.Parent = npcChar;

	local healthComp: HealthComp = self.NpcClass.HealthComp;
	healthComp:SetMaxArmor(maxArmor);
	healthComp:SetArmor(maxArmor);

	healthComp.OnArmorChanged:Connect(function(curArmor, oldArmor, damageData)
		if curArmor > 0 then return end;

		for _, obj in pairs(armorModel:GetDescendants()) do
			if obj:IsA("Weld") then obj:Destroy(); end;
			if obj:IsA("BasePart") then obj.CanCollide = true; end;
		end
		armorModel.Parent = workspace.Debris;
		game.Debris:AddItem(armorModel, 10);
	end)

	local banditarmorLib = modClothingLibrary:Find("banditarmor");
	for _, accessory in pairs(banditarmorLib.Accessories) do
		local handle = accessory:WaitForChild("Handle");
		local att = handle:FindFirstChildWhichIsA("Attachment");
		if att == nil then continue; end;

		local bodyAtt = npcChar:FindFirstChild(att.Name, true);
		if bodyAtt == nil then continue; end;

		local newHandle = handle:Clone();
		att = newHandle:WaitForChild(bodyAtt.Name);
		newHandle.CanCollide = false;
		newHandle.CanQuery = false;
		newHandle.Parent = armorModel;

		local bodyPart = bodyAtt.Parent;

		local weld = Instance.new("Weld");
		weld.Parent = newHandle;
		weld.Part0 = bodyPart;
		weld.Part1 = newHandle;
		weld.C0 = bodyAtt.CFrame;
	end
end

return Component;