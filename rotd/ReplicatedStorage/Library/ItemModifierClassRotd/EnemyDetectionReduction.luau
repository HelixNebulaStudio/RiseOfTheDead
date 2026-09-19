local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Enemy Detection Reduction";

	Tags = {};
	Binds = {};
};

--==
function modifierPackage.onRequire()
	if RunService:IsClient() then return end;
end

return modifierPackage;