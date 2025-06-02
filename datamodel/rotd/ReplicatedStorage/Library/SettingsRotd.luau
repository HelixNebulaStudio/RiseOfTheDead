local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modSettings = require(game.ReplicatedStorage.Library.Settings);
--==

function modSettings.onRequire()
	local baseConfigInterface = modSettings.DefaultConfigInterface;

    modSettings.Add("KeyTogglePat", modSettings.Checks.KeyCheck);
    
	local uiKeyCheck = modSettings.Checks.IgnoreMouseKeys(modSettings.Checks.KeyCheck);

    modSettings.Add("KeyWindowInventory", uiKeyCheck);
    modSettings.Add("KeyWindowFactionsMenu", uiKeyCheck);
    modSettings.Add("KeyWindowMissions", uiKeyCheck);
    modSettings.Add("KeyWindowSocialMenu", uiKeyCheck);
    modSettings.Add("KeyWindowMasteryMenu", uiKeyCheck);
    modSettings.Add("KeyWindowWorkbench", uiKeyCheck);
    modSettings.Add("KeyWindowMapMenu", uiKeyCheck);

	modSettings.Add("KeyScoreboardToggle", uiKeyCheck);
	modSettings.Add("KeyWindowGambitShop", uiKeyCheck);
    
    modSettings.Add("UseOldZombies", modSettings.Checks.BooleanOrNil);
    baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
        TitleProperties={Text="Use Zombie 1.0 Skin & Face";};
        DescProperties={Text="Use Zombie 1.0's skin tone & face. Only shows for new spawns. (Model, clothing & animations aren't compatible)";};
        Config={
            SettingsKey="UseOldZombies";
            Type="Toggle;Disabled;Enabled";
        };
    });

	modSettings.SettingsKeybindControlsTable = {
		{Order=1; Type="Border"; Text="Rise of the Dead"};

        {Order=2; Type="Option"; Id="KeyToggleSpecial"; Text="Toggle/Trigger Special"; };
        {Order=3; Type="Option"; Id="KeyTogglePat"; Text="Toggle Portable Auto Turret"; };
        
		{Order=500; Type="Border"; Text="Nekron's Gambit"};
		{Order=501; Type="Option"; Id="KeyScoreboardToggle"; Text="Scoreboard"; };
		{Order=502; Type="Option"; Id="KeyWindowGambitShop"; Text="Shop"; };
	};
end

return modSettings;