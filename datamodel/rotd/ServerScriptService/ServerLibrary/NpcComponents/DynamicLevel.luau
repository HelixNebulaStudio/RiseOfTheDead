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
		if damageBy and damageBy.ClassName == "PlayerClass" then 
			self(damageBy);
		end;

		_takeDamage(hc, damageData);
	end

end

function Component:__call(callerCharacterClass: CharacterClass)
	local npcClass: NpcClass = self.NpcClass;
	local healthComp: HealthComp = npcClass.HealthComp;
	if healthComp.IsDead then return end;
	if healthComp.CurHealth < healthComp.MaxHealth then return end;

	local npcPackage = npcClass.NpcPackage;
	local dynamicLevelScaling = npcPackage.DynamicLevelScaling;
	if dynamicLevelScaling == nil then return end;

	local configurations: ConfigVariable = npcClass.Configurations;
	local properties: PropertiesVariable<anydict> = npcClass.Properties;

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

			preLevel = math.round(playerLevel * (areaDifficulty/10));
		else
			preLevel = math.round((areaDifficulty/10) * math.ceil(modGlobalVars.MaxLevels/10));
		end
		preLevel = math.max(preLevel, 0);
			
		if properties.Level == preLevel then return end;
		properties.Level = preLevel;
	end

	local level = properties.Level;

	local lvlMoveSpeed = dynamicLevelScaling.WalkSpeed;
	if type(lvlMoveSpeed) == "function" then
		lvlMoveSpeed = lvlMoveSpeed(level);
	end
	configurations.BaseValues.WalkSpeed = lvlMoveSpeed;
	npcClass.Move:SetMoveSpeed("set", "default", lvlMoveSpeed);
	
	local lvlHealth = dynamicLevelScaling.MaxHealth;
	if type(lvlHealth) == "function" then
		lvlHealth = lvlHealth(level);
	end
	configurations.BaseValues.MaxHealth = lvlHealth;

	local lvlAttackDamage = dynamicLevelScaling.AttackDamage;
	if type(lvlAttackDamage) == "function" then
		lvlAttackDamage = lvlAttackDamage(level);
	end
	configurations.BaseValues.AttackDamage = lvlAttackDamage;

	if healthComp.LastDamagedBy == nil then
		healthComp:SetMaxHealth(configurations.MaxHealth);
		healthComp:Reset();
	end
end

return Component;