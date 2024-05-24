local PageInterface = {};
PageInterface.__index = PageInterface;

local localplayer = game.Players.LocalPlayer;
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);
local modLeaderboardInterface = require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
--==

function PageInterface:Load(interface)
	local modBattlePassLibrary = require(game.ReplicatedStorage.Library.BattlePassLibrary);
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