local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local StatusClass = require(script.Parent.StatusClass).new();
local localPlayer = game.Players.LocalPlayer;
--==

function StatusClass.OnExpire(classPlayer, status)
	if classPlayer:GetInstance() ~= localPlayer then return; end
	Debugger:Log("Melee Fury expired")
end

return StatusClass;