local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

library:Add{
	Id="nigowl";
	Icon="rbxassetid://4492141104";
	Name="Night Owl";
	
	Description="Reduce range of enemy detection by $Percent% for the first $Time minute(s) of the night.";
	Stats={
		Percent={Base=10; Max=75};
		Time={Base=1; Max=5};
	};
	
	Level=10;
	UpgradeCost=5;
	MaxLevel=5;
	Triggers={"OnNightTimeStart";};
};

library:Add{
	Id="trinar";
	Icon="rbxassetid://4483748413";
	Name="Trained In Arms";
	Link="nigowl";
	
	Description="Increase equipped weapon's accuracy by $Percent%.";
	Stats={
		Percent={Base=10; Max=35};
	};
	
	Level=15;
	UpgradeCost=5;
	MaxLevel=5;
	Triggers={"OnToolEquipped"; "OnToolUnequipped"};
};

library:Add{
	Id="agirec";
	Icon="rbxassetid://4561097552";
	Name="Agile Recovery";
	Link="nigowl";
	
	Description="Movement impairment(E.g. Slows, Stuns) debuff's duration reduced by $Percent%.";
	Stats={
		Percent={Base=15; Max=40};
	};
	
	Level=15;
	UpgradeCost=5;
	MaxLevel=5;
	Triggers={"OnMovementImpairment"};
};

library:Add{
	Id="theswo";
	Icon="rbxassetid://4572998907";
	Name="The Swordsman";
	Link="trinar";
	
	Description="Melee weapon damage increased by $Percent%.";
	Stats={
		Percent={Base=10; Max=35};
	};
	
	Level=20;
	UpgradeCost=10;
	MaxLevel=5;
	Triggers={"OnToolEquipped"; "OnToolUnequipped"};
};

library:Add{
	Id="ovehea";
	Icon="rbxassetid://4752500248";
	Name="Over Heal";
	Link="trinar";
	
	Description="Default Passive: Heal over max health by $Default health with medkits. Upgrading increases maximum over heal by $Amount.";
	Stats={
		Amount={Default=15; Base=30; Max=70};
	};
	
	Level=20;
	UpgradeCost=10;
	MaxLevel=5;
	Triggers={};
};

library:Add{
	Id="weapoi";
	Icon="rbxassetid://6157470290";
	Name="Weak Point";
	Link="ovehea";

	Description="Default Passive: Shooting weak points deals an additional $Default% of base damage. Upgrading adds $Percent%.";
	Stats={
		Percent={Default=15; Base=10; Max=40}; --{Default=100; Base=15; Max=90};
	};

	Level=25;
	UpgradeCost=20;
	MaxLevel=5;
	Triggers={};
};

library:Add{
	Id="maist";
	Icon="rbxassetid://16479851840";
	Name="Machine Aim Stabilizer";
	Link="theswo";

	Description="Increase devices such as the Portable Auto Turret aim stability by $Percent%.";
	Stats={
		Percent={Base=5; Max=30};
	};

	Level=25;
	UpgradeCost=20;
	MaxLevel=5;
	Triggers={};
};



--library:Add{
--	Id="ammsca";
--	Icon="rbxassetid://2779233892";
--	Name="Ammo Scavenger";
--	Level=10;
--	UpgradeCost=10;
--	MaxLevel=5;
--	Description="Adds a 10%-50% chance for enemy to drop ammunition.";
--};
--
--library:Add{
--	Id="shoref";
--	Icon="rbxassetid://2779233892";
--	Name="Shot Refunded";
--	Link="ammsca";
--	Level=15;
--	UpgradeCost=10;
--	MaxLevel=5;
--	Description="For every 6 - 2 shots missed, refunds a bullet for the equipped weapon.";
--};

return library;