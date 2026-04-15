local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

library:Add{
	Id="nigowl";
	Icon="rbxassetid://4492141104";
	Name="Night Owl";
	
	Description="Reduce range of enemy detection by $Percent% during night time.";
	Stats={
		Percent={Base=10; Max=75};
	};
	
	Level=10;
	UpgradeCost=5;
	MaxLevel=5;

	EventLogicTriggers = {"GameTime_NightStart"};
	TriggerAction = "ApplyStatus";
	TriggerStatusId = "nigowl";
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
	
	EventLogicTriggers = {"Players_BindWieldEvent"};
	EventTriggerActionFunc = function(data, ...)
		local action: string, toolHandler: ToolHandlerInstance = ...;
		if action == "Unequip" or toolHandler.ToolPackage.HandlerType ~= "GunTool" then
			return "RemoveStatus";
		end
		return "ApplyStatus";
	end;
	TriggerStatusId = "trinar";
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

	BaseModifierId = "AgileRecovery";
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

	EventLogicTriggers = {"Players_BindWieldEvent"};
	EventTriggerActionFunc = function(data, ...)
		local action: string, toolHandler: ToolHandlerInstance = ...;
		if action == "Unequip" or toolHandler.ToolPackage.HandlerType ~= "MeleeTool" then
			return "RemoveStatus";
		end
		return "ApplyStatus";
	end;
	TriggerStatusId = "theswo";
};

library:Add{
	Id="ovehea";
	Icon="rbxassetid://4752500248";
	Name="Over Heal";
	Link="trinar";
	
	Description="<b>Passive:</b> Heal over max health by $Default health with medkits.\nUpgrading adds $Amount over heal.";
	Stats={
		Amount={Default=15; Base=30; Max=70};
	};
	
	Level=20;
	UpgradeCost=10;
	MaxLevel=5;
};

library:Add{
	Id="weapoi";
	Icon="rbxassetid://6157470290";
	Name="Weak Point";
	Link="ovehea";

	Description="You can identify weak points, shooting them deals an additional $Percent% of <b>PreModDamage</b>.";
	Stats={
		Percent={Base=10; Max=60};
	};

	Level=25;
	UpgradeCost=20;
	MaxLevel=5;

	BaseModifierId = "WeakPointSense";
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
};

library:Add{
	Id = "seered";
	Icon = "rbxassetid://105295368698384";
	Name = "Seeing Red";
	Link = "ovehea";

	Requirements = {};
	Description = "Damaging enemies enhances your vision in the dark for $Time seconds.";
	Stats={
		Time={Base=3; Max=18};
	};

	Level=25;
	UpgradeCost=20;
	MaxLevel=5;

	EventLogicTriggers = {"Npcs_BindDamaged"};
	EventTriggerActionFunc = function(data, damageData: DamageData)
		if data.PlayerClass == nil then return; end;
		if damageData == nil or damageData.Damage <= 0 then return; end
		if data.PlayerClass ~= damageData.DamageBy then return; end;
		return "ApplyStatus";
	end;
	TriggerStatusId = "seered";
}

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