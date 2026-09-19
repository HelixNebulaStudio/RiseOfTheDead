local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modifierPackage = {
	Name = "LabSafety";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Instancing(modifier: ItemModifierInstance, isFirstTime: boolean)
	if RunService:IsClient() then return end;

	if modifier.WieldComp and modifier.WieldComp.CompOwner and modifier.WieldComp.CompOwner.ClassName ~= "PlayerClass" then
		return 
	end;

	modifier.Properties.CurProtection = 100;
	modifier.Properties.MaxProtection = 100;
	modifier.Properties.LastDamageTick = workspace:GetServerTimeNow();

	modifier.OnEnabledChanged:Connect(function()
		if modifier.WieldComp == nil then return end;

		local playerClass: PlayerClass? = modifier.WieldComp.CompOwner :: PlayerClass;
		if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;
		
		if modifier.Enabled then
			playerClass.StatusComp:Apply("LabCoat", {
				Values = {
					ModifierId = modifier.Id;
				};
			});
		else
			local status: StatusClassInstance = playerClass.StatusComp:GetOrDefault("LabCoat");
			if status then
				status.IsExpired = true;
			end
		end


	end)
end

if RunService:IsServer() then
	function modifierPackage.Binds.CharacterClassTakenDamage(modifier: ItemModifierInstance, damageData: DamageData)
		if damageData.DamageType == "Heal" or damageData.Damage <= 0  then return end;

		local dmgCategory = damageData.DamageCate;
		if dmgCategory == nil then return end;

		if dmgCategory ~= "FumesGas"
		and dmgCategory ~= "TickCombustion"
		and dmgCategory ~= "GasLeak" then return end;

		local damage = damageData.Damage;

		local curProtection = modifier.Properties.CurProtection;
		if curProtection <= 0 then return end;

		local dmgTaken = 0;
		if curProtection >= damage then
			dmgTaken = damage;
		else
			dmgTaken = curProtection;
		end

		modifier.Properties.CurProtection = math.clamp(
			modifier.Properties.CurProtection - dmgTaken, 
			0,
			modifier.Properties.MaxProtection
		);

		damageData.Damage -= math.max(dmgTaken, 0);
		modifier.Properties.LastDamageTick = workspace:GetServerTimeNow();
	end
end

return modifierPackage;