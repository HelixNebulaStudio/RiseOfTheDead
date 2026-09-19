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

DISTRIBUTION_LIBRARY:Add{
	Id = "juggernog";

    Type = "Item";
    ItemId = "juggernog";

    UnlockBy = `Unlock by completing <b>Mission: Food Airdrop</b>`;
    FundCost = 15000;
};

return modFactionsLibrary;