local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
<<<<<<< HEAD
=======

>>>>>>> 01b374c3841948c19aa3971b7a40af546df480ce
local Settings = {};
Settings.__index = Settings;
--==

function Settings:Init(super)
	local baseConfigInterface = super.DefaultConfigInterface;

    super.Add("KeyTogglePat", super.Checks.KeyCheck);
    
	local uiKeyCheck = super.Checks.IgnoreMouseKeys(super.Checks.KeyCheck);
	super.Add("KeyScoreboardToggle", uiKeyCheck);
	super.Add("KeyWindowGambitShop", uiKeyCheck);
    
    super.Add("UseOldZombies", super.Checks.BooleanOrNil);
    baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
        TitleProperties={Text="Use Zombie 1.0 Skin & Face";};
        DescProperties={Text="Use Zombie 1.0's skin tone & face. Only shows for new spawns. (Model, clothing & animations aren't compatible)";};
        Config={
            SettingsKey="UseOldZombies";
            Type="Toggle;Disabled;Enabled";
        };
    });

	super.SettingsKeybindControlsTable = {
		{Order=1; Type="Border"; Text="Rise of the Dead"};

        {Order=2; Type="Option"; Id="KeyToggleSpecial"; Text="Toggle/Trigger Special"; };
        {Order=3; Type="Option"; Id="KeyTogglePat"; Text="Toggle Portable Auto Turret"; };
        
		{Order=500; Type="Border"; Text="Nekron's Gambit"};
		{Order=501; Type="Option"; Id="KeyScoreboardToggle"; Text="Scoreboard"; };
		{Order=502; Type="Option"; Id="KeyWindowGambitShop"; Text="Shop"; };
	};
end

return Settings;