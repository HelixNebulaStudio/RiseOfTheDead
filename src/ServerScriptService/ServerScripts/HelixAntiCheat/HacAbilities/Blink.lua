local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local HacAbility = {}

function HacAbility:OnSniper(player, case, packet)
	local lastPos = packet.A;
	local newPos = packet.B;

	local checkTeleport = case.LastTeleport and (tick()-case.LastTeleport) < 1 or false;

	local cframeLog = case.CFrameLog;
	local lastCframe = cframeLog[#cframeLog];

	local distance = 0;
	if checkTeleport then
		local lastTpCframe = case.TeleportCframeBuffer;
		distance = (newPos - lastTpCframe.Position).Magnitude;
	end

	if checkTeleport == false or distance > 10 then
		task.spawn(function()
			self.LogToAnalytics("Client illegal teleport.");
			Debugger:Warn(player.Name, "Illegal teleport! No tp in last second or Distance:", distance);

			case.LastIllegalMovement = tick();
			case.IllegalCount = case.IllegalCount +1;
		end)

		return false;

	else
		return true;
	end
end

return HacAbility;
