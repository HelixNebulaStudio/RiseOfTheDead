local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
--==
local library = modLibraryManager.new();
local libraryAdd = library.Add;

library.NpcTasks = {};

function library:Add(data)
    local npcsList = data.NpcsList;

    for a=1, #npcsList do
        local npcName = npcsList[a];
        if library.NpcTasks[npcName] == nil then
            library.NpcTasks[npcName] = {};
        end

        table.insert(library.NpcTasks, data);
    end

    return libraryAdd(library, data);
end

function library:GetTasks(npcName)
    return library.NpcTasks[npcName];
end

-- MARK: Lydia
library:Add{
    Id="scavengeColorCustoms";
    Name="Scavenge Custom Colors";
    Requirements={
        {Type="Mission"; Id=78; Completed=true;};
    };
    NpcsList = {"Lydia";};
};

return library;


