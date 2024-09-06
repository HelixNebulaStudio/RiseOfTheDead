local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16855658641;};
		Load={Id=16855661898;};
		PrimaryAttack={Id=16855664531};
		PrimaryAttack2={Id=16855682824};
		HeavyAttack={Id=4473902088};
		Inspect={Id=16855689192;};
		Unequip={Id=16855693138};
		
	} or {
		Core={Id=16855529757;};
		Load={Id=16855532480;};
		PrimaryAttack={Id=16855664531};
		PrimaryAttack2={Id=16855682824};
		HeavyAttack={Id=4473902088};
		Inspect={Id=16855689192;};
		Unequip={Id=16855693138};
	};
	Audio={
		Load={Id=2304904662; Pitch=1; Volume=0.4;};
		PrimaryHit={Id=9141019032; Pitch=1; Volume=1;};
		PrimarySwing={Id=158037267; Pitch=0.8; Volume=0.6;};
	};
};

--==
local RunService = game:GetService("RunService");
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

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
		Debugger:Warn("ToolCategory:", toolConfig.Category);
		

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