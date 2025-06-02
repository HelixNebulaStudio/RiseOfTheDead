local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modPseudoRandom = shared.require(game.ReplicatedStorage.Library.PseudoRandom);

local casualRandom;

local modifierPackage = {
	Name = "Critical Shot";

	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Binds.OnNewDamage(modifier: ItemModifierInstance, damageData: DamageData)
    if RunService:IsClient() then return end;

    if modifier.EquipmentClass == nil then return end;
    local configurations = modifier.EquipmentClass.Configurations;

    local critChance = configurations.CritChance or 0;

    local player = modifier.Player;
    local classPlayer = player and shared.modPlayers.get(player);
    if classPlayer and classPlayer.Properties and classPlayer.Properties.CritBoost then
        critChance = critChance + (classPlayer.Properties.CritBoost.Amount/100);
    end
    
    if critChance <= 0 then return end;

    if casualRandom == nil then
        casualRandom = modPseudoRandom.new();
    end
    local critProced = casualRandom:FairCrit(nil, critChance);
    if critProced == false then return end;

    local preModDamage = configurations.PreModDamage;
    local multi = configurations.CritMulti or 1.5;
    local add = (preModDamage * multi);

    damageData.Damage = damageData.Damage + add;
    damageData.DamageType = "Crit";

    local toolHandler: ToolHandlerInstance? = damageData.ToolHandler;
    local toolModel = toolHandler and toolHandler.Prefabs[1] or nil;
    if toolModel then
        local critSound = modAudio.Play("CritHit0"..math.random(1, 2) , toolModel.PrimaryPart);
        critSound.PlaybackSpeed = math.random(800, 1200)/1000;
        critSound.Volume = 1;
    end
end

return modifierPackage;