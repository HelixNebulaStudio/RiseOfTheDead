local PageInterface = {};
PageInterface.__index = PageInterface;

local localplayer = game.Players.LocalPlayer;
local modLeaderboardService = shared.require(game.ReplicatedStorage.Library.LeaderboardService);
local modLeaderboardInterface = shared.require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
--==

function PageInterface:Load(interface)
	local modBattlePassLibrary = shared.require(game.ReplicatedStorage.Library.BattlePassLibrary);
	local activeId = modBattlePassLibrary.Active;

	local keyTable = {
		StatName="Event Level";
		AllTimeTableKey=activeId;
	};
	
	modLeaderboardService.ClientSyncRequest();
	local newLeaderboard = modLeaderboardInterface.new(keyTable, "AllTime");
	newLeaderboard.Frame.Parent = interface.PageFrame;
end

return PageInterface;