local PageInterface = {};
PageInterface.__index = PageInterface;

local localplayer = game.Players.LocalPlayer;
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);
local modLeaderboardInterface = require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
--==

function PageInterface:Load(interface)
	local keyTable = {
		StatName="Zombie Kills";
		AllTimeTableKey="AllTimeZombieKills";
		WeeklyTableKey="WeeklyZombieKills";
		DailyTableKey="DailyZombieKills";
	};
	
	modLeaderboardService.ClientSyncRequest();
	local newLeaderboard = modLeaderboardInterface.new(keyTable);
	newLeaderboard.Frame.Parent = interface.PageFrame;
end

return PageInterface;
