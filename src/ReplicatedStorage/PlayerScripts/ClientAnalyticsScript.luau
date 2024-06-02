local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ClientGameAnalytics = {};

function ClientGameAnalytics:Init()
	local depGameAnalytics = require(game.ReplicatedStorage.Dependencies:WaitForChild("GameAnalytics"));
	depGameAnalytics:initClient();
end

return ClientGameAnalytics;