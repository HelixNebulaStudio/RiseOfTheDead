local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

return function(player, dialog, data)
    local rngInitial = {
        "Get out of my face! I'm trying to sleep.";
        "What do you want?!";
        "Stop messing about!";
    }
    
    if math.random(1, 4) == 1 then
        dialog:SetInitiate(`Today is day {workspace:GetAttribute("DayOfYear") or 0} of the year..`, "Angry");

    else
        dialog:SetInitiate(rngInitial[math.random(1, #rngInitial)], "Angry");
    end
end
