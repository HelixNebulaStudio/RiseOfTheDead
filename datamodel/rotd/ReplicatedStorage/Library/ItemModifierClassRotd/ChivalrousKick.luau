local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);
local modStatusLibrary = shared.require(game.ReplicatedStorage.Library.StatusLibrary);
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local modifierPackage = {
	Name = "Chivalrous Kick";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.onRequire()
	modStatusLibrary:Add(modStatusClass.new{
		Id = "ChivalrousKick";
	});
end

function modifierPackage.Kick(modifier: ItemModifierInstance, targetModel)
	if modifier.WieldComp == nil then return end;
	local ownerClass: CharacterClass = modifier.WieldComp.CompOwner;

	local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
	if healthComp == nil or healthComp.IsDead then return end;
	targetModel = healthComp:GetModel();

	local targetClass: CharacterClass = healthComp.CompOwner;
	if targetClass.ClassName ~= "NpcClass" then return end;

	if targetClass.HealthComp:CanTakeDamageFrom(ownerClass) == false then return end;

	local statusComp: StatusComp? = targetClass.StatusComp;
	if statusComp == nil then return end;

	local statusClass: StatusClassInstance? = statusComp:GetOrDefault("ChivalrousKick");
	if statusClass then return end;

	statusComp:Apply("ChivalrousKick", {
		Expires = workspace:GetServerTimeNow() + 3;
		Duration = 3;
		ApplyBy = ownerClass;
		Values = {};
	});

	local rootPart: BasePart = targetModel.PrimaryPart;
	if rootPart and rootPart.Anchored ~= true then
		local position = ownerClass:GetCFrame().Position;
		local dir = (rootPart.Position-position).Unit;
		
		local dForce = dir * 200;

		local knockbackResistance = targetClass.Configurations.KnockbackResistant or 0;
		if targetClass.HealthComp.CurArmor <= 0 and knockbackResistance < 1 then
			targetClass.StatusComp:Apply("ExplosionRagdoll", {
				Expires = workspace:GetServerTimeNow() + 1;
				Values = {
					Ragdoll=true;
				}
			});
		end

		if knockbackResistance < 1 then
			rootPart:ApplyImpulse(dForce 
				* rootPart.AssemblyMass 
				* (1-knockbackResistance)
			);
		end
	end
end

function modifierPackage.Binds.CharacterClassPropertiesChanged(modifier: ItemModifierInstance, propertyName: string, isSliding: boolean)
	if propertyName ~= "IsSliding" then return end;
	if modifier.WieldComp == nil then return end;

	local ownerClass: CharacterClass = modifier.WieldComp.CompOwner;
	if isSliding == false then return end

	task.spawn(function()
		local r = 8;

		while ownerClass.Properties.IsSliding == true do
			local pos = ownerClass.RootPart.Position;
			local lookVec = ownerClass:GetCFrame().LookVector;

			local overlapParams = OverlapParams.new();
			overlapParams.FilterType = Enum.RaycastFilterType.Include;
			overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("Enemies");
			overlapParams.MaxParts = 8;

			local rootParts = workspace:GetPartBoundsInRadius(pos + lookVec*(r/2), r, overlapParams);

			for a=1, #rootParts do
				modifierPackage.Kick(modifier, rootParts[a].Parent);
			end

			task.wait(0.1);
		end
	end)
end


return modifierPackage;