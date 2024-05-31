local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Server only
local modNpcStatusMeta = require(game.ServerScriptService.ServerLibrary.Entity.NpcStatusMeta);

local NpcStatus = setmetatable({
    NpcModule = nil;
    OnTarget = nil;
    Name = nil;
}, modNpcStatusMeta);

return NpcStatus;
