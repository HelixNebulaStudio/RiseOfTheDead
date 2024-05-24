local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);

local library = modLibraryManager.new();
--==
library.BuyLevelCost = 1000;
library.PostRewardLvlFmod = 5;

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(library); end

if library.Active then
	local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);

	modLeaderboardService.Library[library.Active]={
		DataKey=library.Active;
		DatastoreName=`L_{library.Active}_MpLevel`;
		DatastoreId=`L_{library.Active}_MpLevel`;
		RanksLimit=100;
		Folder="AllTimeStats";
	};
	
end

return library;