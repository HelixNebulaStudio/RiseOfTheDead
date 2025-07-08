local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local bladeTweenInfo = TweenInfo.new(0.15);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={IdEdged=88385412741022; IdBlunt=100039716699323;};
		Load={IdEdged=90134835056137; IdBlunt=90134835056137;};
		PrimaryAttack={IdEdged=129349391321673; IdBlunt=132575511732000;};
		HeavyAttack={IdEdged=138107195915025;};
		Inspect={IdEdged=124027192088239; IdBlunt=71182743483465;};
		Unequip={IdEdged=100516511704056; IdBlunt=100516511704056;};
		SwitchMode={IdEdged=111076155912694; IdBlunt=112369282090587;};
	};
	Audio={
		Load={Id=2304904662; Pitch=1; Volume=0.4;};
		PrimarySwing={Id=158037267; Pitch=0.8; Volume=0.6;};
	};
	
	DefaultAnimatorState = "Edged";
	SpecialToggleHint = "to toggle between Edged and Blunt.";

	Configurations={
		Category = "Edged";
		Type="Sword";

		EquipLoadTime=1;
		Damage=250;

		PrimaryAttackSpeed=0.8;
		PrimaryAttackAnimationSpeed=0.35;

		HeavyAttackMultiplier=3.45;
		HeavyAttackSpeed=1.4;
		HitRange=14;

		BaseKnockback=80;

		WaistRotation=math.rad(25);
		FirstPersonWaistOffset=math.rad(0);

		StaminaCost = 28;
		StaminaDeficiencyPenalty = 0.6;

		BleedDamagePercent=0.2;
		BleedSlowPercent=0.2;
	};
	Properties={
		ActiveCategory = "Edged";
	};
};

function toolPackage.InputEvent(toolHandler: ToolHandlerInstance, inputData)
	if inputData.InputType ~= "Begin" or inputData.KeyIds.KeyToggleSpecial == nil then return end;
	
	local properties = toolHandler.EquipmentClass.Properties;

	if properties.Disabled then return end;
	properties.Disabled = true;
	task.delay(0.75, function()
		properties.Disabled = false;
	end)

	if properties.ActiveCategory == "Edged" then
		properties.ActiveCategory = "Blunt";

	elseif properties.ActiveCategory == "Blunt" then
		properties.ActiveCategory = "Edged";

	end
	local activeCategory = properties.ActiveCategory;

	if RunService:IsClient() then
		local toolAnimator = toolHandler.ToolAnimator;

		toolAnimator:SetState(activeCategory);
		toolAnimator:Play("SwitchMode");
		toolAnimator:Play("Core");

		properties.RadialDuration = 0.75;
		properties.RadialTick = tick()+properties.RadialDuration;
	end

	if RunService:IsServer() then
		local toolPrefab = toolHandler.Prefabs[1];

		local bladeMotor: Motor6D = toolPrefab.Handle.Blade;
		local colliderMotor: Motor6D = toolPrefab.Handle.Collider;

		if activeCategory == "Edged" then
			modAudio.Play("SwitchBladeOpen", toolPrefab.PrimaryPart);

			colliderMotor.C0 = CFrame.new(0, 2.122, 0);
			TweenService:Create(bladeMotor, bladeTweenInfo, {
				C0=CFrame.new(0, 1.26, 0);
			}):Play();

		else
			modAudio.Play("SwitchBladeClose", toolPrefab.PrimaryPart);

			colliderMotor.C0 = CFrame.new(0, 0, 0);
			TweenService:Create(bladeMotor, bladeTweenInfo, {
				C0=CFrame.new(0, 1.26, 0) * CFrame.Angles(0, 0, math.rad(-178));
			}):Play();

		end
	end
	
	return true; -- submit input to server;
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;