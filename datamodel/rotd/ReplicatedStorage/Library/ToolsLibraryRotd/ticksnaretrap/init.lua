local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = require(game.ReplicatedStorage.Components.HealthComponent);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="StructureTool";

	Animations={
		Core={Id=16350759475;};
		Placing={Id=10964648124};
	};
	Audio={};
	Configurations={
		PlaceOffset = CFrame.Angles(0, 0, 0);

		Prefab = script:WaitForChild("TicksSnareTrap");
		BuildDuration = 1;

		BuildAvoidTags = {"TrapStructures"}
	};
	Properties={};
};

function toolPackage.OnSpawn(handler: ToolHandlerInstance, prefab: Model)
	prefab:AddTag("TrapStructures");

	if modConfigurations.ExpireDeployables == true then
		Debugger.Expire(prefab, 300);
	end

	local nailAtts = {};
	for _, obj in pairs(prefab:GetChildren()) do
		if obj.Name == "Nail" then
			table.insert(nailAtts, obj:WaitForChild("Attachment"));
		end
	end
	modAudio.Play("Repair", prefab.PrimaryPart);

	local collider = prefab:WaitForChild("Collider") :: BasePart;
	local ropePart = prefab:WaitForChild("Rope") :: BasePart;

	local activeLeashes = {};

	local useCount = 5;
	collider.Touched:Connect(function(hitPart)
		local targetModel = hitPart.Parent;
		if targetModel == nil then return end;
		if not targetModel:IsA("Model") or targetModel.Name ~= "Ticks" then return end;

		local characterClass: CharacterClass = handler.CharacterClass;
		local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
		if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(characterClass) then return end;

		local compOwner = healthComp.CompOwner;
		local statusComp: StatusComp? = compOwner.StatusComp;
		if statusComp == nil then return end;

		local leashedStatus = statusComp:GetOrDefault("Leashed");
		if leashedStatus then return end;

		if useCount <= 0 then return end;
		useCount = useCount -1;

		statusComp:Apply("Leashed", {});
		ropePart.Transparency = useCount <= 0 and 1 or 0;

		local furthestNail, furthestDist = nil, 0;
		for _, nailAtt in pairs(nailAtts) do
			local dist = (hitPart.Position-nailAtt.WorldCFrame.Position).Magnitude;

			if dist > furthestDist then
				furthestDist = dist;
				furthestNail = nailAtt;
			end
		end

		local att = Instance.new("Attachment");
		att.Parent = hitPart;

		local newLeash = Instance.new("RopeConstraint");
		newLeash.Parent = hitPart;
		newLeash.Visible = true;

		newLeash.Length = 4;
		newLeash.Attachment0 = furthestNail;
		newLeash.Attachment1 = att;
		table.insert(activeLeashes, newLeash);

		newLeash.Destroying:Connect(function()
			for a=#activeLeashes, 1, -1 do
				local leash = activeLeashes[a];
				if leash == newLeash then
					table.remove(activeLeashes, a);
				end
			end
			if #activeLeashes <= 0 then
				game.Debris:AddItem(prefab, 1);
			end
		end)

		repeat task.wait() until healthComp.IsDead;
		newLeash:Destroy();
	end)
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;