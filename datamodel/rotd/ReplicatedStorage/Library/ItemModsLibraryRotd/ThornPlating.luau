local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modifierPackage = {
	Name = "Thorn Plating";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.onRequire()
	if RunService:IsClient() then return end;

	function modifierPackage.Binds.CharacterClassTakenDamage(modifier: ItemModifierInstance, damageData: DamageData)
		local initDamage = damageData.InitDamage;
		if initDamage <= 0 then return end;

		local damageType = damageData.DamageType;
		if damageType == "Thorn" then return end;

		local damageBy: CharacterClass? = damageData.DamageBy :: CharacterClass;
		if damageBy == nil or damageBy.ClassName ~= "NpcClass" then return end;
		
		local damageTo: CharacterClass? = damageData.DamageTo :: CharacterClass;
		if damageTo == nil then return end;

		local healthCompTo: HealthComp = damageTo.HealthComp;
		if healthCompTo.CurArmor <= 0 then return end;

		if damageData.DamageCate ~= DamageData.DamageCategory.Melee then return end;

		local conDamageReflection = damageTo.Configurations.DamageReflection;
		if conDamageReflection == nil or conDamageReflection <= 0 then return end;
		
		if damageTo.Properties.ThornCooldown and tick()-damageTo.Properties.ThornCooldown < 0.1 then return end;
		damageTo.Properties.ThornCooldown = tick();

		local healthCompBy: HealthComp = damageBy.HealthComp;
		if healthCompBy.IsDead then return end;
		
		local thornResist = (damageBy.Properties.ThornResist or 1);
		local isBasicEnemy = damageBy.Properties.BasicEnemy == true;
		if isBasicEnemy and damageBy.Properties.ThornResist == nil then
			thornResist = 0;
		end

		local reflect = conDamageReflection * math.clamp(1-thornResist, 0, 1);
		local reflectedDmg = math.max(healthCompBy.CurHealth * reflect, 10);

		local thornDmgData = DamageData.new{
			Damage = reflectedDmg;
			DamageBy = damageTo;

			TargetModel = damageBy.Character;
			TargetPart = damageBy.RootPart;
			DamageType = "Thorn";
		};

		healthCompBy:TakeDamage(thornDmgData);
	end
end

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "R");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.MaxValues.DamageReflection = value;
end

return modifierPackage;