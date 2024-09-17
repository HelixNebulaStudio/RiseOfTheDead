local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local AnalyticsServiceWrapper = {};

local AnalyticsService = game:GetService("AnalyticsService");
--==

AnalyticsServiceWrapper.Currency = {
    Money="Money";
    Perks="Perks";
    TweakPoints="TweakPoints";
    Gold="Gold";
}

function AnalyticsServiceWrapper:Source(param)
    local player = param.Player;
    local currency = param.Currency;
    local amount = param.Amount;
    local endBalance = param.EndBalance;
    local transactionType = param.TransactionType or Enum.AnalyticsEconomyTransactionType.Gameplay.Name;
    local itemSku = param.ItemSKU;
    local customFields = param.CustomFields;

    AnalyticsService:LogEconomyEvent(
        player, 
        Enum.AnalyticsEconomyFlowType.Source,
        currency,
        amount,
        endBalance,
        transactionType,
        itemSku,
        customFields
    );
end

function AnalyticsServiceWrapper:Sink(param)
    local player = param.Player;
    local currency = param.Currency;
    local amount = param.Amount;
    local endBalance = param.EndBalance;
    local transactionType = param.TransactionType or Enum.AnalyticsEconomyTransactionType.Gameplay.Name;
    local itemSku = param.ItemSKU;
    local customFields = param.CustomFields;

    AnalyticsService:LogEconomyEvent(
        player, 
        Enum.AnalyticsEconomyFlowType.Sink,
        currency,
        amount,
        endBalance,
        transactionType,
        itemSku,
        customFields
    );
end

--==
AnalyticsServiceWrapper.OnBoardingSteps = {
    ClickPlay = 1;

    Mission1_WakeUp = 2;
    Mission1_TakePistol = 3;
    Mission1_EquipPistol = 4;
    Mission1_Complete = 5;

    Mission2_WakeUp = 6;
    Mission2_TalkToMason = 7;
    Mission2_ExitBedroom = 8;
    Mission2_DrDeniskiHeal = 9;
    Mission2_PurchaseAmmo = 10;
    Mission2_KillTenZombies = 11;
    Mission2_Complete = 12;

    Mission5_Start = 13;
    Mission5_CheckBlueprintCost = 14;
    Mission5_BuildDamageMod = 15;
    Mission5_CollectDamageMod = 16;
    --Mission5_EquippedDamageMod = 17;
    Mission5_Complete = 17;

    Mission6_Start = 18;
    Mission6_DestroyedBarricade = 19;
    Mission6_Complete = 20;

    Mission7_Start = 21;
    Mission7_EnteredBossFight = 22;
    Mission7_DefeatedBoss = 23;
    Mission7_UnlockedBloxmartGate = 24;
    Mission7_Complete = 25;
};

function AnalyticsServiceWrapper:LogOnBoarding(param)
    local player = param.Player;
    local boardingStep = param.OnBoardingStep;
    local customFields = param.CustomFields;

    local boardingStepName;
    for name, step in pairs(AnalyticsServiceWrapper.OnBoardingSteps) do
        if step == boardingStep then
            boardingStepName = name;
            break;
        end
    end

    AnalyticsService:LogOnboardingFunnelStepEvent(
        player,
        boardingStep,
        boardingStepName,
        customFields
    )
    
end

return AnalyticsServiceWrapper;