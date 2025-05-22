local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==
local touchHandler = modTouchHandler.new("BarbedFence", 1);

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="StructureTool";

	Animations={
		Core={Id=4379418967;};
		Placing={Id=4379471624};
	};
	Audio={};

	Configurations={
		WaistRotation = math.rad(0);
		PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
		
		BuildDuration = 1;
		BuildAvoidTags = {"TrapStructures"};
	};

	Properties={};
};

function toolPackage.OnSpawn(handler: ToolHandlerInstance, prefab: Model)
	prefab:AddTag("TrapStructures");

	if modConfigurations.ExpireDeployables == true then
		Debugger.Expire(prefab, 300);
	end
	
	local modDestructible = shared.require(prefab:WaitForChild("Destructible"));
	modAudio.Play("Repair", prefab.PrimaryPart);
	
	local debris = prefab:WaitForChild("debris");
	local hitbox = debris:WaitForChild("Hitbox");
	hitbox.Anchored = true;
	
	debris.Parent = workspace.Entities;

	prefab.Destroying:Connect(function()
		debris:Destroy();
		Debugger.Expire(debris, 0);
	end)
	prefab:GetAttributeChangedSignal("Destroyed"):Connect(function()
		if prefab:GetAttribute("Destroyed") ~= true then return end;

		Debugger.Expire(hitbox, 0);
		for _, obj in pairs(debris:GetChildren()) do
			if not obj:IsA("BasePart") then continue end
			obj.CanCollide = true;
			obj.Anchored = false;
		end

	end)
	touchHandler:AddObject(hitbox);
	
	function touchHandler:OnHumanoidTouch(humanoid, basePart, hitPart)
		local targetModel = hitPart.Parent;
		if targetModel == nil or not targetModel:IsA("Model") then return end;
	
		local characterClass: CharacterClass = handler.CharacterClass;
		local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
		if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(characterClass) then return end;

		local damage = math.clamp(healthComp.MaxHealth * 0.001, 10, math.huge);
		local dmgData = DamageData.new{
			Damage=damage;
			DamageBy=characterClass;
			ToolStorageItem=handler.StorageItem;
			TargetPart=hitPart;
		}
		healthComp:TakeDamage(dmgData);
	
		local statusComp: StatusComp? = healthComp.CompOwner.StatusComp;
		if statusComp == nil then return end;
		
		statusComp:Apply("BarbWireSlow", {
			Expires = workspace:GetServerTimeNow()+2;
			SlowValue = 4;
		});
	
		modDestructible:TakeDamage(DamageData.new{
			Damage=30;
		});
	end
end;

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;