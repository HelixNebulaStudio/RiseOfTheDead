local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local AnalyticsServiceWrapper = {};

local AnalyticsService = game:GetService("AnalyticsService");

AnalyticsServiceWrapper.Currency = {
    Money="Money";
    Perks="Perks";
    TweakPoints="TweakPoints";
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

return AnalyticsServiceWrapper;