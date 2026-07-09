local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16923739633;};
		PrimaryAttack={Id=17765553002;};
		Load={Id=16923742307};
		Inspect={Id=16923747582; WaistStrength=0.2;};
		Charge={Id=16923735442;};
		Throw={Id=16923753693};
		Unequip={Id=16923756581};
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};

		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=4844105915; Pitch=1; Volume=2;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=2;};
	};

	Configurations={
		Category = "Pointed";
		Type="Tool";

		EquipLoadTime=0.5;
		FireAlertRange = 24;
		Damage=300;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.5;

		HitRange = 8;

		WaistRotation=math.rad(0);
		StaminaCost = 25;
		StaminaDeficiencyPenalty = 0.5;

		UseViewmodel = false;

		-- Throwable
		Throwable = true;
		ThrowRange = 40;
		ThrowDamagePercent = 0.04;

		ChargeDuration = 1;
		ThrowStaminaCost = 25;
		
		ThrowRate = 1;
		ThrowWaistRotation=math.rad(0);

		--== Projectile
		ProjectileId = "pickaxe";
		ProjectileConfig = {
			Velocity = 60;
			Bounce = 0;
			LifeTime = 10;
		};
		VelocityBonus = 60;

		ConsumeOnThrow=false;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

function toolPackage.BindMeleePointHit(handler: ToolHandlerInstance, packet)
	if not game:GetService("RunService"):IsStudio() then return end;
	Debugger:Warn("MeleePointHit", packet);
end

function toolPackage.ClientEquip(handler: ToolHandlerInstance)
	local wieldComp: WieldComp = handler.WieldComp;

	local function updateMinables()
		local interactConfigs = CollectionService:GetTagged("Interactable");

		local minableInteractConfigList = {};
		for a=1, #interactConfigs do
			local config = interactConfigs[a];

			if config:GetAttribute("_Name") ~= "PickupableRotd" then continue end;
			if config:GetAttribute("_EquipItemId") ~= "pickaxe" then continue end;

			table.insert(minableInteractConfigList, config);

			local model = config.Parent;

			local isPickaxeEquiped = wieldComp.ItemId == "pickaxe";
			local highlight: Highlight = model:FindFirstChild("PickaxeHighlight");

			if isPickaxeEquiped and highlight == nil then
				highlight = Instance.new("Highlight");
				highlight.Name = "PickaxeHighlight";
				highlight.FillTransparency = 1;
				highlight.OutlineTransparency = 0.5;
				highlight.DepthMode = Enum.HighlightDepthMode.Occluded;
				highlight.Parent = model;

			elseif isPickaxeEquiped == false and highlight then
				highlight:Destroy();

			end

		end
	end
	
	handler.Garbage:Tag(CollectionService:GetInstanceAddedSignal("Interactable"):Connect(updateMinables));
	updateMinables();

	handler.Garbage:Tag(updateMinables);
end

return toolPackage;