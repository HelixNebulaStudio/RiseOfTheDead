local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TAGSIZEMIN, TAGSIZEMAX = 3, 10;

local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local DataStoreService = game:GetService("DataStoreService");
local MessagingService = game:GetService("MessagingService");
local TextService = game:GetService("TextService");
local TeleportService = game:GetService("TeleportService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBitFlags = require(game.ReplicatedStorage.Library.BitFlags);
local modSerializer = require(game.ReplicatedStorage.Library.Serializer);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modNpcProfileLibrary = require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);

local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

local FactionGroup = require(script:WaitForChild("FactionGroup"));
local FactionUser = require(script:WaitForChild("FactionUser"));
local FactionMeta = require(script:WaitForChild("FactionMeta"));


local remoteFactionService = modRemotesManager:Get("FactionService");

local factionsDatabase = modDatabaseService:GetDatabase("FactionsTest2"); --Can't change this anymore;
local factionSerializer = modSerializer.new();

local takenFactionTags = {
	["metalist"]=true;
	["khronos"]=true;
	["gods"]=true;
	["roblox"]=true;
	["rotd"]=true;
	["almdes"]=true;
	["developer"]=true;
	["devoloper"]=true;
	["devs"]=true;
};
for class, _ in pairs(modNpcProfileLibrary.ClassColors) do
	takenFactionTags[class:lower()] = true;
	takenFactionTags[class:lower().."s"] = true;
end

modRewardsLibrary:Add{
	Id="factionMissions";
	Rewards={
		{Name="Food Scavenge"; Id=35; Chance=1;};
		{Name="Horde Clearance"; Id=59; Chance=1/2;};
		{Name="Ammo Manufacturing"; Id=61; Chance=1/2;};
		{Name="Deadly Zeniths Strike"; Id=73; Chance=1/5;};
		{Name="Reconnaissance Duty"; Id=60; Chance=1/10;};
	};
};

local missionRestoreDuration = 300;

local globalFactionMeta, lastMetaUpdate;
--== Script;

--======= Factions
local Factions = {};
Factions.Database = factionsDatabase;

local function refreshFaction(factionGroup)
	local unixTimestamp = DateTime.now().UnixTimestamp;

	for userId, _ in pairs(factionGroup.JoinRequests) do
		if factionGroup.Members[userId] then
			factionGroup.JoinRequests[userId] = nil;
		end
	end

	for a=1, 3 do
		local activeMission = factionGroup.Missions.Active[a];
		if activeMission == nil then continue end;

		if activeMission.Id == nil then
			factionGroup.Missions.Active[a] = nil;

		elseif unixTimestamp >= activeMission.CompletionTick then
			factionGroup.Missions.Active[a].Completed = true;
			
		end
	end
end


--======= FactionMeta, mainly for listing like searches or leaderboards
function Factions.SearchMetaList(searchInput)
	if globalFactionMeta == nil then
		Factions.RefreshMetaList();

	elseif tick()-lastMetaUpdate >= 10 then
		Factions.RefreshMetaList();
	end

	local list = {};
	for tag, metaObj in pairs(globalFactionMeta.List) do
		if #tag > TAGSIZEMIN and tag:lower():find(searchInput:lower()) then
			list[tag] = metaObj;
		end
	end

	return list;
end



factionsDatabase:OnUpdateRequest("updatemetalist", function(requestPacket)
	local factionMeta = requestPacket.Data;
	local facData = requestPacket.Values;

	factionMeta:Set(facData.Tag, facData);

	return factionMeta;
end)

function Factions.RefreshMetaList()
	globalFactionMeta = factionsDatabase:Get("metalist");
	if globalFactionMeta == nil then
		Debugger:Warn("Could not load metalist.");
		globalFactionMeta = FactionMeta.new();
	end
	lastMetaUpdate = tick();
end

function Factions.UpdateMetaList(factionObj)
	task.spawn(function()
		if factionObj == nil or factionObj.Tag == nil then
			Debugger:Warn("Failed to update metalist.",debug.traceback());
			return;
		end
		factionsDatabase:UpdateRequest("metalist", "updatemetalist", {
			Tag=factionObj.Tag;
			Title=factionObj.Title;
			Icon=factionObj.Icon;
			Color=factionObj.Color;
		});
	end)
end
--======= FactionMeta


function Factions.Get(tag)
	local factionGroup;
	
	local s, e = pcall(function()
		factionGroup = factionsDatabase:Get(tostring(tag));
	end) if not s then Debugger:Warn("Failed to get: ", e); end;
	
	return factionGroup;
end


function Factions.GetUser(userId)
	local factionUser;
	local s, e = pcall(function()
		factionUser = factionsDatabase:Get(tostring(userId));
	end) if not s then Debugger:Warn("Failed to getUser: ", e); end;

	return factionUser;
end


function Factions.SyncUser(userId, data)
	task.spawn(function()
		Debugger:Log("PublishMessage", "Msg"..userId);

		local packet = {
			Request = "SyncFactionUser";
		};
		if data then
			for k,v in pairs(data) do
				packet[k] = v;
			end
		end
		MessagingService:PublishAsync("Msg"..userId, packet);
	end)
end


function Factions.SetUserFaction(userId, factionTag)
	local tL = tick();
	local returnPacket = factionsDatabase:UpdateRequest(userId, "setuserfaction", factionTag);
	
	Debugger:Log("SetUserFaction returns:",returnPacket.Data," in ", math.floor((tick()-tL)*1000)/1000 ,"s");

	return returnPacket.Data;
end

function Factions.SubmitLeaderboard(factionGroup)
	task.spawn(function()
		local lbKey = modLeaderboardService.FactionBoardKey;

		modLeaderboardService:SubmitToBoard(lbKey, factionGroup.Tag, {
			WeeklyStats=(factionGroup["W_"..lbKey] or 0);
			DailyStats=(factionGroup["D_"..lbKey] or 0);
		});
	end)
end


factionsDatabase:OnUpdateRequest("setuserfaction", function(requestPacket)
	local factionUser = requestPacket.Data or FactionUser.new(requestPacket.Key);
	local newTag = requestPacket.Values;

	if newTag == nil or #newTag < 3 then
		requestPacket.FailMsg = "Faction tag too short.";
		return;
	end

	factionUser.Tag = newTag;

	return factionUser;
end)


factionsDatabase:OnUpdateRequest("updatemember", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;

	if factionGroup.Members[values.UserId] == nil then
		requestPacket.FailMsg = "Player not in faction";
		return;
	end
	
	factionGroup:SetMember(values.FactionUser);
	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("refresh", function(requestPacket)
	local unixTimestamp = DateTime.now().UnixTimestamp;
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;
	
	for memberId, memberData in pairs(factionGroup.Members) do
		if values.DelMembers[memberId] then -- No longer in faction.
			factionGroup:Notify(memberData.Name.." has been removed from the faction.");
			factionGroup:DelMember(memberId);

		elseif values.UpdateUsers[memberId] then
			local factionUser = values.UpdateUsers[memberId];
			
			if memberId == values.InvokerUserId then
				factionUser.LastActive = unixTimestamp;
			end
			
			factionGroup:SetMember(factionUser);

		end
	end

	factionGroup.LastUpdate = unixTimestamp;
	
	if values.RefreshPacket then
		for k,v in pairs(values.RefreshPacket) do
			if factionGroup[k] ~= nil then
				factionGroup[k] = v;
			end
		end
	end
	
	if values.HqHost then
		factionGroup:SetHqHost(values.HqHost);
	end
	
	refreshFaction(factionGroup);

	if unixTimestamp-factionGroup.Missions.LastRoll >= missionRestoreDuration then
		local loopCount = math.floor((unixTimestamp-factionGroup.Missions.LastRoll)/missionRestoreDuration);
		factionGroup.Missions.LastRoll = unixTimestamp;

		local availableMission = factionGroup.Missions.Available;

		for a=#availableMission, 1, -1 do
			if unixTimestamp-availableMission[a].RollTime >= shared.Const.OneDaySecs then
				table.remove(availableMission, a);
			end
		end

		for a=1, math.min(loopCount, 10) do
			if #availableMission < 10 then
				local roll = modDropRateCalculator.RollDrop(modRewardsLibrary:Find("factionMissions"), factionGroup.PseudoRandom.Player);
				if #roll > 0 then
					local rolledMission = roll[1];

					local existCount = 0;

					for a=1, #availableMission do
						if availableMission[a].Id == rolledMission.Id then
							existCount = existCount +1;
						end
					end

					if existCount < 2 then
						table.insert(factionGroup.Missions.Available, {
							Id=rolledMission.Id;
							RollTime=unixTimestamp;
						});
					end
				end

			else
				break;

			end
		end
	end
	
	task.spawn(function()
		Factions.SubmitLeaderboard(factionGroup);
	end)
	
	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("sendjoinrequest", function(requestPacket)
	local unixTimestamp = DateTime.now().UnixTimestamp;
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;
	
	local userId = values.UserId;
	local playerName = values.PlayerName;

	if factionGroup.Owner == userId then
		factionGroup:AddMember({UserId=userId; Name=playerName; LastActive=unixTimestamp});
		
		if requestPacket.Publish then
			factionGroup:Notify(playerName.." has joined the faction.");
		end

	else
		-- local joinRequestsCount = 0;
		-- for memberUserId, requestData in pairs(factionGroup.JoinRequests) do
		-- 	local requestAge = unixTimestamp - (requestData.LastSent or 0);
			
		-- 	if requestAge <= shared.Const.OneDaySecs*30 then
		-- 		joinRequestsCount = joinRequestsCount+1;
				
		-- 	else
		-- 		factionGroup.JoinRequests[memberUserId] = nil;
				
		-- 	end
		-- end;
		
		-- if joinRequestsCount >= 16 then
		-- 	requestPacket.FailMsg = "Join requests queue is full.";
		-- 	return factionGroup;
		-- end

		if requestPacket.Publish then
			local joinRequestsCount = 0;
			for memberUserId, requestData in pairs(factionGroup.JoinRequests) do
				joinRequestsCount = joinRequestsCount+1;
			end

			if joinRequestsCount > 16 then
				for a=1, (joinRequestsCount-16) do
					factionGroup.JoinRequests[(next(factionGroup.JoinRequests))] = nil;
				end
			end
		end

		factionGroup.JoinRequests[tostring(userId)] = {
			LastSent=unixTimestamp;
			Name=playerName;
		};
		factionGroup:Log("sentjoinrequest", {playerName});
	end
	Debugger:StudioWarn("factionGroup.JoinRequests", factionGroup.JoinRequests);
	
	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("leavefaction", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local userId = tostring(requestPacket.Values);

	local userObj = factionGroup.Members[userId];
	
	local leaveSucess = factionGroup:DelMember(userId, "leave");
	
	if not leaveSucess then
		requestPacket.FailMsg = "Failed to leave";
		return;
	end
	
	factionGroup:Log("leave", {userId});
	
	if requestPacket.Publish then
		factionGroup:Notify(userObj.Name.." has left the faction.");
	end
	
	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("kickuser", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;
	
	local kickUserId = tostring(values.KickUserId);
	local userId = values.UserId;

	if not factionGroup:HasPermission(userId, "KickUser", {UserId=kickUserId;}) then
		requestPacket.FailMsg = "Insufficient permissions";
		return;
	end

	local userObj = factionGroup.Members[kickUserId];
	local kickSucess = factionGroup:DelMember(kickUserId, "kick");
	
	if not kickSucess then
		requestPacket.FailMsg = "Failed to kick";
		return;
	end
	
	factionGroup:Log("kick", {userId; kickUserId});
	
	if requestPacket.Publish then
		factionGroup:Notify(userObj.Name.." has been kicked from the faction.");
	end

	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("setrole", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;
	
	local targetUserId = values.TargetUserId;
	local setRoleKey = values.SetRoleKey;
	local userId = values.UserId;

	if not factionGroup:HasPermission(userId, "AssignRole", {UserId=targetUserId;}) then
		requestPacket.FailMsg = "Insufficient permissions";
		return;
	end

	local setterRole = factionGroup.Members[userId]
	local targetRole = factionGroup.Roles[setRoleKey];

	if setterRole == nil or setterRole.Role == setRoleKey then
		requestPacket.FailMsg = "Set Role invalid";
		return;
	end

	if targetRole and factionGroup.Members[targetUserId] then
		local setterRoleData = factionGroup.Roles[setterRole and setterRole.Role or "Member"];
		if setterRoleData.Rank >= targetRole.Rank then
			return;
		end

		local member = factionGroup.Members[targetUserId];

		local oldRole = factionGroup.Roles[member.Role or "Member"];

		member.Role = setRoleKey;

		if requestPacket.Publish then
			local rankDiff = math.floor(oldRole.Rank/10) - math.floor(targetRole.Rank/10);
			if rankDiff >= 0 then
				factionGroup:Notify(member.Name.." has been promoted to ("..targetRole.Title..").");

			elseif rankDiff < 0 then
				factionGroup:Notify(member.Name.." has been demoted to ("..targetRole.Title..").");

			else
				factionGroup:Notify(member.Name.."'s role set to ("..targetRole.Title..").");
			end
			
			factionGroup:Log("setrole", {userId; targetUserId; targetRole.Title});
		end
	end
	
	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("configrole", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;
	
	local roleKey, configs, userId = values.RoleKey, values.Configs, values.UserId;

	if not factionGroup:HasPermission(userId, "ConfigRole", {RoleKey=roleKey; Rank=configs.Rank}) then
		requestPacket.FailMsg = "Insufficient permissions";
		return;
	end

	local rolesCount = 0;
	for k, _ in pairs(factionGroup.Roles) do
		rolesCount = rolesCount +1;
	end

	local oldRoleConfig = factionGroup.Roles[roleKey];
	if factionGroup.Roles[roleKey] == nil and roleKey == "__new" then
		if rolesCount > 20 then
			requestPacket.FailMsg = "Too many roles";
			return;
		end
		
		factionGroup.RoleKeyCount = factionGroup.RoleKeyCount +1;
		local newKey = tostring(factionGroup.RoleKeyCount);

		factionGroup:SetRole(newKey, configs);
		if requestPacket.Publish then
			factionGroup:Log("newrole", {userId; configs.Title});
		end
		
	else
		factionGroup:SetRole(roleKey, configs);
		if requestPacket.Publish then
			factionGroup:Log("configrole", {userId; oldRoleConfig.Title});
		end
		
	end
	
	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("deleterole", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;

	local roleKey = values.RoleKey;
	local userId = values.UserId;

	if not factionGroup:HasPermission(userId, "ConfigRole", {RoleKey=roleKey}) then
		requestPacket.FailMsg = "Insufficient permissions";
		return;
	end

	local roleConfig = factionGroup.Roles[roleKey];
	if roleConfig == nil then
		requestPacket.FailMsg = "Role does not exist";
		return;
	end
	
	factionGroup:DelRole(roleKey);
	
	if requestPacket.Publish then
		factionGroup:Log("delrole", {userId; roleConfig.Title});
	end
	
	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("settings", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;

	local userId = values.UserId;
	local titleInput = values.SettingsPacket.TitleInput;
	local descInput = values.SettingsPacket.DescInput;
	local iconInput = tostring(values.SettingsPacket.IconInput);
	local colorInput = values.SettingsPacket.ColorInput;


	if not factionGroup:HasPermission(userId, "EditInfo") then
		requestPacket.FailMsg = "Insufficient permissions";
		return;
	end

	if titleInput and #titleInput >= 5 and #titleInput <= 40 then
		factionGroup.Title = titleInput;
		
	end

	
	if descInput and #descInput > 1 and #descInput <= 500 then
		factionGroup.Description = descInput;
	end
	
	if iconInput and #iconInput > 0 then
		factionGroup.Icon = iconInput;
	end
	
	factionGroup.Color = colorInput or factionGroup.Color;
	
	if requestPacket.Publish then
		factionGroup:Log("editinfo", {userId;}); 
	end

	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("handlejoinrequest", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;
	
	
	local acceptRequest = values.AcceptRequest;
	local hostUserId = values.UserId;
	
	local targetFactionUser = values.FactionUser;
	local requesterName = targetFactionUser.Name;
	

	if not factionGroup:HasPermission(hostUserId, "HandleJoinRequests") then
		requestPacket.FailMsg = "Insufficient permissions";
		return;
	end
	
	local memCount = 0;
	for userIds, userObj in pairs(factionGroup.Members) do 
		memCount = memCount +1;
	end;
	if memCount >= 50 then
		requestPacket.FailMsg = "Faction is full.";
		return;
	end
	
	if acceptRequest == true then
		
		if targetFactionUser == nil then
			requestPacket.FailMsg = "Nil targetFactionUser";
			return;
		end
		
		factionGroup:AcceptJoinRequest(targetFactionUser.UserId, targetFactionUser);
		factionGroup:Log("acceptinvite", {hostUserId; requesterName;}); 
		
		if requestPacket.Publish then
			factionGroup:Notify(requesterName.." has joined the faction.");
		end
		
	else
		factionGroup:Log("denyinvite", {hostUserId; requesterName;}); 
		
	end

	factionGroup.JoinRequests[targetFactionUser.UserId] = nil;
	
	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("startmission", function(requestPacket)
	Debugger:Log("[OnUpdateRequest] startmission ", requestPacket.ReqId);
	local factionGroup = requestPacket.Data;
	local actionPacket = requestPacket.Values;

	local missionData = factionGroup.Missions;
	
	local missionId = actionPacket.MissionId;
	local missionStartTime = actionPacket.MissionStartTime;

	local missionLib = modMissionLibrary.Get(missionId);
	if missionLib == nil then
		requestPacket.FailMsg = "Mission id (".. missionId ..") does not exist in mission lib.";
		return 
	end;

	local vacantIndex = nil;
	for a=1, 3 do
		if missionData.Active[a] == nil then
			vacantIndex = a;
			break;
		end
	end
	
	if vacantIndex == nil then
		requestPacket.FailMsg = "No vacant mission index available "..Debugger:Stringify(missionData.Active);
		return;
	end

	local exist = false;
	for a=1, #missionData.Available do
		if missionData.Available[a].Id == missionId then
			exist = true;

			table.remove(missionData.Available, a);
			break;
		end
	end
	
	if exist == false then
		requestPacket.FailMsg = "Attempt to start non-available mission (".. missionId ..") "..Debugger:Stringify(missionData.Available);
		return;
	end

	if missionLib.OneAtATime then
		local alreadyActive = false;
		for _, activeData in pairs(missionData.Active) do
			if activeData.Id == missionId then
				alreadyActive = true;
				break;
			end
		end
		
		if alreadyActive then
			requestPacket.FailMsg = "Only can have one at a time (".. missionId ..")"
			return;
		end
	end
	
	
	if tostring(actionPacket.QuotaLimit):lower() == "max" then
		actionPacket.QuotaLimit = 99;
	end
	local maxMissionQuota = missionLib.QuotaLimit or 99;
	local missionQuota = math.clamp(tonumber(actionPacket.QuotaLimit) or maxMissionQuota, 1, maxMissionQuota);


	local accessType = "Everyone";
	if actionPacket.AccessType then
		if tostring(actionPacket.AccessType) == "Roles" then
			accessType = "Roles";
		elseif tostring(actionPacket.AccessType) == "Members" then
			accessType = "Members";
		end
	end


	local accessValue = {};
	if typeof(actionPacket.AccessValue) == "table" and #actionPacket.AccessValue > 0 and #actionPacket.AccessValue <= 50 then
		for a=1, #actionPacket.AccessValue do
			table.insert(accessValue, actionPacket.AccessValue[a]);
		end
	end
	
	local expireTime = missionLib.ExpireTime;
	missionData.Active[vacantIndex] = {
		Id=missionId;
		CompletionTick=missionStartTime + expireTime;
		AccessType=accessType;
		AccessValue=accessValue;
		QuotaLimit=missionQuota;
		Players={};
	}
	
	requestPacket.VacantIndex = vacantIndex;
	
	if requestPacket.Publish then
		factionGroup:Log("startmission", {requestPacket.Values.UserId; missionLib.Name});
		factionGroup:Notify("Faction mission \"".. missionLib.Name .."\" is now available.", "Reward");
		--Debugger:Log("startmission ", factionGroup.Tag, actionPacket);
	end

	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("completemission", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local actionPacket = requestPacket.Values;

	local unixTime = DateTime.now().UnixTimestamp;
	local missionData = factionGroup.Missions;
	local activeIndex = actionPacket.ActiveIndex;

	local activeMission = missionData.Active[activeIndex];
	local missionTimeLeft = activeMission and (activeMission.CompletionTick-unixTime) or nil;
	if activeMission == nil or missionTimeLeft > 0 then Debugger:Log("missionTimeLeft", missionTimeLeft) return end

	local missionLib = modMissionLibrary.Get(activeMission.Id);
	if missionLib == nil then return end;

	local playerCount = 0;
	local successCount = 0;
	for userId, playerMissionData in pairs(activeMission.Players) do
		playerCount = playerCount +1;
		
		if playerMissionData.MissionStatus == 3 then
			successCount = successCount +1;
		end
	end
	local failCount = playerCount-successCount;

	local successCriteria = missionLib.FactionSuccessCriteria;
	local missionResult;
	if successCriteria then
		missionResult = true;
		
		if successCriteria.SuccessfulAgents and successCount < successCriteria.SuccessfulAgents then
			if RunService:IsStudio() then
				Debugger:Warn("[Studio] Unsuccessful cancelled: successCount < successCriteria.SuccessfulAgents");
			else
				missionResult = "At least ".. successCriteria.SuccessfulAgents .." agents are required to successfully completed the mission.";
			end
		end
		
	else
		missionResult = true;

	end
	
	Debugger:Warn(factionGroup.Tag,"missionResult",missionResult);

	
	if missionResult == true then -- mission succesful;
		local rewards = missionLib.FactionRewards;
		local missionScore = 1;
		
		for a=1, #rewards do
			local rewardType = rewards[a].Type;
			local rewardId = rewards[a].Id;
			local rewardValue = rewards[a].Value;

			if rewardType == "Resource" then
				factionGroup:AddResources(rewardId, rewardValue, requestPacket.Publish);
				Debugger:Log(missionLib.Name,"Claim reward", rewardId, " = ", rewardValue);
				
			elseif rewardType == "Score" then
				missionScore = rewardValue;
				factionGroup:AddScore(rewardValue or 1);

			elseif rewardType == "Gold" then
				if factionGroup.TestGoldReward == true then
					factionGroup:AddGold(rewardValue, "mission"..missionLib.MissionId, "Completing mission, ".. missionLib.Name);
					
				else
					Debugger:Log(missionLib.Name,"TestGoldReward disabled to add gold: ", rewardValue);
					
				end
				
			end
		end

		
		for userId, playerMissionData in pairs(activeMission.Players) do
			if requestPacket.Publish then
				task.spawn(function()
					local rPacket = factionsDatabase:UpdateRequest(userId, "user_missionsuccess", {
						MissionId=missionLib.MissionId;
						MissionScore=missionScore;
					});
					if not rPacket.Success then
						Debugger:Warn("Failed to set faction mission stats:",rPacket.FailMsg);
					end
				end)
			end
				
			local memberData = factionGroup.Members[userId];
			
			if memberData then
				memberData.SuccessfulMissions = memberData.SuccessfulMissions or {};
				memberData.SuccessfulMissions.This = (memberData.SuccessfulMissions.This or 0) +1;
				memberData.SuccessfulMissions.Total = (memberData.SuccessfulMissions.Total or 0) +1;
				
				memberData.ScoreContribution = memberData.ScoreContribution or {};
				memberData.ScoreContribution.This = (memberData.ScoreContribution.This or 0) + missionScore;
				memberData.ScoreContribution.Total = (memberData.ScoreContribution.Total or 0) + missionScore;
			end
		end
		
	else
		-- faction mission failed;
	end

	
	Debugger:Log("completemission activeMission missionData", activeMission, missionData);
	missionData.Active[activeIndex] = nil;

	if requestPacket.Publish then
		factionGroup:Log("completemission", {actionPacket.UserId; missionLib.Name; missionResult});
		Debugger:Log("Publish completemission activeMission missionData", activeMission, missionData);
		
	end

	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("addmission", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local actionPacket = requestPacket.Values;

	local unixTime = DateTime.now().UnixTimestamp;
	
	local missionId = actionPacket.MissionId;
	
	table.insert(factionGroup.Missions.Available, {
		Id=missionId;
		RollTime=unixTime;
	});
	
	return factionGroup;
end)

factionsDatabase:OnUpdateRequest("updatemission", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local actionPacket = requestPacket.Values;

	local unixTime = DateTime.now().UnixTimestamp;
	local missionData = factionGroup.Missions;

	local activeIndex = actionPacket.ActiveIndex;
	local activeMission = missionData.Active[activeIndex];
	if activeMission == nil then
		requestPacket.FailMsg = "Mission missing (".. activeIndex ..") ".. Debugger:Stringify(missionData.Active);
		return
	end

	if activeMission.Players[actionPacket.UserId] == nil then
		requestPacket.FailMsg = "User ".. actionPacket.UserId .." not in mission";
		return;
	end
	
	local playerData = activeMission.Players[actionPacket.UserId];
	
	if playerData.MissionStatus == 1 and actionPacket.StatusUpdate == 3 then
		playerData.MissionStatus = 3;
		
		playerData.MissionData = actionPacket.MissionData;

		local timeReduction = (activeMission.CompletionTick-unixTime) * 0.1
		local newCompletionTick = activeMission.CompletionTick - timeReduction;
		activeMission.CompletionTick = newCompletionTick;

		Debugger:Log("joined mission", activeMission, " time reduction: ", timeReduction);
		Debugger:Log("User completed mission ", playerData);
		
	elseif playerData.MissionStatus == 1 and actionPacket.StatusUpdate == 4 then
		playerData.MissionStatus = 4;
		playerData.MissionData = actionPacket.MissionData;

		Debugger:Log("User failed mission ", playerData);
	end
	
	return factionGroup;
end)


factionsDatabase:OnUpdateRequest("joinmission", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local actionPacket = requestPacket.Values;
	
	local unixTime = DateTime.now().UnixTimestamp;
	local missionData = factionGroup.Missions;
	
	local activeIndex = actionPacket.ActiveIndex;
	local missionJoinTime = actionPacket.MissionJoinTime;

	local activeMission = missionData.Active[activeIndex];
	if activeMission == nil then
		requestPacket.FailMsg = "Mission missing (".. activeIndex ..") ".. Debugger:Stringify(missionData.Active);
		return
	end
	
	if activeMission.CompletionTick-missionJoinTime <= 10 then
		requestPacket.FailMsg = "Too late to join mission";
		return
	end

	local missionLib = modMissionLibrary.Get(activeMission.Id);
	if missionLib == nil then
		requestPacket.FailMsg = "Invalid mission Id";
		return
	end;

	if activeMission.Players[actionPacket.UserId] then
		requestPacket.FailMsg = "Already in mission";
		return;
	end
	
	local function doInsufficientResource(rId)
		requestPacket.FailMsg = "Insufficient Resources: ".. rId;
		return;
	end
	
	local costs = missionLib.FactionCosts;
	for a=1, #costs do
		local costType = costs[a].Type;
		local costId = costs[a].Id;
		local costValue = costs[a].Value;

		if costType == "Resource" then
			if factionGroup.Resources[costId] < costValue then
				doInsufficientResource(costId);
				return;
			end
		end
	end
	
	for a=1, #costs do
		local costType = costs[a].Type;
		local costId = costs[a].Id;
		local costValue = costs[a].Value;

		if costType == "Resource" then
			factionGroup:AddResources(costId, -costValue, requestPacket.Publish);
			Debugger:Log(missionLib.Name,"Deduct Cost", costId, " = ", costValue);
		end
	end

	activeMission.Players[actionPacket.UserId] = {JoinTime=missionJoinTime; MissionStatus=1;};

	if requestPacket.Publish then
		Debugger:Log("Publish:",requestPacket.Publish,"joined mission", activeMission);
	end
	
	return factionGroup;
end)

factionsDatabase:OnUpdateRequest("clearmission", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local actionPacket = requestPacket.Values;

	local unixTime = DateTime.now().UnixTimestamp;
	local missionData = factionGroup.Missions;

	local activeIndex = actionPacket.ActiveIndex;
	local expireTime = actionPacket.ExpireTime or 0;
	
	local activeMission = missionData.Active[activeIndex];
	if activeMission == nil then
		requestPacket.FailMsg = "Mission missing";
		return
	end

	activeMission.CompletionTick = unixTime + expireTime;
	
	return factionGroup;
end)

factionsDatabase:OnUpdateRequest("addscore", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;

	if requestPacket.Publish then
		Debugger:Log("addscore", values);
		factionGroup:AddScore(values);
	end
	return factionGroup;
end)

factionsDatabase:OnUpdateRequest("addresource", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;
	
	factionGroup:AddResources(values.Id, values.Value, requestPacket.Publish);
	
	return factionGroup;
end)

factionsDatabase:OnUpdateRequest("addgold", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local actionPacket = requestPacket.Values;
	
	local amount = actionPacket.Amount;
	local reason = actionPacket.Reason;
	local analyticsKey = actionPacket.AnalyticsKey;
	
	if amount == "testgold" then
		factionGroup.TestGoldReward = not factionGroup.TestGoldReward;
		requestPacket.FailMsg = "Test gold toggled: ".. tostring(factionGroup.TestGoldReward);
		return
	end
	
	if typeof(amount) ~= "number" then
		requestPacket.FailMsg = "Invalid amount input.";
		return
	end
	
	if factionGroup.TestGoldReward == false then 
		requestPacket.FailMsg = "Gold reward not enabled on this faction.";
		return
	end;
	
	factionGroup:AddGold(amount, analyticsKey, reason);
	
	return factionGroup;
end)

factionsDatabase:OnUpdateRequest("sethqaccesscode", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;
	
	if factionGroup.HqAccessCode == "" then
		factionGroup.HqAccessCode = values;
	end
	
	return factionGroup;
end)

factionsDatabase:OnUpdateRequest("sethqhost", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;

	if not factionGroup:HasPermission(values.UserId, "CustomizeHq") then
		requestPacket.FailMsg = "Insufficient permissions";
		
		requestPacket.HqHost = factionGroup.HqHost;
		return;
	end
	
	if values.HostName then
		factionGroup:SetHqHost(values.HostName);
		if factionGroup.HqHost == values.HostName then
			factionGroup.SafehomeId = values.SafehomeId;
			
			factionGroup:Log("sethqhost", {values.UserId; values.HostName});
		end
		
	else
		factionGroup.SafehomeId = values.SafehomeId;
		
	end

	requestPacket.HqHost = factionGroup.HqHost;
	
	return factionGroup;
end)

factionsDatabase:OnUpdateRequest("customizeHq", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;

	if not factionGroup:HasPermission(values.UserId, "CustomizeHq") then
		requestPacket.FailMsg = "Insufficient permissions";
		return;
	end

	local inputGroupId = values.GroupId;
	local inputGroupData = values.GroupData;
	
	if factionGroup.SafehomeCustomizations[inputGroupId] == nil then
		factionGroup.SafehomeCustomizations[inputGroupId] = {};
	end
	
	local groupData = factionGroup.SafehomeCustomizations[inputGroupId];
	
	if inputGroupData.Color then
		groupData.Color = inputGroupData.Color;
	end
	
	return factionGroup;
end)

factionsDatabase:OnUpdateRequest("settesttoggle", function(requestPacket)
	local factionGroup = requestPacket.Data;
	local values = requestPacket.Values;
	
	local testKey = values.TestKey;
	
	if testKey:sub(1, 4) == "Test" then
		if typeof(factionGroup[testKey]) == "boolean" then
			factionGroup[testKey] = values.TestValue;
			
			requestPacket.ReturnValue =	factionGroup[testKey];
		end
	end
	
	return factionGroup;
end)

--== OnUpdateRequest for FactionUser
factionsDatabase:OnUpdateRequest("user_clearfaction", function(requestPacket)
	return requestPacket.Data:SetFaction();
end)


factionsDatabase:OnUpdateRequest("user_reset", function(requestPacket)
	local factionUser = requestPacket.Data;
	factionUser.Role = "Member";
	factionUser:SetFaction();
	
	return factionUser;
end)


factionsDatabase:OnUpdateRequest("user_setrole", function(requestPacket)
	local factionUser = requestPacket.Data;
	local values = requestPacket.Values;

	factionUser:SetRole(values.NewRole);
	
	return factionUser;
end)


factionsDatabase:OnUpdateRequest("user_setfaction", function(requestPacket)
	local factionUser = requestPacket.Data or FactionUser.new(requestPacket.Key);
	local values = requestPacket.Values;
	
	factionUser.Name = values.PlayerName;
	factionUser:SetFaction(values.NewFactionTag);
	factionUser:SetRole(values.Role);
	factionUser.LastActive = DateTime.now().UnixTimestamp;
	
	return factionUser;
end)

factionsDatabase:OnUpdateRequest("user_missionsuccess", function(requestPacket)
	local factionUser = requestPacket.Data;
	local values = requestPacket.Values;
	
	local missionId = values.MissionId;
	local missionScore = values.MissionScore;
	
	factionUser.SuccessfulMissions.This = factionUser.SuccessfulMissions.This +1;
	factionUser.SuccessfulMissions.Total = factionUser.SuccessfulMissions.Total +1;

	factionUser.ScoreContribution.This = factionUser.ScoreContribution.This + missionScore;
	factionUser.ScoreContribution.Total = factionUser.ScoreContribution.Total + missionScore;
	
	local function updateMissionInfo(missionInfo)
		missionInfo.Score = (missionInfo.Score or 0) + missionScore;
		-- initialize or add new here;
		return missionInfo;
	end
	local exist =  false;
	for a=1, #factionUser.TopMissions do
		local missionInfo = factionUser.TopMissions[a];
		if missionInfo.Id == missionId then
			exist = true;
			updateMissionInfo(missionInfo);
			
			break;
		end
	end
	if not exist then
		table.insert(factionUser.TopMissions, updateMissionInfo({Id=missionId;}));
	end
	
	return factionUser;
end)

modMission.OnPlayerMission:Connect(function(player, mission, context)
	if context ~= "complete" and context ~= "failed" then return; end
	
	Debugger:Log("OnPlayerMission", player, mission, context);
	local missionLib = modMissionLibrary.Get(mission.Id);
	if missionLib == nil or missionLib.MissionType ~= modMissionLibrary.MissionTypes.Faction then return; end
	
	local profile = shared.modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local missionsProfile = activeSave and activeSave.Missions;
	
	missionsProfile:Destroy(mission);
	
	local factionProfile = profile.Faction;
	
	local actionPacket = {
		UserId = tostring(player.UserId);
		FactionTag = factionProfile.Tag;
	}

	local factionGroup = Factions.Get(actionPacket.FactionTag);
	if factionGroup == nil then Debugger:Log("Player not in a faction.",player,mission,context) return; end;

	local missionData = factionGroup.Missions;
	
	Debugger:Log("missionData.Active", missionData.Active);
	local activeIndex;
	for a=1, 3 do
		local activeMissionData = missionData.Active[a];
		if activeMissionData == nil then continue end;
		
		if activeMissionData.Id ~= mission.Id then continue end;
		
		local playerData = activeMissionData.Players[actionPacket.UserId];
		if playerData == nil then continue end;
		if playerData.MissionStatus >= 3 then continue end;
		
		activeIndex = a;
		break;
	end
	
	if activeIndex == nil then Debugger:Log("Could not find matching mission") return end;
	
	actionPacket.ActiveIndex = activeIndex;
	actionPacket.StatusUpdate = mission.Type;
	actionPacket.MissionData = HttpService:JSONDecode(HttpService:JSONEncode(mission.SaveData.FactionData));
	
	Factions.Action("submitmissionreport", actionPacket);
end)

function Factions.Action(actionId, actionPacket)
	local unixTime = modSyncTime.GetTime();
	local userId = actionPacket.UserId;
	local factionTag = actionPacket.FactionTag;
	
	local rPacket = {
		Success=nil;
		FactionObj=nil;
	};
	
	local player = game.Players:GetPlayerByUserId(userId);
	if player == nil then return rPacket; end;

	local factionGroup = Factions.Get(factionTag);
	if factionGroup == nil then
		return rPacket;
	end;

	--Debugger:Log("Faction action ",actionId, actionPacket);
	if actionId == "startfactionmission" then
		if not factionGroup:HasPermission(userId, "HandleMission") then 
			rPacket.NoPermissions = "HandleMission";
			shared.Notify(player, "Insufficient permissions (\"HandleMission\")", "Negative");
			return rPacket;
		end
		
		if factionGroup.MemberCount > 50 then
			shared.Notify(player, "Action rejected, oversized faction. Kick some members.", "Negative");
			return rPacket;
		end
		
		local missionData = factionGroup.Missions;
		
		local missionLib = modMissionLibrary.Get(actionPacket.MissionId);
		if missionLib == nil or missionLib.MissionType ~= modMissionLibrary.MissionTypes.Faction then
			shared.Notify(player, "Attempt to start invalid mission. (".. tostring(actionPacket.MissionId) ..")", "Negative");
			return rPacket;
		end

		local exist = false;
		for a=1, #missionData.Available do
			if missionData.Available[a].Id == actionPacket.MissionId then
				exist = true;
				break;
			end
		end
		if not exist then
			shared.Notify(player, "Available mission no longer exist. (".. tostring(actionPacket.MissionId) ..")", "Negative");
			return rPacket;
		end
		

		if missionLib.OneAtATime then
			local alreadyActive = false;
			for _, activeData in pairs(missionData.Active) do
				if activeData.Id == actionPacket.MissionId then
					alreadyActive = true;
					break;
				end
			end
			
			if alreadyActive then
				shared.Notify(player, "You can only have one (".. missionLib.Name ..") active at a time.", "Negative");
				return rPacket;
			end
		end
		
		
		actionPacket.MissionStartTime = unixTime;
		
		local returnPacket = factionsDatabase:UpdateRequest(factionTag, "startmission", actionPacket);
		Factions.UpdateMetaList(returnPacket.Data);
		
		if returnPacket.Success then
			Debugger:Log("[Action] startmission UpdateRequest success ", actionPacket);
			
			rPacket.Success = true;
			rPacket.FactionObj = returnPacket.Data:Clean(player);
			rPacket.FactionObj:Sync();
			
			
		elseif returnPacket.FailMsg then
			Debugger:Log("[Action] startmission UpdateRequest failmsg ", returnPacket.FailMsg);
			
		end
		
		
	elseif actionId == "claimfactionmission" then
		if not factionGroup:HasPermission(userId, "HandleMission") then 
			rPacket.NoPermissions = "HandleMission";
			shared.Notify(player, "Insufficient permissions (\"HandleMission\")", "Negative");
			return rPacket;
		end

		local activeIndex = actionPacket.ActiveIndex;
		local missionData = factionGroup.Missions;

		local activeMission = missionData.Active[activeIndex];
		local timeLeft = activeMission.CompletionTick-unixTime;
		if activeMission == nil or timeLeft > 0 then
			if activeMission == nil then
				shared.Notify(player, "Missing selected mission:"..activeIndex, "Negative");
			else
				shared.Notify(player, "Mission not yet complete: "..(timeLeft).."s", "Negative");
			end
			return rPacket;
		end

		local returnPacket = factionsDatabase:UpdateRequest(factionTag, "completemission", actionPacket);
		Factions.UpdateMetaList(returnPacket.Data);
		
		if returnPacket.Success then
			Debugger:Log("completemission success ", actionPacket);

			rPacket.Success = true;
			rPacket.FactionObj = returnPacket.Data:Clean(player);
			rPacket.FactionObj:Sync();

		elseif returnPacket.FailMsg then
			Debugger:Log("completemission failmsg ", returnPacket);

		end
		
		
	elseif actionId == "submitmissionreport" then
		local activeIndex = actionPacket.ActiveIndex;
		local missionData = factionGroup.Missions;

		local activeMission = missionData.Active[activeIndex];
		if activeMission == nil or activeMission.CompletionTick-unixTime <= 10 then
			return rPacket;
		end

		local returnPacket = factionsDatabase:UpdateRequest(factionTag, "updatemission", actionPacket);
		
		if returnPacket.Success then
			Debugger:Log("submitmissionreport success ", returnPacket.Data.Missions.Active, actionPacket);

			rPacket.Success = true;
			rPacket.FactionObj = returnPacket.Data:Clean(player);
			rPacket.FactionObj:Sync();
			
		elseif returnPacket.FailMsg then
			Debugger:Log("submitmissionreport failmsg ", returnPacket.FailMsg);

		end
		
	elseif actionId == "joinfactionmission" then
		local activeIndex = actionPacket.ActiveIndex;
		local missionData = factionGroup.Missions;

		local activeMission = missionData.Active[activeIndex];
		if activeMission == nil or activeMission.CompletionTick-unixTime <= 10 then
			shared.Notify(player, "Mission is about to end.", "Negative");
			return rPacket;
		end

		Debugger:Log("[Action] Joining active mission:", activeMission);

		local quotaLimit = math.clamp(tonumber(activeMission.QuotaLimit) or 99, 1, 99);

		if #activeMission.Players >= quotaLimit then
			shared.Notify(player, "Mission quota is full.", "Negative");
			Debugger:Log("[Action] Mission quota is full.", activeMission.Players);
			return rPacket;
		end


		local accessType = activeMission.AccessType;
		local accessValue = activeMission.AccessValue;

		if accessType == "Roles" then
			local userRole = factionGroup:GetRole(userId);
			if userRole ~= "Owner" and table.find(accessValue, userRole) == nil then
				Debugger:Log("[Action] AccessType=Roles unauth", accessValue, " userRole", userRole);
				shared.Notify(player, "Your rank is not authorized to join this mission.", "Negative");
				return rPacket;
			end

		elseif accessType == "Members" then
			if table.find(accessValue, player.Name) == nil then
				Debugger:Log("[Action] AccessType=Members unauth", accessValue, " player.Name", player.Name);
				shared.Notify(player, "You are not authorized to join this mission.", "Negative");
				return rPacket;
			end
		end

		if activeMission.Players[userId] then
			shared.Notify(player, "You are already in this mission.", "Negative");
			Debugger:Log("[Action] Already in faction mission", player.UserId, activeMission.Players);
			return rPacket;
		end
		
		local mission = modMission:GetMission(player, activeMission.Id);
		if mission then
			Debugger:Warn("Player (",player,") Already doing this faction mission (",mission,")");
			local missionProfile = modMission.GetMissions(player.Name);
			if missionProfile then
				missionProfile:Destroy(mission);
			end
		end
		
		actionPacket.MissionJoinTime = unixTime;
		
		local returnPacket = factionsDatabase:UpdateRequest(factionTag, "joinmission", actionPacket);
		if returnPacket.Success then

			rPacket.Success = true;
			rPacket.FactionObj = returnPacket.Data:Clean(player);
			rPacket.FactionObj:Sync();
			
			modMission:StartMission(player, activeMission.Id);
			
		elseif returnPacket.FailMsg then
			Debugger:Log("[Action] joinmission failmsg ", returnPacket.FailMsg);
			shared.Notify(player, returnPacket.FailMsg, "Negative");
			
		end

	end

	-- goal, return packet with success if succeeded
	return rPacket;
end

script:SetAttribute("Debug", false);
function Factions.InvokeHandler(player, action, ...)
	if player.UserId == 16170943 then
		script:SetAttribute("Debug", true);
	end
	
	Debugger:Log(player,":InvokeHandler (", action, ")",...);
	local rPacket = {};
	if action ~= "create" and remoteFactionService:Debounce(player) then rPacket.Debounce=true; return rPacket; end;

	local eventObj = modEvents:GetEvent(player, "mission58choice");
	if eventObj == nil then
		local mission = modMission:GetMission(player, 58);
		if mission == nil or mission.Type ~= 3 then
			Debugger:Log("Factions not unlocked yet.");
			rPacket.Mission58 = true;
			return rPacket;
		end
	end

	local unixTime = DateTime.now().UnixTimestamp;

	local profile = shared.modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local userId = tostring(player.UserId);

	local missionsProfile = modMission.GetMissions(player.Name);
	local factionProfile = profile.Faction;

	local factionUser = Factions.GetUser(userId);
	local factionTag;
	
	if factionUser then
		for k, v in pairs(factionUser) do
			factionProfile[k] = v;
		end
	end
	
	--Debugger:Log("InvokeHandler:factionUser", factionUser);
	--Debugger:Log(player,"Action (", action, ")");
	
	if factionUser == nil or not factionUser.IsInFaction then

		if action == "search" then
			local inputTag = ...;
			inputTag = string.lower(tostring(inputTag));

			local list = Factions.SearchMetaList(inputTag);

			if list[inputTag] == nil then
				if profile.Cache.FactionSearchCooldown == nil or tick()-profile.Cache.FactionSearchCooldown >= 10 then
					profile.Cache.FactionSearchCooldown = tick();

					local factionGroup = Factions.Get(inputTag);
					if factionGroup == nil then
						Debugger:Log("factionGroup ", inputTag, " does not exist.");
						
					else
						list[inputTag] = {
							Tag=factionGroup.Tag;
							Title=factionGroup.Title;
							Icon=factionGroup.Icon;
						};
						
					end
				end
			end

			for tag, v in pairs(list) do
				local filtered = shared.modAntiCheatService:Filter(v.Title, player);
				v.Title = tostring(filtered);

				local filtered = shared.modAntiCheatService:Filter(v.Tag, player);
				v.Tag = tostring(filtered);
			end

			return list;

		elseif action == "sendjoinrequest" then
			local targetFactionTag = ...;
			
			local senderName = player.Name;
			local returnPacket = factionsDatabase:UpdateRequest(targetFactionTag, "sendjoinrequest", {UserId=userId; PlayerName=senderName;});
			if returnPacket.Success then
				local factionGroup = returnPacket.Data;

				if factionGroup.Owner == userId then -- Rejoin;
					shared.Notify(player, "Rejoining your own faction ("..targetFactionTag..")..", "Inform");
					
					local setUserReturnPacket = factionsDatabase:UpdateRequest(userId, "user_setfaction", {
						NewFactionTag=targetFactionTag;
						PlayerName=senderName;
						Role=factionGroup:GetRole(userId);
					});
					if setUserReturnPacket.Success then
						factionProfile.Tag = targetFactionTag;
						rPacket.FactionObj = factionGroup:Clean(player);
						rPacket.Success = true;
						
					end
					
				else --
					for memberUserId, memberData in pairs(factionGroup.Members) do
						if factionGroup:HasPermission(memberUserId, "HandleJoinRequests") then
							Factions.SyncUser(memberUserId, {ReceiveJoinRequest=true;});
						end
					end
					
					shared.Notify(player, "Sent join request to faction (".. targetFactionTag ..")", "Inform");
					task.delay(1, function()
						factionGroup:Sync();
					end)
				end
				
			else
				Debugger:Warn("Failed to sendjoinrequest", returnPacket.FailMsg);
				rPacket.FailMsg = returnPacket.FailMsg;
			end

			return rPacket;

		elseif action == "sync" then
			return rPacket;

		elseif action == "leavefaction" then
			factionsDatabase:UpdateRequest(userId, "user_reset");

			return rPacket;

		elseif action == "create" then
			local inputTag, testCreate = ...;

			Debugger:Log("create inputTag, testCreate", ...);

			inputTag = string.lower(tostring(inputTag));

			if #inputTag <= TAGSIZEMIN then rPacket.TooShort = true; return rPacket; end;
			if #inputTag > TAGSIZEMAX then rPacket.TooLong = true; return rPacket; end;

			local filtered = shared.modAntiCheatService:Filter(inputTag, player);
			if filtered ~= inputTag then rPacket.Tag=filtered; rPacket.Filtered = true; return rPacket; end;
			if inputTag:match("#") then rPacket.Tag=filtered; rPacket.Filtered = true; return rPacket; end;

			if inputTag == nil or #inputTag <= 3 then rPacket.Filtered = true; return rPacket; end;
			if tonumber(inputTag) ~= nil then rPacket.Filtered = true; return rPacket end;

			local tagTaken = false;
			if testCreate and globalFactionMeta then -- testCreate
				for k, _ in pairs(globalFactionMeta.List) do
					if string.lower(k) == inputTag then
						tagTaken = true;
						break;
					end
				end
				if globalFactionMeta.List[inputTag] then
					tagTaken = true;
				end

			else -- Actual create checks
				local existingFaction = Factions.Get(inputTag);
				if existingFaction then
					tagTaken = true;
				end
			end
			
			if takenFactionTags[inputTag:lower()] and not shared.IsAuthorized(player) then
				tagTaken = true;
			end
			if tagTaken then rPacket.Taken = true; return rPacket; end;
			if inputTag == "metalist" then rPacket.Taken = true; return rPacket; end;

			local traderProfile = profile and profile.Trader;
			if traderProfile == nil then rPacket.Success=nil; return rPacket; end;

			local playerGold = traderProfile.Gold;
			local factionCreateCost = 5000;

			if playerGold < factionCreateCost then 
				rPacket.Success=nil;
				rPacket.InsufficientGold = true;
				shared.Notify(player, "Insufficient Gold.", "Negative");
				return rPacket;
			end;
			remoteFactionService:Debounce(player, true);

			rPacket.Success = true;
			rPacket.Tag = inputTag;

			if testCreate then
				return rPacket;
			end
			if profile.CreatingFaction and tick()-profile.CreatingFaction <= 60 then
				shared.Notify(player, "Already creating faction, try again later..", "Negative");
				return rPacket;
			end;

			profile.CreatingFaction = tick();

			factionTag = inputTag;
			factionProfile.Tag = factionTag;

			local userSetFactionRPacket = factionsDatabase:UpdateRequest(userId, "user_setfaction", {
				NewFactionTag=factionTag;
				PlayerName=player.Name;
				Role="Owner";
			});
			if userSetFactionRPacket.Success ~= true then
				shared.Notify(player, "Failed to create faction, try again later..", "Negative");
				return rPacket;
			end
			
			local newUserObj = userSetFactionRPacket.Data;
			Debugger:Log("New userSetFactionRPacket.Data", newUserObj);
			
			local newFactionObj;
			factionsDatabase:Publish(factionTag, function(rawData)
				if rawData ~= nil then return end;

				local newFaction = FactionGroup.new();
				newFaction.Tag = factionTag;
				newFaction.Title = player.Name.."'s Faction";

				newFaction:SetLeader(userId);
				newFaction:AddMember(newUserObj);

				newFactionObj = newFaction 
				return factionSerializer:Serialize(newFaction);
			end)

			Debugger:Log("newFactionObj ", newFactionObj);
			
			if newFactionObj then
				-- create faction set meta;
				Factions.UpdateMetaList(newFactionObj);
				
				if newFactionObj.Owner == userId then
					traderProfile:AddGold(-factionCreateCost);
					shared.Notify(player, "You have successfully created a faction.", "Reward");
					modAnalytics.RecordResource(player.UserId, factionCreateCost, "Sink", "Gold", "Purchase", "Faction");
					activeSave:AwardAchievement("faction");

					local factionsMadeFlag = profile.Flags:Get("FactionsCreated", {Id="FactionsCreated", Value=0});
					factionsMadeFlag.Value = factionsMadeFlag.Value +1;

					local factionsMadeFlags = profile.Flags:Get("Factions", {Id="Factions"; List={}});
					table.insert(factionsMadeFlags.List, newFactionObj.Tag);

				else
					shared.Notify(player, "Failed to create faction, looks like someone made it first.", "Negative");

				end

				rPacket.FactionObj = newFactionObj:Clean(player);
			end

			profile.CreatingFaction = 0;
			return rPacket;

		end
	end
	
	
	--=== Requires factionUser is in faction;
	if not factionUser.IsInFaction then return rPacket end;
	factionTag = factionUser.Tag;

	if action == "sync" then
		local factionGroup = Factions.Get(factionTag);
		

		if profile.FactionBan == 1 and factionGroup then
			factionGroup = nil;
			factionsDatabase:UpdateRequest(factionTag, "leavefaction", userId);
			shared.Notify(player, "You are faction banned, you can not access faction features.", "Negative");
		end
		
		if factionGroup then
			factionProfile.FactionTitle = factionGroup.Title;
			factionProfile.FactionIcon = factionGroup.Icon;
			
			if (profile.FactionRefresh == nil or unixTime-profile.FactionRefresh >= 290) and unixTime-factionGroup.LastUpdate >= 300 then
				profile.FactionRefresh = unixTime;
				
				Debugger:Log("Full faction refresh, check defected members.");
				task.spawn(function()
					local allUserObjs = {};
					local memToDel = {};
					
					local ownerName;
					local hqHostName;
					
					for memberId, memberData in pairs(factionGroup.Members) do
						if unixTime-(memberData.LastActive or 0) >= (shared.Const.OneDaySecs*2) then
							local factionUser = Factions.GetUser(memberId); -- Fetch most updated userObject;

							if factionUser == nil or factionUser.Tag ~= factionGroup.Tag then
								memToDel[memberId] = true;

								if memberData.Name == factionGroup.HqHost then
									factionGroup.HqHost = "";
								end

							elseif factionUser and factionUser.Tag == factionGroup.Tag then
								allUserObjs[memberId] = factionUser;
								
							end;
						end
						
						if tostring(memberId) == factionGroup.Owner then
							ownerName = memberData.Name;
						end
					end
					
					local additionalRefreshPacket = {};
					if factionGroup.Owner == tostring(userId) then
						local safehomeData = profile.Safehome;
						
						additionalRefreshPacket.SafehomeId = safehomeData.ActiveId;
					end
					
					if factionGroup.HqHost == "" then
						hqHostName = ownerName;
					end
					
					local returnPacket = factionsDatabase:UpdateRequest(factionTag, "refresh", {
						InvokerUserId=userId;
						DelMembers=memToDel;
						UpdateUsers=allUserObjs;
						RefreshPacket=additionalRefreshPacket;
						HqHost=hqHostName;
					});
					if returnPacket.Success then
						local factionObj = returnPacket.Data;

						if factionObj.Members[userId] == nil then
							if factionsDatabase:UpdateRequest(userId, "user_reset").Success then
								factionProfile.Tag = nil;
								Factions.SyncUser(userId, {Kicked=true;});
							end
							Debugger:Log("Sync User (",userId,") no longer in faction.", factionObj.Tag);
							
						else
							factionsDatabase:UpdateRequest(userId, "user_setfaction", {
								NewFactionTag=factionTag;
								PlayerName=player.Name;
								Role=factionObj:GetRole(userId);
							});
							
						end
						
					end
				end);
				
			end
			
			refreshFaction(factionGroup);
			
			rPacket.FactionObj=factionGroup:Clean(player);
			return rPacket;
			
		else
			Debugger:Log("Sync factionGroup does not exist:", factionTag);

			if factionsDatabase:UpdateRequest(userId, "user_reset").Success then
				factionProfile.Tag = nil;
			end

			return rPacket;
		end
		
	elseif action == "select" then
		local packet = ...;
		local mIndex = packet.Index;

		local factionGroup = Factions.Get(factionTag);
		
		if factionGroup == nil then Debugger:Log("[select] Faction group doesn't exist:", factionTag) return end;
		
		local missionData = factionGroup.Missions.Active[mIndex];
		if missionData == nil then Debugger:Log("[select] Selected unavailable mission:", mIndex) return end;
		

		local missionTimeLeft = missionData.CompletionTick-unixTime;
		if missionTimeLeft <= 0 then Debugger:Log("[select] Selected ended mission:", mIndex) return end;
		
		local playerMissionData = missionData.Players[userId];
		if playerMissionData == nil then Debugger:Log("[select] Player is not in this mission:", userId, mIndex) return end;
		
		if playerMissionData.MissionStatus == 3 then Debugger:Log("[select] Player completed this mission:", userId, mIndex) return end;
		if playerMissionData.MissionStatus == 4 then Debugger:Log("[select] Player failed this mission:", userId, mIndex) return end;
		
		local mission = modMission:GetMission(player, missionData.Id);
		if mission == nil then
			modMission:StartMission(player, missionData.Id);
		end
		
	elseif action == "startfactionmission" then
		local packet = ...;
		
		packet.UserId = userId;
		packet.FactionTag=factionTag;
		
		return Factions.Action(action, packet);

	elseif action == "claimfactionmission" then
		local packet = ...;

		packet.UserId = userId;
		packet.FactionTag=factionTag;

		return Factions.Action(action, packet);

	elseif action == "joinfactionmission" then
		local packet = ...;

		packet.UserId = userId;
		packet.FactionTag=factionTag;

		return Factions.Action(action, packet);


	elseif action == "leavefaction" then
		
		local returnPacket = factionsDatabase:UpdateRequest(factionTag, "leavefaction", userId);
		if returnPacket.Success then
			rPacket.Success = true;
			
			if factionsDatabase:UpdateRequest(userId, "user_reset").Success then
				factionProfile.Tag = nil;
			end

			rPacket.FactionObj = returnPacket.Data:Clean(player);
			rPacket.FactionObj:Sync(true);
		end
		
		return rPacket;

	elseif action == "kickuser" then
		local kickUserId = ...;

		if kickUserId == userId then
			Debugger:Log("Cannot kick yourself.");
			return rPacket;
		end

		local returnPacket = factionsDatabase:UpdateRequest(factionTag, "kickuser", {KickUserId=kickUserId; UserId=userId});
		if returnPacket.Success then
			local kickReturnPacket = factionsDatabase:UpdateRequest(kickUserId, "user_reset");
			if kickReturnPacket.Success then
				Factions.SyncUser(kickUserId, {Kicked=true;});
			end
			
			rPacket.FactionObj = returnPacket.Data:Clean(player);
			rPacket.FactionObj:Sync();
		end
		
		return rPacket;

	elseif action == "setrole" then
		local targetUserId, setRoleKey = ...;

		local returnPacket = factionsDatabase:UpdateRequest(factionTag, "setrole", {TargetUserId=targetUserId; SetRoleKey=setRoleKey; UserId=userId});
		if returnPacket.Success then
			rPacket.Success = true;

			task.spawn(function()
				factionsDatabase:UpdateRequest(targetUserId, "user_setrole", {NewRole=setRoleKey});
			end)
			
			Factions.SyncUser(targetUserId);
			rPacket.FactionObj = returnPacket.Data:Clean(player);
			rPacket.FactionObj:Sync();
		end
		
		return rPacket;

	elseif action == "configrole" then
		local roleKey, configs = ...;

		configs.Title = tostring(configs.Title):sub(1,40);
		pcall(function() configs.Color = Color3.fromHex(configs.Color):ToHex(); end)
		configs.Color = configs.Color or "#ffffff";
		configs.Rank = math.clamp(tonumber(configs.Rank) or 98, 1, 98);
		configs.Perm = tonumber(configs.Perm) or 0;

		Debugger:Log("submitted configs", configs);

		local returnPacket = factionsDatabase:UpdateRequest(factionTag, "configrole", {RoleKey=roleKey; Configs=configs; UserId=userId});
		if returnPacket.Success then
			rPacket.Success = true;
			rPacket.FactionObj = returnPacket.Data:Clean(player);
			rPacket.FactionObj:Sync();
		end
		
		return rPacket;

	elseif action == "deleterole" then
		local roleKey = ...;

		if roleKey ~= "__new" and roleKey ~= "Owner" and roleKey ~= "Member" then
			
			local returnPacket = factionsDatabase:UpdateRequest(factionTag, "deleterole", {RoleKey=roleKey; UserId=userId});
			if returnPacket.Success then
				rPacket.Success = true;
				rPacket.FactionObj = returnPacket.Data:Clean(player);
				rPacket.FactionObj:Sync();

				Debugger:Log("Del role:", returnPacket.Data);
			end
		end

		return rPacket;

	elseif action == "settings" then
		local settingsPacket = ...;
		if settingsPacket == nil then return end;

		local inputInput = settingsPacket.TitleInput;
		local descInput = settingsPacket.DescInput;
		local iconInput = settingsPacket.IconInput;
		
		if settingsPacket.ColorInput then
			settingsPacket.ColorInput = Color3.fromHex(settingsPacket.ColorInput):ToHex();
		end

		if factionTag == nil then
			rPacket.NotInFaction = true;
			return rPacket;
		end

		if #iconInput > 0 then
			local productInfo = shared.modAntiCheatService:SafeProductInfo(iconInput, Enum.InfoType.Asset, player);

			if productInfo then
				local assetId = productInfo.AssetId;
				
				if productInfo.AssetTypeId == 1 then
					if productInfo.Verifying then
						shared.Notify(player, "Decal id is being verified.. ("..modSyncTime.ToString(productInfo.TimeLeft)..")", "Inform");
						Debugger:WarnClient(player, "Decal id is being verified.. ("..modSyncTime.ToString(productInfo.TimeLeft)..")");
						settingsPacket.IconInput = nil;

					else
						settingsPacket.IconInput = assetId;
						Debugger:Log("Faction icon set successful. ", settingsPacket.IconInput);

					end

				else
					shared.Notify(player, "Invalid decal id.", "Inform");
					Debugger:WarnClient(player, "Invalid decal id.");
					settingsPacket.IconInput = nil;
				end
			end
		end

		local returnPacket = factionsDatabase:UpdateRequest(factionTag, "settings", {SettingsPacket=settingsPacket; UserId=userId});
		if returnPacket.Success then
			local factionGroup = returnPacket.Data;
			
			Factions.UpdateMetaList(factionGroup);
			
			task.spawn(function()
				if shared.modSafehomeService and modBranchConfigs.IsWorld("Safehome") then
					shared.modSafehomeService.LoadHeadquarters();
				end
			end)

			rPacket.FactionObj = factionGroup:Clean(player);
			rPacket.FactionObj:Sync(true);
			
		end
		
		return rPacket;
		
		
	elseif action == "handlejoinrequest" then
		local requestUserId, acceptRequest = ...;

		local factionGroup = Factions.Get(factionTag);

		if not factionGroup:HasPermission(userId, "HandleJoinRequests") then
			rPacket.NoPermissions = true;
			shared.Notify(player, "Insufficient permissions.", "Negative");
			return rPacket;
		end
		
		local joinRequest = factionGroup.JoinRequests[requestUserId];
		
		if joinRequest == nil then
			Debugger:Log("Missing join request");
			shared.Notify(player, acceptRequest and "Accept request already processed." or "Decline request already processed.", "Inform");
			return rPacket;
		end
		
		local requesterName = joinRequest.Name;
		
		local factionUser = Factions.GetUser(tostring(requestUserId));
		
		if factionUser == nil then
			factionUser = FactionUser.new(tostring(requestUserId));
			factionUser.Name = requesterName;
		end

		Debugger:Log("Handlejoinrequest ", requestUserId, " factionUser", factionUser, " acceptRequest", acceptRequest);

		local returnPacket = factionsDatabase:UpdateRequest(factionTag, "handlejoinrequest", {
			AcceptRequest=acceptRequest;
			UserId=userId;
			FactionUser=factionUser;
		});
		
		if returnPacket.Success then
			if acceptRequest then
				local setUserReturnPacket = factionsDatabase:UpdateRequest(requestUserId, "user_setfaction", {
					NewFactionTag=returnPacket.Data.Tag; 
					PlayerName=requesterName;
					Role=returnPacket.Data:GetRole(requestUserId);
				});
				if setUserReturnPacket.Success then
					Factions.SyncUser(requestUserId, {JoinAccepted=true;});
				end
			end
			
			rPacket.FactionObj = returnPacket.Data:Clean(player);
			rPacket.FactionObj:Sync();
		end
		
		return rPacket;

	elseif action == "create" then
		rPacket.AlreadyInFaction = true;
		return rPacket;

	elseif action == "travelhq" then
		Debugger:Warn(player,"request to travel to", factionTag, " hq");

		local factionGroup = Factions.Get(factionTag);

		local hqAccessCode = factionGroup.HqAccessCode;
		
		if hqAccessCode and modServerManager.AccessCode == hqAccessCode then
			
			shared.Notify(player, "You are already in the headquarters.", "Negative");
			return rPacket;
			
		else

			shared.Notify(player, "Creating headquarters server..", "Inform");
			local reserveAccessCode, privateServerId = modServerManager:CreatePrivateServer("Safehome");

			shared.Notify(player, "Setting headquarters server..", "Inform");
			local setAccessCodeReturnPacket = factionsDatabase:UpdateRequest(factionTag, "sethqaccesscode", reserveAccessCode);
			if setAccessCodeReturnPacket.Success then
				local factionGroup = setAccessCodeReturnPacket.Data;
				hqAccessCode = factionGroup.HqAccessCode;
				
				factionGroup:Sync();
				
			else
				shared.Notify(player, "Setting headquarters failed: "..(setAccessCodeReturnPacket.FailMsg or "1") , "Negative");
				
			end

			shared.Notify(player, "Headquarters server load complete..", "Inform");
		end
		
		local teleportData = modServerManager:CreateTeleportData();
		teleportData.FactionHeadquarter = {
			FactionTag=factionTag;
			FactionOwnerId=factionGroup.Owner;
			SafehomeId=factionGroup.SafehomeId;
		}
		
		Debugger:Warn("hqAccessCode", hqAccessCode);
		modServerManager:TeleportToPrivateServer("Safehome", hqAccessCode, {player}, teleportData);
		
		return rPacket;

	elseif action == "sethqhost" then
		local inputName = ...;

		local factionGroup = Factions.Get(factionTag);

		if not factionGroup:HasPermission(userId, "CustomizeHq") then 
			rPacket.NoPermissions = "CustomizeHq";
			shared.Notify(player, "Insufficient permissions (\"CustomizeHq\")", "Negative");
			return rPacket;
		end
		
		local oldHostName = factionGroup.HqHost;
		local hostName = "";
		
		local membersList = {};
		for userId, memberData in pairs(factionGroup.Members) do
			table.insert(membersList, memberData.Name);
			
			if tostring(userId) == factionGroup.Owner then
				hostName = memberData.Name;
			end
		end
		
		if table.find(membersList, inputName) then
			hostName = inputName;
		end
		
		local hostUserId = tostring(player.UserId);
		
		local s, e = pcall(function()
			hostUserId = game.Players:GetUserIdFromNameAsync(hostName);
		end)
		if not s then
			Debugger:Warn(e);
		end

		local hostSaveData = shared.modProfile.LoadRaw(hostUserId);
		Debugger:Log("hostSaveData.Safehome", hostSaveData and hostSaveData.Safehome or nil);
		local activeSafehomeId = hostSaveData and hostSaveData.Safehome and hostSaveData.Safehome.ActiveId or "default";

		local setReturnPacket = factionsDatabase:UpdateRequest(factionTag, "sethqhost", {
			UserId=userId;
			HostName=inputName;
			SafehomeId=activeSafehomeId
		});
		
		if setReturnPacket.HqHost == inputName then
			factionGroup = setReturnPacket.Data;
			
			if modBranchConfigs.IsWorld("Safehome") and shared.modSafehomeService and shared.modSafehomeService.FactionTag == factionTag then
				Debugger:Warn("LoadHeadquarters after sethqhost ", setReturnPacket.HqHost);
				shared.modSafehomeService.LoadHeadquarters(factionGroup);
			end
		end
		
		rPacket.SelectName = setReturnPacket.HqHost;
		return rPacket;

	elseif action == "customizeHq" then
		local packet = ...;

		local factionGroup = Factions.Get(factionTag);

		if not factionGroup:HasPermission(userId, "CustomizeHq") then 
			rPacket.NoPermissions = "CustomizeHq";
			shared.Notify(player, "Insufficient permissions (\"CustomizeHq\")", "Negative");
			return rPacket;
		end

		local groupId = packet.GroupId;
		local groupData = {};


		if packet.NewColor and typeof(packet.NewColor) == "Color3" then
			groupData.Color = packet.NewColor:ToHex();
		end
		
		local cacheObj = {};
		
		local returnColor = Color3.fromHex(groupData.Color);
		if modBranchConfigs.IsWorld("Safehome") and workspace:GetAttribute("FactionHeadquarters") == factionTag then
			local safehomeCustomizableFolder = workspace.Environment:FindFirstChild("Customizable");
			local groupFolder = safehomeCustomizableFolder and safehomeCustomizableFolder:FindFirstChild(groupId);

			if groupFolder then
				for _, obj in pairs(groupFolder:GetChildren()) do
					if obj:IsA("BasePart") then
						cacheObj[obj] = {
							Color = obj.Color;
						}
						obj.Color = returnColor;
					end
				end
			end
		end

		local setReturnPacket = factionsDatabase:UpdateRequest(factionTag, "customizeHq", {
			UserId=userId;
			GroupId=groupId;
			GroupData=groupData;
		});
		
		if setReturnPacket == nil or setReturnPacket.Success ~= true then
			for obj, defaultData in pairs(cacheObj) do
				if defaultData.Color then
					obj.Color = defaultData.Color;
				end
			end
		end

		return rPacket;
		
	else
		rPacket.UnhandleAction = action;
		return rPacket;

	end
end

--================
function Factions.GetGlobalMetaList()
	if globalFactionMeta == nil then
		Factions.RefreshMetaList();
	end
	
	return globalFactionMeta;
end

modLeaderboardService.LookUpFuncs.Factions = function(leaderboardDataTable)	
	if globalFactionMeta == nil then
		Factions.RefreshMetaList();
	end

	for a=1, #leaderboardDataTable do
		local data = leaderboardDataTable[a];
		local factionTag = data.Key;
		local rank = data.Rank;
		local value = data.Value;
		
		local factionMetaInfo = {Title="Loading.."; Icon="9890634236"; Color="ffffff"};
		if globalFactionMeta then
			factionMetaInfo = globalFactionMeta.List[factionTag];
		end

		if factionMetaInfo then
			data.Title = shared.modAntiCheatService:FilterNonChatStringForBroadcast(factionMetaInfo.Title);

			data.Icon = factionMetaInfo.Icon;
			data.Color = "ffffff";

			if factionMetaInfo.Icon == "9890634236" then
				data.Color = factionMetaInfo.Color;
			end
			
		else
			data.Title = factionTag;
			data.Icon = "9890634236";
			data.Color = "ffffff";
			
		end
	end
end

remoteFactionService.OnServerInvoke = Factions.InvokeHandler;

game.Players.PlayerRemoving:Connect(function(player)
	task.wait(1);
	factionsDatabase:Publish(tostring(player.UserId));
end)

task.spawn(function()
	repeat task.wait() until shared.modProfile ~= nil;
	Debugger:Log("Factions connected OnPlayerPacketRecieved.")
	
	shared.modProfile.OnPlayerPacketRecieved:Connect(function(profile, ...)
		local packet = ...;
		
		Debugger:Log(profile.Player," Received packet", packet);
		
		if packet and packet.Data then
			if packet.Data.Request == "SyncFactionUser" then
				local packetData = packet.Data;
				local player = profile.Player;
				local userId = tostring(player.UserId);

				local factionUser = Factions.GetUser(userId);

				if factionUser and factionUser.IsInFaction then
					local newFactionObj = Factions.Get(factionUser.Tag);
					newFactionObj:Sync();

					if packetData.JoinAccepted then
						shared.Notify(player, "You have been accepted by "..(newFactionObj.Title or "faction")..".", "Inform");

					elseif packetData.ReceiveJoinRequest then
						shared.Notify(player, "You have received a faction join request.", "Inform");
					end
				end

				if packetData.Kicked then
					shared.Notify(player, "You have been kicked from the faction.", "Inform");
					remoteFactionService:InvokeClient(player, "sync", {});
				end
				
			elseif packet.Data.Request == "SyncFaction" and profile.Faction.Tag then
				local factionTag = profile.Faction.Tag;

				local newFactionObj = Factions.Get(factionTag);
				newFactionObj:Sync(true);
				
			end
		end
	end)
end)


task.spawn(function()
	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("faction", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
		Description = [[Factions commands.
		/faction clearmission [index] [expireTime]
		/faction addmission missionId
		/faction print
		/faction submitlb
		/faction metalist
		/faction addgold amount
		/faction addresource index amount
		]];

		RequiredArgs = 0;
		UsageInfo = "/faction action";
		Function = function(player, args)
			local profile = shared.modProfile:Get(player);
			local factionProfile = profile.Faction;
			local factionTag = factionProfile.Tag;
			local userId = tostring(player.UserId);

			local action = args[1];

			if factionTag == nil then
				Debugger:Log("Not in a faction");
				shared.Notify(player, "Not in a faction.", "Inform");
				return true
			end
			
			if action == "clearmission" then
				local activeIndex = args[2];
				local expireTime = args[3];

				local returnPacket = factionsDatabase:UpdateRequest(factionTag, "clearmission", {ActiveIndex=activeIndex; ExpireTime=expireTime;});
				if returnPacket.Success then
					Debugger:Log("Clear active mission ", activeIndex);
					shared.Notify(player, "Active mission "..activeIndex.." cleared.", "Inform");
					
					returnPacket.Data:Sync();
					
				else
					shared.Notify(player, "Failed to clear active mission index: "..activeIndex..". FailMsg: ".. returnPacket.FailMsg , "Inform");
					Debugger:Log("Failed to clear active mission ", returnPacket.Data.Missions.Active);
					
				end
				
			elseif action == "print" then
				local key = args[2] or factionTag;
				local factionObj = Factions.Get(key);
				
				Debugger:Log("/print ", factionObj);
				shared.Notify(player, "Printed "..key.." into console.", "Inform");

			elseif action == "addscore" then
				local score = tonumber(args[2]);
				
				local returnPacket = factionsDatabase:UpdateRequest(factionTag, "addscore", score);
				if returnPacket.Success then
					Debugger:Log("Add score successful.");
				end
				
			elseif action == "submitlb" then
				local factionObj = Factions.Get(factionTag);
				local score = factionObj[modLeaderboardService.FactionBoardKey] or 0;
				
				Factions.SubmitLeaderboard(factionObj);
				
				shared.Notify(player, "Submitting (".. factionTag 
					..") to leaderboard (".. modLeaderboardService.FactionBoardKey 
					..") Score: ".. score, "Inform");
				
			elseif action == "addmission" then
				local mId = tonumber(args[2]);

				local returnPacket = factionsDatabase:UpdateRequest(factionTag, "addmission", {MissionId=mId;});
				if returnPacket.Success then
					Debugger:Log("Add mission successful.");
					returnPacket.Data:Sync();
					shared.Notify(player, "Faction mission added.", "Inform");
					
				else
					shared.Notify(player, "Mission failed to add to faction: "..(returnPacket.FailMsg or "n/a") , "Negative");
					
				end
				
				
			elseif action == "view" then
				local viewTag = table.concat(args, " ", 2, #args);
				if viewTag == nil or #viewTag <= 3 then
					factionProfile.ViewTag = nil;
					Debugger:Log("Clear view tag");
					shared.Notify(player, "Clear view faction"..viewTag, "Inform");
				else
					factionProfile.ViewTag = viewTag;
					Debugger:Log("Set view tag:"..viewTag);
					shared.Notify(player, "View faction tag:"..viewTag, "Inform");
				end

			elseif action == "bypass" then
				if modGlobalVars.FactionBypass == nil then modGlobalVars.FactionBypass = false end;
				modGlobalVars.FactionBypass = not modGlobalVars.FactionBypass
				player:SetAttribute("FactionBypass", modGlobalVars.FactionBypass);
				shared.Notify(player, "Faction bypass = "..tostring(modGlobalVars.FactionBypass), "Inform");

			elseif action == "testperm" then
				local value = args[2];
				local flag = args[3];
				local factionObj = Factions.Get(factionTag);

				shared.Notify(player, "testperm:"..value..":"..flag..": "..Debugger:Stringify(factionObj:HasPermission(value, flag)), "Inform");

			elseif action == "toggletest" then

				local testKey = args[2];
				local testValue = args[3] == true;
				
				local returnPacket = factionsDatabase:UpdateRequest(factionTag, "settesttoggle", {TestKey=testKey; TestValue=testValue;});
				if returnPacket.Success then
					shared.Notify(player, "Toggled "..testKey..": "..tostring(returnPacket.ReturnValue) , "Inform");
					returnPacket.Data:Sync(true);
					
				else
					shared.Notify(player, "Toggle failed: "..testKey, "Negative");
				end
				
				
			elseif action == "metalist" then
				local tagsList = {};
				
				Factions.RefreshMetaList();
				for k, v in pairs(globalFactionMeta.List) do
					table.insert(tagsList, k);
				end
				
				Debugger:Log("Metalist",tagsList);
				shared.Notify(player, "metalist(".. #tagsList .."): "..table.concat(tagsList, ", "), "Inform");

			elseif action == "addgold" then

				local v = args[2] or 100;

				local returnPacket = factionsDatabase:UpdateRequest(factionTag, "addgold", {Amount=v; Reason="/faction addgold by "..player.Name});
				if returnPacket.Success then
					shared.Notify(player, "Added gold: ".. returnPacket.Data.Gold, "Inform");
					returnPacket.Data:Sync(true);

				else
					shared.Notify(player, "Add gold failed: "..returnPacket.FailMsg, "Negative");
				end
				
			elseif action == "addresource" then
				
				local rTypes = {"Food"; "Ammo"; "Material"; "Power"; "Comfort"}
				
				local rId = rTypes[args[2]];
				local rVal = args[3];

				local returnPacket = factionsDatabase:UpdateRequest(factionTag, "addresource", {
					Id=rId;
					Value=rVal;
				});

				if returnPacket.Success then
					shared.Notify(player, "Resource add:"..rId.."="..rVal, "Inform");
					returnPacket.Data:Sync(true);

				else
					shared.Notify(player, "Add resource failed: "..returnPacket.FailMsg, "Negative");
					
				end
				
				
			elseif action == "f" then
				local funcName = args[2];
				
				local params = {};
				for a=3, #args do
					table.insert(params, args[a]);
				end
				
				local func = Factions[funcName];
				if func then
					Debugger:Log("Invoking function ".. funcName .."(",params,")");
					local returns = func(unpack(params));
					Debugger:Log("Returns function ".. funcName ..">> ",returns);
					shared.Notify(player, "Faction function returned for "..funcName, "Inform");
					
				else
					shared.Notify(player, "No faction function: "..funcName, "Negative");
				end
				
			else
				shared.Notify(player, "Active FactionTag: ".. (factionTag or "nil") , "Inform");
				
			end

			return true;
		end;
	});
end)


--== factionSerializer
factionSerializer:AddClass(FactionGroup.ClassType, FactionGroup.new);	--For saving and loading classes.
factionSerializer:AddClass(FactionUser.ClassType, FactionUser.new);
factionSerializer:AddClass(FactionMeta.ClassType, FactionMeta.new);
factionsDatabase:BindSerializer(factionSerializer);


return Factions
