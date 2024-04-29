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

-- MARK: Lydia
library:Add{
    Id="scavengeColorCustoms";
    Name="Scavenge Custom Colors";
	Description="Scavenge for a Custom Color unlockable of your choosing.";
    Requirements={
        {Type="Mission"; Id=78; Completed=true;};
    };
    Duration=3600;
    NpcsList = {"Lydia";};
};

library:Add{
    Id="scavengeColorCustoms2";
    Name="Scavenge Custom Colors 2";
	Description="Scavenge for a Custom Color unlockable of your choosing.";
    Requirements={
        {Type="Mission"; Id=78; Completed=true;};
    };
    Duration=3600;
    NpcsList = {"Lydia";};
};

library:Add{
    Id="scavengeColorCustoms3";
    Name="Scavenge Custom Colors 3";
	Description="Scavenge for a Custom Color unlockable of your choosing.";
    Requirements={
        {Type="Mission"; Id=78; Completed=true;};
    };
    Duration=3600;
    NpcsList = {"Lydia";};
};

library:Add{
    Id="scavengeColorCustoms4";
    Name="Scavenge Custom Colors 4";
	Description="Scavenge for a Custom Color unlockable of your choosing.";
    Requirements={
        {Type="Mission"; Id=78; Completed=true;};
    };
    Duration=3600;
    NpcsList = {"Lydia";};
};

library:Add{
    Id="scavengeColorCustoms5";
    Name="Scavenge Custom Colors 5";
	Description="Scavenge for a Custom Color unlockable of your choosing.";
    Requirements={
        {Type="Mission"; Id=78; Completed=true;};
    };
    Duration=3600;
    NpcsList = {"Lydia";};
};

return library;


