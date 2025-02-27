local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modItemModifierClass = require(game.ReplicatedStorage.Library.ItemModifierClass);
local modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);

local ItemModifier = modItemModifierClass.new(script);
local casualRandom = modPseudoRandom.new();
--==

if RunService:IsServer() then

    function ItemModifier:OnNewDamageSource(damageSource)
        local configurations = self.EquipmentClass.Configurations;

        local critChance = configurations.CritChance or 0;
	
        local player = self.Player;
        local classPlayer = player and shared.modPlayers.Get(player);
        if classPlayer and classPlayer.Properties and classPlayer.Properties.CritBoost then
            critChance = critChance + (classPlayer.Properties.CritBoost.Amount/100);
        end
        
        if critChance <= 0 then return end;

        local critProced = casualRandom:FairCrit(nil, critChance);
        if critProced == false then return end;

        local preModDamage = configurations.PreModDamage;
        local multi = configurations.CritMulti or 1.5;
        local add = (preModDamage * multi);

        damageSource.Damage = damageSource.Damage + add;
        damageSource.DamageType = "Crit";

        local toolModel = damageSource.ToolModel;
        if toolModel then
            local critSound = modAudio.Play("CritHit0"..math.random(1, 2) , toolModel.PrimaryPart);
            critSound.PlaybackSpeed = math.random(800, 1200)/1000;
            critSound.Volume = 1;
        end
    end

end

return ItemModifier;