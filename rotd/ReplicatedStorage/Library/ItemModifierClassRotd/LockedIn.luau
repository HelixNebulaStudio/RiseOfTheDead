local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modifierPackage = {
	Name = "Gunslinger Lock-In";
	
	Tags = {
        GunModifier = true;
	};
	Binds = {};
};
--==

function modifierPackage.onRequire()
	if RunService:IsServer() then return end;
end

return modifierPackage;