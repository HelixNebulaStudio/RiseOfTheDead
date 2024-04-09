local PageInterface = {};
PageInterface.__index = PageInterface;

local localplayer = game.Players.LocalPlayer;
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);
local modLeaderboardInterface = require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
--==

function PageInterface:Load(interface)
	local keyTable = {
		StatName="Pass Level";
		AllTimeTableKey="AllTimeMp";
	};
	
	modLeaderboardService.ClientSyncRequest();
	local newLeaderboard = modLeaderboardInterface.new(keyTable, "AllTime");
	newLeaderboard.Frame.Parent = interface.PageFrame;
end

return PageInterface;