local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TeleportService = game:GetService("TeleportService");
local MessagingService = game:GetService("MessagingService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

local remoteFactionService = modRemotesManager:Get("FactionService");

local PermissionFlags = modGlobalVars.FactionPermissions;
local scoreboardKey = modLeaderboardService.FactionBoardKey;
--==
local FactionGroup = {};
FactionGroup.__index = FactionGroup;
FactionGroup.ClassType = "Factions";

FactionGroup.Title="Unnamed";
FactionGroup.Icon="9890634236";
FactionGroup.Description="~";
FactionGroup.Color="c8c8c8";

function FactionGroup.new()
	local meta = {}
	meta.__index = meta;

	meta.OnSerialize = function(self)
	end

	meta.OnDeserialize = function(self, rawData)
		meta.PseudoRandom = modPseudoRandom.new({
			Name=self.Tag;
			UserId=self.Owner;
		});
		
	end;

	local self = {
		Tag="";
		Owner="";
		Members={};
		MemberCount=0;
		JoinRequests={};
		RoleKeyCount=0;
		Roles={};
		LastUpdate=0;
		Gold=0;
		Logs={};
		
		Resources={
			Food=0;
			Ammo=25;
			Material=50;
			Power=75;
			Comfort=100;
		};

		Missions={
			Active={};
			Available={};
			LastRoll=0;
		};
		
		HqAccessCode = "";
		HqHost = "";
		
		SafehomeId = "default";
		SafehomeCustomizations = {};
		
		-- TestFlags
		TestGoldReward = false;
	};

	self[scoreboardKey] = 0;
	self["W_"..scoreboardKey] = 0;
	self["D_"..scoreboardKey] = 0;
	
	self.WeekEndTime = 0;
	self.DayEndTime = 0;
	
	setmetatable(self, meta);
	setmetatable(meta, FactionGroup);

	self:SetRole("Owner", {Rank=0; Title="Owner"; Color="aa7800"; Perm=PermissionFlags.Size;});
	self:SetRole("Member", {Rank=99; Title="Member"; Color="ffffff"; Perm=0;});
	return self;
end

function FactionGroup:AddScore(amount)
	if self[scoreboardKey] == nil then Debugger:Log("Missing scoreboard Key", scoreboardKey) return end;
	
	local weekEndTime = modSyncTime.TimeOfEndOfWeek();
	if weekEndTime ~= self.WeekEndTime then
		if self.WeekEndTime ~= 0 then
			self["W_"..scoreboardKey] = 0;
		end
		self.WeekEndTime = weekEndTime;
	end
	local dayEndTime = modSyncTime.TimeOfEndOfDay();
	if dayEndTime ~= self.DayEndTime then
		if self.DayEndTime ~= 0 then
			self["D_"..scoreboardKey] = 0;
		end
		self.DayEndTime = dayEndTime;
	end
	
	self[scoreboardKey] = self[scoreboardKey] + amount;
	self["W_"..scoreboardKey] = self["W_"..scoreboardKey] + amount;
	self["D_"..scoreboardKey] = self["D_"..scoreboardKey] + amount;
end

function FactionGroup:SetRole(roleKey, configs)
	local roleConfig = self.Roles[roleKey] or {};
	
	roleConfig.Title = configs.Title;
	roleConfig.Rank = configs.Rank;
	roleConfig.Color = configs.Color;
	roleConfig.Perm = configs.Perm or 0;

	if roleKey == "Owner" then
		roleConfig.Rank = 0;
	elseif roleKey == "Member" then
		roleConfig.Rank = 99;
	else
		roleConfig.Rank = math.clamp(tonumber(roleConfig.Rank) or 98, 1, 98);
	end

	self.Roles[roleKey] = roleConfig;
end

function FactionGroup:HasPermission(userId, flag, affectingTypes)
	if self.Owner == tostring(userId) then
		return true;
	end

	local hasPerm = false;
	if self.Members[userId] then
		local userRole, userRoleConfig = self:GetRole(userId);

		if userRoleConfig then
			hasPerm = PermissionFlags:Test(flag, userRoleConfig.Perm or 0);
		end

		if affectingTypes then
			if affectingTypes.UserId or affectingTypes.RoleKey then
				affectingTypes = {affectingTypes};
			end

			for a=1, #affectingTypes do
				local permAff = affectingTypes[a];

				local permAffRole, permAffRoleConfig = permAff.RoleKey, nil;
				if permAff.UserId then
					permAffRole, permAffRoleConfig = self:GetRole(permAff.UserId);
				end

				if permAff.RoleKey then
					permAffRoleConfig = permAffRoleConfig or self.Roles[permAffRole];

					local permAffRank = permAffRoleConfig and permAffRoleConfig.Rank or 99;
					if permAff.RoleKey == "__new" then
						permAffRank = permAff.Rank;
						Debugger:Log("affRoleRank", permAffRank);
					end

					if userRoleConfig.Rank >= permAffRank then
						hasPerm = false;
						Debugger:Log("user no perm to affect this role", permAff.RoleKey);
					end
				end
			end
		end
	end
	if hasPerm then return true; end;

	if userId == "16170943" and modGlobalVars.FactionBypass == true then
		Debugger:Log("Khronos ",flag," perm bypass ", self.Owner);
		return true;
	end

	return false;
end


function FactionGroup:SetLeader(userId)
	self.Owner = userId;
end


function FactionGroup:SetMember(factionUser) -- factionUser is most up to date. However, only contains FactionUser data.
	local memberTable = {
		Role="Member";
	};

	local userId = factionUser.UserId;

	local oldMemberTable = self.Members[userId];
	if oldMemberTable then
		for k, v in pairs(memberTable) do
			if oldMemberTable[k] then
				memberTable[k] = oldMemberTable[k];
			end
		end
	end

	memberTable.UserId = userId;
	memberTable.Name = factionUser.Name;
	memberTable.LastActive = factionUser.LastActive;

	memberTable.Role = self.Roles[factionUser.Role] and factionUser.Role or "Member";
	if self.Owner == userId then
		memberTable.Role = "Owner";
	elseif memberTable.Role == "Owner" then
		memberTable.Role = "Member";
	end


	--
	memberTable.SuccessfulMissions = factionUser.SuccessfulMissions;
	memberTable.ScoreContribution = factionUser.ScoreContribution;
	memberTable.TopMissions = factionUser.TopMissions;

	self.Members[userId] = memberTable;
	self:MembersChanged();
end


function FactionGroup:AddMember(factionUser)
	local userId = factionUser.UserId;
	
	self:SetMember(factionUser);
	
	return self.Members[userId];
end


function FactionGroup:MembersChanged()
	self.MemberCount = 0;

	for userIds, userObj in pairs(self.Members) do 
		self.MemberCount = self.MemberCount +1;
	end;
end


function FactionGroup:DelMember(userId, reason)
	userId = tostring(userId);
	local userObj = self.Members[userId];
	local success = false;

	if userObj then
		self.Members[userId] = nil;
		success = true;
	end

	self:MembersChanged();
	return success;
end


function FactionGroup:DelRole(roleKey)
	if roleKey == "Owner" or roleKey == "Member" then return end;

	for k, data in pairs(self.Members) do
		if data.Role == roleKey then
			self.Members[k].Role = "Member";
		end
	end
	self.Roles[roleKey] = nil;
end


function FactionGroup:Notify(msg, style)
	task.spawn(function()
		shared.ChatService:ProccessGlobalChat("Game", ("["..self.Tag.."]"), msg, {Style=(style or "Inform")})
	end)
end


function FactionGroup:AcceptJoinRequest(userId, factionUser)
	if self.JoinRequests[userId] == nil then Debugger:Warn("Missing join request for ", userId) return end;
	if factionUser == nil then Debugger:Warn("Missing userObj", userId) return end;

	factionUser.Tag = self.Tag;
	self:SetMember(factionUser);
	self.JoinRequests[userId] = nil;
end


function FactionGroup:Clean(player)
	local unixTimestamp = DateTime.now().UnixTimestamp;
	local r = modGlobalVars.CloneTable(self);

	r.ClassType = "FactionsCleaned";
	if player then
		r.Title = shared.modAntiCheatService:Filter(self.Title, player);
		r.Tag = shared.modAntiCheatService:Filter(self.Tag, player);
		r.ChannelId = "["..self.Tag.."]";
		r.Description = shared.modAntiCheatService:Filter(self.Description, player);

		local memberData = self.Members[tostring(player.UserId)];
		if memberData then
			local userRole = memberData.Role or "Member";

			if not self:HasPermission(tostring(player.UserId), "CanViewSettings") then
				r.Logs = {};

				for roleKey, roleConfig in pairs(r.Roles) do
					if roleKey == userRole then continue end;
					roleConfig.Perm = 0;
				end
			end
		end
	end
	
	r.Color = self.Color;
	r.Missions = self.Missions;
	r.Resources = self.Resources;
	r.Icon = self.Icon;
	r.Gold = self.Gold;
	
	r.SafehomeId = self.SafehomeId;
	
	r.HqHost = self.HqHost;
	
	--=
	r.TestGoldReward = self.TestGoldReward;
	
	return r;
end


function FactionGroup:GetRole(userId)
	userId = tostring(userId);
	if self.Owner == userId then
		return "Owner", self.Roles.Owner;
	end

	local userRole = self.Members[userId].Role or "Member";
	local roleConfig = self.Roles[userRole];
	return userRole, roleConfig;
end

function FactionGroup:SetHqHost(playerName)
	local ownerName = "";
	local membersList = {};

	for memberId, memberData in pairs(self.Members) do
		if tostring(memberId) == self.Owner then
			ownerName = memberData.Name;
		end
		table.insert(membersList, memberData.Name);
	end
	
	if table.find(membersList, playerName) then
		self.HqHost = playerName;

	else
		self.HqHost = ownerName;

	end
end

function FactionGroup:Sync(onlineOnly)
	local unixTimestamp = DateTime.now().UnixTimestamp;
	
	if typeof(onlineOnly) == "function" then
		onlineOnly = true;
		Debugger:Warn("deprecated :Sync param", debug.traceback());
	end
	
	for userIdStr, memObj in pairs(self.Members) do
		local memberName = memObj.Name;
		
		local playerMember = game.Players:FindFirstChild(memberName);
		if playerMember then
			task.spawn(function()
				remoteFactionService:InvokeClient(playerMember, "sync", {
					FactionObj=self:Clean(playerMember)
				});
			end)
			
		else
			if onlineOnly == true then
				continue;
			end
			
			task.spawn(function()
				if (unixTimestamp-memObj.LastActive > 300) then
					return;
				end
				
				local placeId, instanceId = modServerManager:FindPlayerServer(memberName, false);
				if placeId == nil then
					return;
				end
				
				local packet = {
					Request = "SyncFaction";
				};
				Debugger:Warn("PublishAsync", "Msg"..userIdStr, "SyncFaction");
				MessagingService:PublishAsync("Msg"..userIdStr, packet);
			end)
			
		end
	end
end


function FactionGroup:Log(logType, values)
	local timestamp = DateTime.now().UnixTimestamp;

	local logPacket = {
		Tick=timestamp;
		Type=logType;
		Values=values;
	};

	local logLimit = 50;
	if #self.Logs >= logLimit then
		for a=1, #self.Logs - logLimit do
			table.remove(self.Logs, 1);
			if #self.Logs <= 0 then break; end;
		end
	end
	table.insert(self.Logs, logPacket);
end


function FactionGroup:AddResources(key, value, log)
	if value == 0 then return end;
	
	self.Resources[key] = math.clamp(self.Resources[key] + value, 0, 100);
	
	if log then
		self:Log("resourcechange", {Key=key; Value=value;});
	end
end

function FactionGroup:AddGold(value, analyticsKey, reason)
	analyticsKey = analyticsKey or "Others";
	
	self.Gold = self.Gold + value;
	self:Log("addgold", {value; analyticsKey; reason});

	modAnalytics.RecordResource(tonumber(self.Owner), value, "Source", "Gold", "Faction", analyticsKey);
end

return FactionGroup;
