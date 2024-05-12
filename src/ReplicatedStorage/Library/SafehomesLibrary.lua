local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

library:Add{
	Id="default";
	Name="Warehouse";
	Image="http://www.roblox.com/asset/?id=7030452840";
	Unlocked=true;
	Price=0;
};

library:Add{
	Id="bunker";
	Name="Bunker";
	Image="http://www.roblox.com/asset/?id=7037517331";
	Price=24000;
};

library:Add{
	Id="abandonedmilcamp";
	Name="Abandoned Military Camp";
	Image="http://www.roblox.com/asset/?id=12724913917";
	Price=24000;
};

library:Add{
	Id="survivorsoutpost";
	Name="Survivor's Outpost";
	Image="http://www.roblox.com/asset/?id=13898399031";
	UnlockHint="Unlocked from Event Pass: Apocalypse Origins";
};

library:Add{
	Id="slaughterwoods";
	Name="Slaughter Woods";
	Image="http://www.roblox.com/asset/?id=14991850441";
	UnlockHint="Unlocked from Event Pass: Slaughter Fest 2023";
};



return library;