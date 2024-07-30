local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

return function(player, dialog, data)
    if math.random(1, 99) == 1 then
        dialog:InitDialog{
            Text="... *creak*";
        }
    else
        dialog:InitDialog{
            Text="...";
        }
    end
end