local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local HacAbility = {}

function HacAbility:OnSniper(player, case, packet)
	local gravity = packet.Value;
	
	-- if gravity ~= workspace.Gravity then
	-- 	task.spawn(function()
	-- 		self.LogToAnalytics("Illegal gravity set!");
	-- 		Debugger:Warn(player.Name, "Illegal gravity set!");
	-- 	end)
	-- end
	
	return workspace.Gravity;
end

return HacAbility;
