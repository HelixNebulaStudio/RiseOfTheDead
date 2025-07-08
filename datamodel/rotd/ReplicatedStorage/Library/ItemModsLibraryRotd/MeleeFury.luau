local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Melee Fury";
	
	Tags = {
		MeleeModifier = true;
	};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "AS");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.SetValues.MeleeFury = value;
end

function modifierPackage.Binds.OnPrimaryMelee(modifier: ItemModifierInstance, changeRef: anydict)
	if RunService:IsServer() then return end;

	local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
    if equipmentClass == nil then return end;

    Debugger:Warn(`OnPrimaryAttack`, modifier.Id);

    local characterClass: CharacterClass? = modifier.WieldComp and modifier.WieldComp.CompOwner or nil;
    if characterClass == nil or characterClass.ClassName ~= "PlayerClass" then return end
	
    local cMeleeFury = characterClass.Configurations.MeleeFury;
    if cMeleeFury == nil then return end;

    local meleeFuryStatus: StatusClassInstance = characterClass.StatusComp:GetOrDefault("MeleeFury");
    local buffDuration = 5;

    if meleeFuryStatus == nil then
        meleeFuryStatus = characterClass.StatusComp:Apply("MeleeFury", {
            ExpiresOnDeath = true;
            Duration = buffDuration;
            Expires = workspace:GetServerTimeNow() + buffDuration;
            Values = {
                Amount = 1;
            }
        });
    else
        meleeFuryStatus.Expires = workspace:GetServerTimeNow() + buffDuration;
        meleeFuryStatus.Values.Amount = math.clamp(meleeFuryStatus.Values.Amount + 1, 1, 5);
    end

	local meleeFuryBonus = 0;

    if meleeFuryStatus then
        meleeFuryBonus = meleeFuryStatus.Values.Amount * cMeleeFury;
    end
        
    if meleeFuryBonus > 0 then
        changeRef.AttackTime = changeRef.AttackTime * (1-math.clamp(meleeFuryBonus, 0, 1));
    end
	Debugger:Warn(`meleeFuryBonus {meleeFuryBonus}`, changeRef.AttackTime);
end

return modifierPackage;