local modStoragePresetsLibrary = shared.require(game.ReplicatedStorage.Library.StoragePresetsLibrary);

modStoragePresetsLibrary:Replace("Inventory", {
	Name = "Inventory";
    Configuration = {
        Persistent=true;
        Size = 30;
        MaxSize = 30;
        PremiumStorage = 20;
    };
});

modStoragePresetsLibrary:Replace("Clothing", {
	Name = "Clothing";
    Configuration = {
        Persistent=true;
        Size = 5;
        MaxSize = 5;
    };
});

modStoragePresetsLibrary:Add{
    Id = "Wardrobe";
    Configuration = {
        Persistent=true;
        Size = 50;
        MaxSize = 50;
        PremiumStorage = 30;
    };
}

modStoragePresetsLibrary:Add{
    Id = "attachmentmods";
    Configuration = {
        Persistent=true;
        Size = 5;
        MaxSize = 5;
    };
};

modStoragePresetsLibrary:Add{
	Id = "Safehouse";
    Name = "Safehouse Storage";
    Configuration = {
        Persistent=true;
        Size=24;
        MaxSize=50;
        Expandable=true;
        MaxPages=4;
        PremiumPage=4;
    };
};

modStoragePresetsLibrary:Add{
	Id = "trade";
    Configuration = {
        Size=8;
        MaxSize=8;
    };
};

modStoragePresetsLibrary:Add{
	Id = "RatStorage";
    Name = "Rat Storage";
    Configuration = {
        Persistent=true; 
        Settings={ScaleByContent=1; Rental=5;};
        Size=50; 
        MaxSize=50; 
        MaxPages=9;
    };
    MissionRequired = {
        Id = 62; 
        Type = {3};
    };
};

modStoragePresetsLibrary:Add{
	Id = "Freezer";
    Name = "Food Storage";
    Configuration = {
        Persistent=true; 
        Size=10; 
        Expandable=true; 
        MaxSize=20;
    };
};



modStoragePresetsLibrary:Add{
	Id = "lootcrate"; -- Single user crate
    Name = "Loot Crate";
    Configuration = {
        Persistent=false;
        Settings={
            WithdrawalOnly=true;
            DestroyOnEmpty=false;
        }
    };
};

modStoragePresetsLibrary:Add{
	Id = "rewardcrate"; -- Multi user crate
    Name = "Reward Crate";
    Configuration = {
        Persistent=false;
        Settings={
            WithdrawalOnly=true;
        }
    };
};

modStoragePresetsLibrary:Add{
	Id = "giftcrate"; -- Persistent crate saved fter opening.
    Name = "Gift Crate";
    Configuration = {
        Persistent=true;
        Settings={
            WithdrawalOnly=true;
        }
    };
};


--MARK: Item related
modStoragePresetsLibrary:Add{
    Id = "dufflebag";
    Configuration = {
        Persistent=true;
        Expandable=true;
        Size=5;
        MaxSize=15;
        Virtual = true;
    };
};

modStoragePresetsLibrary:Add{
    Id = "portableautoturret";
    Configuration = {
        Persistent=true;
        Expandable=true;
        Size=2;
        MaxSize=2;
        Virtual = true;
    };
};

--MARK: Mission related
modStoragePresetsLibrary:Add{
	Id = "thebackupplan";
    Name = "Wooden Crate";
    Configuration = {
        Persistent=true; 
        Size=5; 
        MaxSize=5;
    };
};


--MARK: Npc
modStoragePresetsLibrary:Add{
    Id = "npcstorage";
    Configuration = {
        Persistent=true; 
        Size=5; 
        MaxSize=5;
    };
}

--MARK: Event
modStoragePresetsLibrary:Add{
    Id = "HalloweenCauldron";
    Configuration = {
        Persistent=true; 
		Size = 1;
		Virtual = true;
        Settings={
            DepositOnly=true;
        };
    };
}


return modStoragePresetsLibrary;