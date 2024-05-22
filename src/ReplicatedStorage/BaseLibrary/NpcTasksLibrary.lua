local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
--==
local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);
local library = modLibraryManager.new();

library.NpcTasks = {};

library:SetOnAdd(function(data)
    local npcsList = data.NpcsList;

    local function add(npcName)
        if library.NpcTasks[npcName] == nil then
            library.NpcTasks[npcName] = {};
        end

        if table.find(library.NpcTasks[npcName], data) == nil then
            table.insert(library.NpcTasks[npcName], data);
        end
    end

    local listType = npcsList[1];
    
    if listType == "x" then
        for a=1, #modNpcProfileLibrary.Keys do
            local npcName = modNpcProfileLibrary.Keys[a];
            local npcLib = modNpcProfileLibrary:Find(npcName);
            if npcLib.SafehomeNpc ~= true then continue end;
            if table.find(npcsList, npcName) then continue end;

            add(npcName);
        end

    else
        for a=1, #npcsList do
            add(npcsList[a]);
        end
    end
end)

function library:GetTasks(npcName)
    return library.NpcTasks[npcName];
end

local genericSkipCost = {Perks=25; Gold=700;};
--==
library:Add{
    Id="scavengeColorCustoms";
    Name="Scavenge Custom Colors";
	Description="Scavenge for a Custom Color unlockable of your choosing.";
    Requirements={
        {Type="Mission"; Id=78; Completed=true;};
        {Type="Stat"; Id="Happiness"; Value=0.5;};
    };
    FailFactors={
        {Type="Stat"; Id="Hunger"; Value=0.1; Weight=1;};
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

--
library:Add{
    Id="scavengeFood";
    Name="Scavenge Food";
	Description="Scavenge for food for your safehome.";
    Requirements={
        {Type="Stat"; Id="Hunger"; Value=0.5;};
    };
    FailFactors={};
    Values={};
    Rewards={
        {
            Type="ItemDrop";
            RewardId="npctask:foodscavenge";
        };
    };
    Duration=3600;
    NpcsList = {"x";};
    SkipCost = genericSkipCost;
};


return library;


