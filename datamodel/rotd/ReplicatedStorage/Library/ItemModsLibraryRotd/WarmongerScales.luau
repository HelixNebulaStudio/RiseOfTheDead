local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Warmonger Scales";
	
	Tags = {
		Unique_HealthMods = true;
		Unique_PacifistsWarmongers = true;
	};
	Binds = {};
};
--==

if RunService:IsServer() then
	function modifierPackage.Binds.WeaponShotDamageDataNew(modifier: ItemModifierInstance, damageData: DamageData)
		if shared.WorldName == "Slaughterfest" then return end;
		if damageData == nil then return end;

		local damageTo: CharacterClass? = damageData.DamageTo :: CharacterClass;
		if damageTo == nil or (damageTo.ClassName ~= "PlayerClass" and damageTo.ClassName ~= "NpcClass") then return end;
		
		local characterClassTo: CharacterClass? = (modifier.WieldComp and modifier.WieldComp.CompOwner or nil) :: CharacterClass?;
		if characterClassTo == nil then return end;

		local targetHealthComp = damageTo.HealthComp;
		if targetHealthComp == nil or targetHealthComp.IsDead or not targetHealthComp:CanTakeDamageFrom(characterClassTo) then return end;

		local targetCurHealth = targetHealthComp.CurHealth or nil;
		if targetCurHealth == nil then return end;

		local targetMaxHealth = targetHealthComp.MaxHealth;

		task.spawn(function()
			local damage = damageData.Damage;
			if damageData.DamageType == "Heal" then return end;

			damage = math.max(targetCurHealth, damage);
			if damage <= 0 then return end;

			local statusComp = characterClassTo.StatusComp;
			if statusComp == nil then return end;

			local statusClass = statusComp:GetOrDefault("WarmongerScales");
			if statusClass == nil then 
				statusClass = statusComp:Apply("WarmongerScales", {
					Values = {
						HealthPerKill = modifier.Properties.HealthPerKill;
						Max = modifier.Properties.Max;
						Pool = 0;
						Buffer = 0;
						LastDeduct = tick();
					};
				});
			end;

			local ratio = math.clamp(damage/targetMaxHealth, 0.1, 1);
			local add = ratio * statusClass.Values.HealthPerKill;

			local oldPool = (statusClass.Values.Pool or 0);
			statusClass.Values.Pool = math.clamp(oldPool + add, 0, statusClass.Values.Max);
			statusClass.Values.LastDeduct = tick()+1;

			if statusClass.Values.Pool > oldPool then
				local dif = statusClass.Values.Pool-oldPool;

				statusClass.Values.Buffer = (statusClass.Values.Buffer or 0) + dif;
			end
			statusClass.Values.LastDamageDealt = workspace:GetServerTimeNow();

			statusClass:Sync();
		end)
	end
end;

function modifierPackage.Update(modifier: ItemModifierInstance)
	local hpkLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "HPK");
	local hpkValue, hpkTweakVal = hpkLayerInfo.Value, hpkLayerInfo.TweakValue;
	if hpkTweakVal then
		hpkValue = hpkValue + hpkTweakVal;
	end

	local hpLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "HP");
	local hpValue, hpTweakVal = hpLayerInfo.Value, hpLayerInfo.TweakValue;
	if hpTweakVal then
		hpValue = hpValue + hpTweakVal;
	end

	modifier.Properties.HealthPerKill = hpkValue;
	modifier.Properties.Max = hpValue;
end

return modifierPackage;