local PageInterface = {};
PageInterface.__index = PageInterface;

local localplayer = game.Players.LocalPlayer;
local modLeaderboardService = shared.require(game.ReplicatedStorage.Library.LeaderboardService);
local modLeaderboardInterface = shared.require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
--==

function PageInterface:Load(interface: Interface, window: InterfaceWindow)
	local keyTable = {
		StatName="Zombie Kills";
		AllTimeTableKey="AllTimeZombieKills";
		YearlyTableKey="YearlyZombieKills";
		SeasonlyTableKey="SeasonlyZombieKills";
		MonthlyTableKey="MonthlyZombieKills";
		WeeklyTableKey="WeeklyZombieKills";
		DailyTableKey="DailyZombieKills";
	};
	
	modLeaderboardService.ClientSyncRequest();
	local newLeaderboard = modLeaderboardInterface.new(keyTable);
	newLeaderboard.Frame.Parent = window.Binds.PageFrame;
end

return PageInterface;