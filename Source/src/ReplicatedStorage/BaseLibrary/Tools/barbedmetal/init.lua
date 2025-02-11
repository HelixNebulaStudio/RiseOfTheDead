local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
--==
local touchHandler = modTouchHandler.new("BarbedMetalFence", 1);

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

function toolPackage.OnSpawn(handler, prefab: Model)
	prefab:AddTag("TrapStructures");

	if modConfigurations.ExpireDeployables == true then
		Debugger.Expire(prefab, 300);
	end
	
	local modDestructible = require(prefab:WaitForChild("Destructible"));
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
	
	local player = handler.Player;
	function touchHandler:OnHumanoidTouch(humanoid, basePart, hitPart)
		local targetModel = hitPart.Parent;
		if targetModel == nil or not targetModel:IsA("Model") then return end;
		
		local damagable = modDamagable.NewDamagable(targetModel);
		if damagable == nil or damagable.Object.ClassName ~= "NpcStatus" then return end;

		local npcStatus = damagable.Object;
		local npcModule = npcStatus:GetModule();
		
		if player == nil or damagable:CanDamage(player) then
			local healthInfo = damagable:GetHealthInfo();
			
			local damage = math.clamp(healthInfo.MaxHealth * 0.001, 10, math.huge);
			local newDmgSrc = modDamagable.NewDamageSource{
				Damage=damage;
				Dealer=player;
				ToolStorageItem=handler.StorageItem;
				TargetPart=hitPart;
			}
			damagable:TakeDamagePackage(newDmgSrc);
			
			local entityStatus = npcModule.EntityStatus;
			
			entityStatus:Apply("BarbWireSlow", {
				Expires = modSyncTime.GetTime()+2;
				SlowValue = 2;
			})
			
			modDestructible:TakeDamagePackage(modDamagable.NewDamageSource{
				Damage=15;
			});
		end
	end
end;

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class);
end

return toolPackage;