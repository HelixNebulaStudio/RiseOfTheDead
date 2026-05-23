local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local BuildAdTimeSkipPackage = {
    ProductIds = {20802461};
};


function BuildAdTimeSkipPackage.ProcessReceipt(player: Player, receiptInfo)
    Debugger:Warn(`Process receiptInfo {receiptInfo}`);
end

return BuildAdTimeSkipPackage;