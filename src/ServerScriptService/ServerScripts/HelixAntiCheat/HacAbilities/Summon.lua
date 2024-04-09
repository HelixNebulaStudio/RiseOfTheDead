local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local HacAbility = {}

function HacAbility:OnSniper(player, case, packet)
	local child = packet.Child;
	
	if child == nil or not player.Character:IsAncestorOf(child) then
		task.spawn(function()
			self.LogToAnalytics("Illegal child added!");
			Debugger:Warn(player.Name, "Illegal child added!");
		end)
		
		return false;
	end
	
	return true;
end

return HacAbility;
