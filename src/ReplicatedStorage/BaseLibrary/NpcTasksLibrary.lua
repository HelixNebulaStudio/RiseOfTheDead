local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
--==
local library = modLibraryManager.new();

library.NpcTasks = {};

library:SetOnAdd(function(data)
    local npcsList = data.NpcsList;

    for a=1, #npcsList do
        local npcName = npcsList[a];
        if library.NpcTasks[npcName] == nil then
            library.NpcTasks[npcName] = {};
        end

        table.insert(library.NpcTasks[npcName], data);
    end
end)

function library:GetTasks(npcName)
    return library.NpcTasks[npcName];
end

local genericSkipCost = {Perks=25; Gold=700;};
-- MARK: Lydia
library:Add{
    Id="scavengeColorCustoms";
    Name="Scavenge Custom Colors";
	Description="Scavenge for a Custom Color unlockable of your choosing.";
    Requirements={
        {Type="Mission"; Id=78; Completed=true;};
    };
    Values={
        Color={Type="ColorPicker"; Title="Scavenging Color"};
    };
    Rewards={
        {
            Type="Item"; 
            ItemId="colorcustom";
            SetItemValues=function(itemValues, taskData)
                itemValues.Color = taskData.Values.Color;
            end;
        };
    };
    Duration=3600;
    NpcsList = {"Lydia";};
    SkipCost = genericSkipCost;
};

return library;


