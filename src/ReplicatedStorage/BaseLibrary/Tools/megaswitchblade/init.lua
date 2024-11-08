local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
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
};

--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local bladeTweenInfo = TweenInfo.new(0.15);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";
	Tool.Category = "Edged";
	Tool.DefaultAnimatorState = "Edged";

	Tool.SpecialToggleHint = "to toggle between Edged and Blunt.";

	function Tool.OnInputEvent(toolHandler, inputData)
		if inputData.InputType ~= "Begin" or inputData.KeyIds.KeyToggleSpecial == nil then return end;
		
		local toolConfig = toolHandler.ToolConfig;
		local configurations = toolConfig.Configurations;
		local properties = toolConfig.Properties;

		if properties.Disabled then return end;
		properties.Disabled = true;
		task.delay(0.75, function()
			properties.Disabled = false;
		end)

		if toolConfig.Category == "Edged" then
			toolConfig.Category = "Blunt";

		elseif toolConfig.Category == "Blunt" then
			toolConfig.Category = "Edged";

		end

		if RunService:IsClient() then
			local toolAnimator = toolHandler.ToolAnimator;

			toolAnimator:SetState(toolConfig.Category);
			toolAnimator:Play("SwitchMode");
			toolAnimator:Play("Core");

			properties.RadialDuration = 0.75;
			properties.RadialTick = tick()+properties.RadialDuration;

			-- if toolConfig.Category == "Edged" then
			-- 	configurations.WaistRotation=math.rad(25);
	
			-- elseif toolConfig.Category == "Blunt" then
			-- 	configurations.WaistRotation=math.rad(0);
	
			-- end
		end

		if RunService:IsServer() then
			local toolPrefab = toolHandler.Prefabs[1];

			local bladeMotor: Motor6D = toolPrefab.Handle.Blade;
			local colliderMotor: Motor6D = toolPrefab.Handle.Collider;

			if toolConfig.Category == "Edged" then
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
	
	-- Tool.Holster = {
	-- 	LowerTorsoHolster={PrefabName="megaswitchblade"; Offset=CFrame.new(-0.293823242, -0.206907272, -0.817176819, -0.0917134061, -0.965947926, -0.241936639, 0.0980803296, -0.250541896, 0.963124633, -0.990943432, 0.0646022111, 0.11771854)};
	-- }

	Tool.Configurations = {
		Type="Sword";
		EquipLoadTime=1;
		BaseDamage=250;

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

	Tool.Properties = {
		Attacking=false;
	}
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;