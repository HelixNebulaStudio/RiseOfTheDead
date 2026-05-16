local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modifierPackage = {
	Name = "Health Reaper";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	modItemModifierClass.AddTierDamage(modifier);

	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "H");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

    modifier.Properties.HealAmount = value;
end

local KILL_THRESHOLD = 3;
local KILL_WINDOW = 5;
local MOD_COOLDOWN = 8;

if RunService:IsServer() then
    function modifierPackage.Binds.DeathHandler(modifier: ItemModifierInstance, npcClass: NpcClass, damageData: DamageData)
        local curTime = workspace:GetServerTimeNow();
        if modifier.Properties.CooldownTick and curTime < modifier.Properties.CooldownTick then
            return;
        end

		if damageData.ToolHandler == nil or modifier.EquipmentClass ~= damageData.ToolHandler.EquipmentClass then
			return; -- not killed by this weapon
		end

        if modifier.Properties.KillList == nil then
            modifier.Properties.KillList = {};
        end

        local killList = modifier.Properties.KillList;
        table.insert(killList, curTime);

        local healAmount = modifier.Properties.HealAmount;

        local listCount = #killList;
        local firstKill = killList[listCount-(KILL_THRESHOLD-1)];
        if listCount >= KILL_THRESHOLD and firstKill then
            local timeSinceFirstKill = curTime - firstKill;
            local success = timeSinceFirstKill <= KILL_WINDOW;

            if success then
                modifier.Properties.CooldownTick = curTime + MOD_COOLDOWN;
                modifier:Sync({"CooldownTick"});
                table.clear(killList);

                local characterClass: CharacterClass? = modifier.WieldComp and modifier.WieldComp.CompOwner :: CharacterClass;
                if characterClass and characterClass.HealthComp and not characterClass.HealthComp.IsDead then
                    characterClass.HealthComp:TakeDamage(DamageData.new{
                        Damage = -healAmount;
                        DamageType = "Heal";
                        TargetPart = characterClass.RootPart;
                    });
                end
            end

            for a=1, #killList do
                if #killList > KILL_THRESHOLD then
                    local tl = curTime - killList[1];
                    if tl > KILL_WINDOW then
                        table.remove(killList, 1);
                    end
                end;
            end
        end
    end

else
	function modifierPackage.Binds.WeaponRenderStepped(modifier: ItemModifierInstance, toolStatusHud: anydict)
		if modifier.Enabled == false then return end;

		local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
		assert(equipmentClass, `Missing equipment class: {modifier}`);

		local configurations = equipmentClass.Configurations;

		if toolStatusHud.HealthReaper == nil then
			toolStatusHud.HealthReaper = {
				ModItemId=`healthreaper`;
				Order=1;
				Text="";
			};
		end

        local curTime = workspace:GetServerTimeNow();

		local modifierValues = modifier.Properties;
        local cooldownTl = (modifierValues.CooldownTick or curTime-5) - curTime;
        toolStatusHud.HealthReaper.ColorPercent = 1-math.clamp(cooldownTl/MOD_COOLDOWN, 0, 1);
	end

    
end

return modifierPackage;