local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

library:Add{
	Id="reqback";
	Icon="rbxassetid://4561090238";
	Name="Requesting Backup";
	
	Description="When you drop below 35% health, you will heal up to $Percent% health of a squadmate with the highest health. (1 minute cooldown)";
	Stats={
		Percent={Base=50; Max=75};
	};
	
	Level=40;
	UpgradeCost=20;
	MaxLevel=5;
	Triggers={"OnHealthChange"};
};

library:Add{
	Id="methme";
	Icon="rbxassetid://16098835311";
	Name="Meet the Medic";
	Link="reqback";

	Description="When you heal someone else, you also heal by $Percent%.";
	Stats={
		Percent={Base=60; Max=110};
	};

	Level=60;
	UpgradeCost=20;
	MaxLevel=5;
};

library:Add{
	Id="resgat";
	Icon="rbxassetid://16380816785";
	Name="Resource Gatherers";
	Link="reqback";

	Description="When a squad mate picks up an item, they will also help you pick up the item and this goes into cooldown for $Cooldown seconds.";
	Stats={
		Cooldown={Base=5; Max=1};
	};

	Level=60;
	UpgradeCost=20;
	MaxLevel=5;
};

return library;