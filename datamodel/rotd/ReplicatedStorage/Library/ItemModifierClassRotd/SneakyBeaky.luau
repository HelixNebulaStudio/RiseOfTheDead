local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modifierPackage = {
	Name = "Sneaky Beaky";

	Tags = {
        GunModifier = true;
        MeleeModifier = true;
    };
	Binds = {};
    Priority = 6;
};
--==

return modifierPackage;