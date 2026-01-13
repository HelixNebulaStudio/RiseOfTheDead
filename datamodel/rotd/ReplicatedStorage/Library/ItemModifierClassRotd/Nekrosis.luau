local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Nekrosis";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.onRequire()
	if RunService:IsClient() then return end;

	function modifierPackage.Binds.CharacterClassTakeDamage(modifier: ItemModifierInstance, damageData: DamageData)
		local characterClass: CharacterClass? = modifier.WieldComp and modifier.WieldComp.CompOwner or nil;
		if characterClass == nil then return end;

		local statusComp: StatusComp = characterClass.StatusComp;

		local statusClass: StatusClassInstance? = statusComp:GetOrDefault("Nekrosis");
		if statusClass then return end;

		statusComp:Apply("Nekrosis", {});
	end

	shared.modEventService:OnInvoked("Players_BindSpawn", function(event: EventPacket, playerClass: PlayerClass)
		task.wait(1);
		if playerClass.HealthComp.IsDead then return end;
		
		local statusClass: StatusClassInstance? = playerClass.StatusComp:GetOrDefault("Nekrosis");
		if statusClass then return end;

		playerClass.StatusComp:Apply("Nekrosis", {});
	end)
end

return modifierPackage;