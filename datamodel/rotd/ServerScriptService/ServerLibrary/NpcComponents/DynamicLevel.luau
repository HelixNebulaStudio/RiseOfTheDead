local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

function Component.new(npcClass: NpcClass)
	local self = {
		NpcClass = npcClass;
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:Setup()
	local npcClass: NpcClass = self.NpcClass;

	local healthComp: HealthComp = npcClass.HealthComp;

	local _takeDamage = healthComp.TakeDamage;
	function healthComp.TakeDamage(hc, damageData: DamageData)
		if hc.IsDead then return end;

		local damageBy: CharacterClass? = damageData.DamageBy :: CharacterClass;
		local ccPlayer = damageBy and (damageBy :: NpcClass).Player;
		if ccPlayer then
			damageBy = shared.modPlayers.get(ccPlayer);
		end

		if damageBy and damageBy.ClassName == "NpcClass" then
			local damageByTargetData = damageBy.Properties.EnemyTargetData;
			local damageByTargetEntityClass: EntityClass = damageByTargetData and damageByTargetData.HealthComp and damageByTargetData.HealthComp.CompOwner;
			if damageByTargetEntityClass and damageByTargetEntityClass.ClassName == "PlayerClass" then
				damageBy = damageByTargetEntityClass :: PlayerClass;
			end
		end

		if damageBy and damageBy.ClassName == "PlayerClass" then
			self(damageBy);
		end;

		_takeDamage(hc, damageData);
	end
end

function Component:__call(callerCharacterClass: CharacterClass)
	local npcClass: NpcClass = self.NpcClass;

	local configurations: ConfigVariable = npcClass.Configurations;
	local properties: PropertiesVariable<anydict> = npcClass.Properties;

	local healthComp: HealthComp = npcClass.HealthComp;
	if healthComp.IsDead then return end;

	local npcPackage = npcClass.NpcPackage;
	local dynamicLevelScaling = npcPackage.DynamicLevelScaling;
	if dynamicLevelScaling == nil then return end;

	local areaDifficulty = properties.AreaDifficulty or 1;
	if properties.Level == nil and areaDifficulty == nil then
		Debugger:Warn(`Missing both level and areaDiff!`);
		return;
	end;

	if properties.Level and properties.SetLevel == nil then
		properties.SetLevel = properties.Level;
	end
	
	local preLevel = properties.PreLevel;
	if properties.SetLevel then
		properties.Level = properties.SetLevel;

	elseif areaDifficulty then
		if callerCharacterClass and callerCharacterClass.ClassName == "PlayerClass" then
			local player = (callerCharacterClass :: PlayerClass):GetInstance();
			local playerLevel = 1;
			local playerProfile = shared.modProfile:Get(player);
			local playerSave = playerProfile and playerProfile:GetActiveSave();
			if playerSave then 
				playerLevel = playerSave:GetStat("Level") or 1;
			end;
			playerLevel = math.max(playerLevel, 1);

			preLevel = math.round(math.ceil(playerLevel/10) * (areaDifficulty/10));
		else
			preLevel = math.round((areaDifficulty/10) * math.ceil(modGlobalVars.MaxLevels/10));
		end
		preLevel = math.max(preLevel, 0);
			
		if properties.Level == preLevel then return end;
		properties.Level = preLevel;
	end

	local level = properties.Level;
	local maxLevel = math.round(modGlobalVars.MaxLevels/10);


	local lvlMoveSpeed = dynamicLevelScaling.WalkSpeed;
	if lvlMoveSpeed then
		if type(lvlMoveSpeed) == "function" then
			lvlMoveSpeed = lvlMoveSpeed(level, maxLevel);
		end
		configurations.BaseValues.WalkSpeed = lvlMoveSpeed;
		npcClass.Move:SetMoveSpeed("set", "default", lvlMoveSpeed);
	end
	

	local lvlHealth = dynamicLevelScaling.MaxHealth;
	if type(lvlHealth) == "function" then
		lvlHealth = lvlHealth(level, maxLevel);
	end
	configurations.BaseValues.MaxHealth = lvlHealth;


	local lvlAttackDamage = dynamicLevelScaling.AttackDamage;
	if type(lvlAttackDamage) == "function" then
		lvlAttackDamage = lvlAttackDamage(level, maxLevel);
	end
	configurations.BaseValues.AttackDamage = lvlAttackDamage;


	local lvlImmunity = dynamicLevelScaling.Immunity;
	if type(lvlImmunity) == "function" then
		lvlImmunity = lvlImmunity(level, maxLevel);
	end
	configurations.BaseValues.Immunity = lvlImmunity;


	local lvlCripplingHit = dynamicLevelScaling.CripplingHit;
	if type(lvlCripplingHit) == "function" then
		lvlCripplingHit = lvlCripplingHit(level, maxLevel);
	end
	configurations.BaseValues.CripplingHit = lvlCripplingHit;

	
	if healthComp.CurHealth < healthComp.MaxHealth then
		local healthPercent = healthComp.CurHealth/healthComp.MaxHealth;

		if self.SetCooldown == nil or tick() > self.SetCooldown then
			self.SetCooldown = tick() + 150;
			healthComp:SetMaxHealth(configurations.MaxHealth);
			healthComp:SetHealth(configurations.MaxHealth * healthPercent);
		end

	elseif healthComp.LastDamagedBy == nil then
		healthComp:SetMaxHealth(configurations.MaxHealth);
		healthComp:Reset();

	end

	if configurations.Immunity then
		properties.Immunity = configurations.Immunity;
	end
end

return Component;