local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

library:Add{
	Id="morbir";
	Icon="rbxassetid://4488388895";
	Name="Morning Bird";
	
	Description="Gives you a $Heal health per second for the first $Time minute(s) of the day.";
	Stats={
		Heal={Base=0.5; Max=2};
		Time={Base=1; Max=5};
	};
	
	Level=10;
	UpgradeCost=5;
	MaxLevel=5;
	Triggers={"OnDayTimeStart";};
};

library:Add{
	Id="fiaitr";
	Icon="rbxassetid://4493354290";
	Name="First Aid Training";
	Link="morbir";
	
	Description="Using medkits are $Percent% faster.";
	Stats={
		Percent={Base=10; Max=60};
	};
	
	Level=15;
	UpgradeCost=5;
	MaxLevel=5;
	Triggers={"OnToolEquipped"; "OnToolUnequipped"};
};

library:Add{
	Id="effmet";
	Icon="rbxassetid://4651191421";
	Name="Efficient Metabolism";
	Link="morbir";
	
	Description="Increases the duration of food by $Percent%";
	Stats={
		Percent={Base=15; Max=40};
	};
	
	Level=15;
	UpgradeCost=5;
	MaxLevel=5;
	Triggers={"OnToolEquipped"; "OnToolUnequipped"};
};

library:Add{
	Id="engdeg";
	Icon="rbxassetid://4572998714";
	Name="Engineering Degree";
	Link="effmet";
	
	Description="Reduce building time for blueprints by $Percent%.";
	Stats={
		Percent={Base=15; Max=40};
	};
	
	Level=20;
	UpgradeCost=10;
	MaxLevel=5;
	Triggers={"OnBlueprintBuild";};
};

library:Add{
	Id="remres";
	Icon="rbxassetid://4651191717";
	Name="Remarkable Resilience";
	Link="effmet";
	
	Description="After dropping below 15% health, player will regenerate to $Percent% of max health. (2 minute cooldown)";
	Stats={
		Percent={Base=20; Max=35};
	};
	
	Level=20;
	UpgradeCost=10;
	MaxLevel=5;
	Triggers={"OnHealthChange"};
};

library:Add{
	Id="tougup";
	Icon="rbxassetid://6561811265";
	Name="Toughening Up";
	Link="remres";

	Description="When your armor is more than 0, every percent of damage dealt to your enemies recovers $Amount armor points.";
	Stats={
		Amount={Base=0.01; Max=0.05};
	};

	Level=25;
	UpgradeCost=20;
	MaxLevel=5;
	Triggers={"OnNpcDamaged"};
};

library:Add{
	Id="thrsen";
	Icon="rbxassetid://10829432890";
	Name="Threat Sense";
	Link="morbir";

	Description="Enemies that targets you are revealed within $Amount units away.";
	Stats={
		Amount={Base=40; Max=320};
	};

	Level=15;
	UpgradeCost=5;
	MaxLevel=5;
	Triggers={};
};

library:Add{
	Id="enecon";
	Icon="rbxassetid://16479593030";
	Name="Energy Conservationer";
	Link="engdeg";

	Description="Reduce battery power drain cost $Percent%.";
	Stats={
		Percent={Base=10; Max=85};
	};

	Level=25;
	UpgradeCost=20;
	MaxLevel=5;
	Triggers={};
};

return library;
