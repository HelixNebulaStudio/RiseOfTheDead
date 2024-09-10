local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations={
		Core={Id=88385412741022;};
		Load={Id=90134835056137;};
		PrimaryAttack={Id=129349391321673};
		PrimaryAttack2={Id=129349391321673};
		HeavyAttack={Id=138107195915025};
		Inspect={Id=123039690215804;};
		Unequip={Id=100516511704056};
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

local bladeTweenInfo = TweenInfo.new(0.15);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";
	Tool.Category = "Edged";

	Tool.SpecialToggleHint = "to toggle between Edged and Blunt.";

	function Tool.OnInputEvent(toolHandler, inputData)
		if inputData.InputType ~= "Begin" or inputData.KeyIds.KeyToggleSpecial == nil then return end;
		
		local toolConfig = toolHandler.ToolConfig;
		if toolConfig.Category == "Edged" then
			toolConfig.Category = "Blunt";

		elseif toolConfig.Category == "Blunt" then
			toolConfig.Category = "Edged";

		end

		if RunService:IsServer() then
			local toolPrefab = toolHandler.Prefabs[1];

			local bladeMotor: Motor6D = toolPrefab.Handle.Blade;
			local colliderMotor: Motor6D = toolPrefab.Handle.Collider;

			if toolConfig.Category == "Edged" then
				colliderMotor.C0 = CFrame.new(0, 2.122, 0);
				TweenService:Create(bladeMotor, bladeTweenInfo, {
					C0=CFrame.new(0, 1.26, 0);
				}):Play();

			else
				colliderMotor.C0 = CFrame.new(0, 0, 0);
				TweenService:Create(bladeMotor, bladeTweenInfo, {
					C0=CFrame.new(0, 1.26, 0) * CFrame.Angles(0, 0, math.rad(-178));
				}):Play();

			end
		end
		
		return true; -- submit input to server;
	end
	
	Tool.Holster = {
		RightSwordAttachment={PrefabName="megaswitchblade";};
	}

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

		WaistRotation=math.rad(0);

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