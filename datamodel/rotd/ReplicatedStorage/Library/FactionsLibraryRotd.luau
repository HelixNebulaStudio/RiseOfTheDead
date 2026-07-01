local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);

local modFactionsLibrary = shared.require(game.ReplicatedStorage.Library.FactionsLibrary);

local DISTRIBUTION_LIBRARY = modLibraryManager.new();
modFactionsLibrary.DistributionsLibrary = DISTRIBUTION_LIBRARY;


DISTRIBUTION_LIBRARY:Add{
	Id = "ammobox";

    Type = "Item";
    ItemId = "ammobox";

    UnlockBy = `Unlock by completing <b>Mission: Ammo Manufacturing</b>`;
    FundCost = 6000;
};


if shared.gameConfig.BranchName == "Dev" then
    -- for testing only 
    
    DISTRIBUTION_LIBRARY:Add{
        Id = "annihilationsoda";

        Type = "Item";
        ItemId = "annihilationsoda";

        FundCost = 10000;
    };

    DISTRIBUTION_LIBRARY:Add{
        Id = "gumball";

        Type = "Item";
        ItemId = "gumball";

        FundCost = 15000;
    };

    DISTRIBUTION_LIBRARY:Add{
        Id = "perkscupcake";

        Type = "Item";
        ItemId = "perkscupcake";

        FundCost = 20000;
    };

end

return modFactionsLibrary;