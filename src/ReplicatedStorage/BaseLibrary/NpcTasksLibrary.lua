local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
--==
local library = modLibraryManager.new();

-- MARK: Lydia
library:Add{
    Id="scavengeColorCustoms";
    Name="Scavenge Custom Colors";
    Requirements={
        {Type="Mission"; Id=78; Completed=true;};
    };
};

return library;


