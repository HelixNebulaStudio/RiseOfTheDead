local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local LeaderboardService = {};
LeaderboardService.Initialized = false;
LeaderboardService.LookUpFuncs = {};

local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local DataStoreService = game:GetService("DataStoreService");

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);

local remoteLeaderboardService = modRemotesManager:Get("LeaderboardService");

local library = {
	AllTimeZombieKills={
		StatName="ZombieKills"; --All time take stat val
		DatastoreName="L_AllTime_ZombieKills";
		DatastoreId="L_AllTime_ZombieKills";
		RanksLimit=100;
	};
	WeeklyZombieKills={
		DataKey="ZombieKills"; --Weekly seperate store stat val;
		DatastoreName="L_Weekly_ZombieKills";
		DatastoreId="L_Weekly_ZombieKills";
		Folder="WeeklyStats";
	};
	DailyZombieKills={
		DataKey="ZombieKills";
		DatastoreName="L_Daily_ZombieKills";
		DatastoreId="L_Daily_ZombieKills";
		Folder="DailyStats";
	};
	---
	AllTimeGoldDonor={
		DataKey="GoldDonor";
		DatastoreName="L_AllTime_GoldDonor";
		DatastoreId="L_AllTime_GoldDonor";
		RanksLimit=100;
		Folder="AllTimeStats";
	};
	WeeklyGoldDonor={
		DataKey="GoldDonor";
		DatastoreName="L_Weekly_GoldDonor";
		DatastoreId="L_Weekly_GoldDonor";
		Folder="WeeklyStats";
	};
	DailyGoldDonor={
		DataKey="GoldDonor";
		DatastoreName="L_Daily_GoldDonor";
		DatastoreId="L_Daily_GoldDonor";
		Folder="DailyStats";
	};
	--- mission pass leaderboard
	AllTimeMp={
		DataKey="AllTimeMp";
		DatastoreName="L_AllTime_MpLevel";
		DatastoreId="L_AllTime_MpLevel";
		RanksLimit=100;
		Folder="AllTimeStats";
	};
}

--== For faction
local factionBoardKey = "FactionMissionScore"
LeaderboardService.FactionBoardKey = factionBoardKey;

library["Seasonly"..factionBoardKey]={
	LookUpKey="Factions";
	Folder="SeasonlyStats";

	DatastoreName="L_Seasonly_"..factionBoardKey;
	DatastoreId="L_Seasonly_"..factionBoardKey;
	RanksLimit=10;
	DataKey=factionBoardKey;
};
library["Monthly"..factionBoardKey]={
	LookUpKey="Factions";
	Folder="MonthlyStats";

	DatastoreName="L_Monthly_"..factionBoardKey;
	DatastoreId="L_Monthly_"..factionBoardKey;
	RanksLimit=25;
	DataKey=factionBoardKey;
};
library["Weekly"..factionBoardKey]={
	LookUpKey="Factions";
	Folder="WeeklyStats";

	DatastoreName="L_Weekly_"..factionBoardKey;
	DatastoreId="L_Weekly_"..factionBoardKey;
	RanksLimit=50;
	DataKey=factionBoardKey;
};


local uploadTimer = 120;
local playerDataCache = {};
--==
LeaderboardService.Library = library;

function LeaderboardService.ClientSyncRequest()
	if not RunService:IsClient() then return end;
	remoteLeaderboardService:FireServer("sync");
end

function LeaderboardService.ClientGamemodeBoardRequest(gameType, gameStage)
	if not RunService:IsClient() then return end;
	remoteLeaderboardService:FireServer("requestgamemode", {Type=gameType; Stage=gameStage});
end


function LeaderboardService.UpdateDatastoreScopes(lbTable)
	if lbTable.Folder == "YearlyStats" then
		local yearEndTick = modSyncTime.TimeOfEndOfYear();
		lbTable.DatastoreId = lbTable.DatastoreName.."/"..yearEndTick;
		
	elseif lbTable.Folder == "SeasonlyStats" then
		local seasonEndTick = modSyncTime.TimeOfEndOfSeason();
		lbTable.DatastoreId = lbTable.DatastoreName.."/"..seasonEndTick;
		
	elseif lbTable.Folder == "MonthlyStats" then
		local monthEndTick = modSyncTime.TimeOfEndOfMonth();
		lbTable.DatastoreId = lbTable.DatastoreName.."/"..monthEndTick;
		
	elseif lbTable.Folder == "WeeklyStats" then
		local weekEndTick = modSyncTime.TimeOfEndOfWeek();
		lbTable.DatastoreId = lbTable.DatastoreName.."/"..weekEndTick;
		
	elseif lbTable.Folder == "DailyStats" then 
		local dayEndTick = modSyncTime.TimeOfEndOfDay();
		lbTable.DatastoreId = lbTable.DatastoreName.."/"..dayEndTick;
		
	end
end

function LeaderboardService.Update(sync)
	if not RunService:IsServer() then return end;
	
	--Player leaderboards;
	local modProfile = shared.modProfile;
	if modProfile == nil then return end;
	playerDataCache = {};
	
	for statKey,_ in pairs(library) do
		local lookupKey = library[statKey].LookUpKey or "Player";
		if lookupKey == "Player" then
			playerDataCache[statKey] = {};
		end
	end

	for _, player in pairs(game.Players:GetChildren()) do
		local playerName = player.Name;
		local profile = modProfile:Find(playerName);

		if profile then
			local avatar = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png";
			pcall(function()
				avatar = game.Players:GetUserThumbnailAsync(profile.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150);
			end)

			pcall(function()
				local activeSave = profile:GetActiveSave();
				local playerKey = tostring(profile.UserId);

				for statKey, info in pairs(library) do
					if info.LookUpKey == nil or info.LookUpKey == "Player" then
						local statValue = 0;
						if info.StatName then
							statValue = activeSave:GetStat(info.StatName);
						else
							statValue = profile[info.Folder][info.DataKey] or 0;
						end
						
						table.insert(playerDataCache[statKey], {
							Name=playerName;
							Avatar=avatar;
							Value=statValue;
							UserId=profile.UserId;
						});
					end
				end
			end)
		end
	end

	for statKey,_ in pairs(library) do
		local lbTable = library[statKey];
		LeaderboardService.LoadLeaderboard(statKey, lbTable, sync);
	end
end

function LeaderboardService.LoadLeaderboard(statKey, lbTable, sync)
	local dataTable = {};
	
	LeaderboardService.UpdateDatastoreScopes(lbTable);
	
	local tag = script:FindFirstChild(statKey);
	if tag == nil then sync = true; end

	local datastoreScope = lbTable.DatastoreId;
	local lookUpKey = lbTable.LookUpKey or "Player";
	local loaded = false;
	
	if sync and (lbTable.LastGetSorted == nil or tick()-lbTable.LastGetSorted >= 60) then
		lbTable.LastGetSorted = tick();

		local s, e = pcall(function()
			Debugger:Log("Downloading leaderboard data for (",statKey,") using datastoreId (",datastoreScope,").");
			
			lbTable.Datastore = DataStoreService:GetOrderedDataStore(datastoreScope);
			local pages = lbTable.Datastore:GetSortedAsync(false, lbTable.RanksLimit or 10);  -- 100 max
			
			local function loadPage(page)
				local pageData = page:GetCurrentPage();
				for a, data in ipairs(pageData) do
					local item = {
						Key=data.key;
						Value=data.value;
						Rank=a;
						Title="n/a";
					};
					
					if lookUpKey == "Player" then
						local userId = tonumber(data.key);
						local username = "[Failed to load]";
						
						pcall(function()
							--if RunService:IsStudio() and userId ~= 16170943 then return; end;
							username = game.Players:GetNameFromUserIdAsync(userId);
						end)

						local avatar = "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=420&height=420&format=png";
						pcall(function()
							if RunService:IsStudio() then return end;
							avatar = game.Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150);
						end)
						
						item.Title = username;
						item.Avatar = avatar;
						item.UserId = userId;
					end
					
					table.insert(dataTable, item);
				end
				loaded = true;
			end
			
			loadPage(pages);
		end)

		if not s then
			Debugger:Warn(e);
		end
		
	end
	
	if not loaded then
		dataTable = LeaderboardService:GetTable(statKey);
	end

	if lookUpKey == "Player" then
		if playerDataCache then
			for a=1, #(playerDataCache[statKey] or {}) do
				local exist = false;

				for b=1, #dataTable do
					if dataTable[b].Title == playerDataCache[statKey][a].Name then
						dataTable[b].Rank = playerDataCache[statKey][a].Rank;
						dataTable[b].Value = playerDataCache[statKey][a].Value;
						exist = true;
						break;
					end
				end

				if not exist then
					local pd = playerDataCache[statKey][a];
					table.insert(dataTable, {Title=pd.Name; Rank=pd.Rank; Value=pd.Value; Avatar=pd.Avatar;});
				end
			end
		end
		
	else
		if LeaderboardService.LookUpFuncs[lookUpKey] then
			LeaderboardService.LookUpFuncs[lookUpKey](dataTable);
		end
		
	end
	
	table.sort(dataTable, function(a, b) return a.Value > b.Value end);
	
	local dataTag = script:FindFirstChild(statKey) or Instance.new("StringValue");
	dataTag.Name = statKey;
	dataTag.Parent = script;
	dataTag.Value = HttpService:JSONEncode(dataTable);
	
	return dataTable;
end

function LeaderboardService.Init(libOverwrite)
	if modConfigurations.DisableLeaderboard == true then return end;
	if not RunService:IsServer() then return end;
	if LeaderboardService.Initialized then return end;
	LeaderboardService.Initialized = true;
	
	if libOverwrite then
		for key, _ in pairs(libOverwrite) do
			library[key] = libOverwrite[key];
		end
	end
	
	remoteLeaderboardService.OnServerEvent:Connect(function(player, action, paramsPacket)
		if action == "sync" then
			local playerName = player.Name;
			local profile = shared.modProfile:Find(playerName);

			if profile and (os.time()-(profile.LeaderstatsTimer or 0)) >= uploadTimer then
				profile.LeaderstatsTimer = os.time();
				
				LeaderboardService:SubmitPlayerToBoard(player);
			end
			
		elseif action == "requestgamemode" then
			local gameType = paramsPacket.Type;
			local gameStage = paramsPacket.Stage;
			
			local gameLib = modGameModeLibrary.GetGameMode(gameType);
			local stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);
			
			if stageLib.LeaderboardKeyTable then
				for statKey, _ in pairs(stageLib.LeaderboardKeyTable) do
					
					if tick()-(stageLib.LeaderboardKeyTable[statKey].LoadTick or 0) >= 300 then
						stageLib.LeaderboardKeyTable[statKey].LoadTick = tick();
						
						LeaderboardService.LoadLeaderboard(statKey, stageLib.LeaderboardKeyTable[statKey], true);
					else
						LeaderboardService.LoadLeaderboard(statKey, stageLib.LeaderboardKeyTable[statKey]);
					end
				end
			end
			
		elseif action == "request" then
			local statKey = tostring(paramsPacket.StatKey);
			
			local keyTable = {
				"AllTime"..statKey;
				"Yearly"..statKey;
				"Seasonly"..statKey;
				"Monthly"..statKey;
				"Weekly"..statKey;
				"Daily"..statKey;
			}
			
			for a=1, #keyTable do
				local key = keyTable[a];

				if library[key] then
					if tick()-(library[key].LoadTick or 0) >= 300 then
						library[key].LoadTick = tick();

						LeaderboardService.LoadLeaderboard(key, library[key], true);
					else
						LeaderboardService.LoadLeaderboard(key, library[key]);
					end
				end
			end
		end
	end)
	
	Debugger:Log("Initializing Leaderboard Service");
	task.spawn(function()
		local loopLength = 300;
		local timer = os.time()-loopLength;
		wait(5);
		while true do
			
			local sync = false;
			if os.time()-timer >= loopLength then
				timer = os.time();
				sync = true;
			end
			
			LeaderboardService.Update(sync);
			task.wait(60);
		end
	end)
end

function LeaderboardService:SubmitToBoard(leaderKey, boardKey, values)
	local statKey = tostring(leaderKey);

	local keyTable = {
		"AllTime"..statKey;
		"Yearly"..statKey;
		"Seasonly"..statKey;
		"Monthly"..statKey;
		"Weekly"..statKey;
		"Daily"..statKey;
	}
	
	for a=1, #keyTable do
		local key = keyTable[a];
		local info = library[key];
		if info == nil then continue end;
		
		local boardValue = values[info.Folder];
		if boardValue == nil then Debugger:Log("No values to submit for ", info, values) continue end;
		
		LeaderboardService.UpdateDatastoreScopes(info);

		Debugger:Log("Leaderboard submitting ("..boardValue..") to ("..key..":/"..boardKey.."). ", info);

		local s, e = pcall(function()
			info.Datastore = DataStoreService:GetOrderedDataStore(info.DatastoreId);

			local budget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync);

			while budget <= 0 do wait(10); end
			
			if boardValue > 0 then
				info.Datastore:UpdateAsync(boardKey, function()
					return tonumber(boardValue);
				end);

			else
				info.Datastore:RemoveAsync(boardKey);

			end
		end)
		if not s then
			Debugger:Warn(e);
		end
	end
end

function LeaderboardService:SubmitPlayerToBoard(player)
	local playerName = player.Name;
	local profile = shared.modProfile:Find(playerName);
	
	
	pcall(function()
		local activeSave = profile:GetActiveSave();
		local playerKey = tostring(profile.UserId);
		
		if playerKey == "16170943" and modBranchConfigs.CurrentBranch.Name == "Live" then
			Debugger:Log("Leaderboard submission disabled for user 16170943");
			return;
		end;
		
		for statKey, info in pairs(library) do
			if info.LookUpKey == nil or info.LookUpKey == "Player" then
				LeaderboardService.UpdateDatastoreScopes(info);

				local statValue = 0;
				if info.StatName then
					statValue = activeSave:GetStat(info.StatName);
					
				else
					statValue = profile[info.Folder][info.DataKey] or 0;
					
				end

				Debugger:Log("Leaderboard submitting player (",playerKey,") statKey (",statKey,") statValue (",statValue,") to datastoreId (",info.DatastoreId,").");

				pcall(function()
					library[statKey].Datastore = DataStoreService:GetOrderedDataStore(info.DatastoreId);

					local budget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync);

					while budget <= 0 do task.wait(10); end
					if statValue > 0 then
						library[statKey].Datastore:UpdateAsync(playerKey, function()
							return tonumber(statValue), {player.UserId};
						end);

					else
						library[statKey].Datastore:RemoveAsync(playerKey);

					end
				end)
			end
		end
	end)
end

function LeaderboardService:GetTable(key)
	local tag = script:FindFirstChild(key);
	if tag then
		return HttpService:JSONDecode(tag.Value);
	end
	return {};
end

return LeaderboardService;