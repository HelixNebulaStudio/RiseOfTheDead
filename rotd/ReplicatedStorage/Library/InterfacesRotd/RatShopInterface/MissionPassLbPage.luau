local PageInterface = {};
PageInterface.__index = PageInterface;

local localplayer = game.Players.LocalPlayer;
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modLeaderboardService = shared.require(game.ReplicatedStorage.Library.LeaderboardService);
local modLeaderboardInterface = shared.require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);

--==

function PageInterface:Load(interface: Interface, window: InterfaceWindow)
	local remoteLeaderboardService = modRemotesManager:Get("LeaderboardService");

	local modBattlePassLibrary = shared.require(game.ReplicatedStorage.Library.BattlePassLibrary);
	local activeId = modBattlePassLibrary.Active;

	local keyTable = {
		StatName = "Event Level";
		AllTimeTableKey = activeId;
	};
	
	modLeaderboardService.ClientSyncRequest();
	
	local newLeaderboard = modLeaderboardInterface.new(keyTable, "AllTime");
	newLeaderboard.Frame.Parent = window.Binds.PageFrame;
end

return PageInterface;