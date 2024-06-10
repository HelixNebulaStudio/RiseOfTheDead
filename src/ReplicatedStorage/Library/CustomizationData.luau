local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local CustomizationData = {};
CustomizationData.__index = CustomizationData;

function CustomizationData.new(player)
    local meta = {};
    meta.__index = meta;
    meta.Player = player;

    local self = {

    };

    setmetatable(self, meta);
    setmetatable(meta, CustomizationData);
    return self;
end

function CustomizationData:Load(rawTable)

    return self;
end

return CustomizationData;