local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local BadgeLibrary = {
	Premium=479110154;
	Welcome=478975214;
}

local RbxDataLimit = 4000000;
local month = {"January"; "February"; "March"; "April"; "May"; "June"; "July"; "Augest"; "September"; "October"; "November"; "December";};

local dayInSec = 3600*20;
--== Variables;
local Profile = {};
Profile.Profiles = {};
Profile.MaxSaves = 1;
Profile.PickUpRequest = nil;
--Profile.GroupRank = {Tester=1;Staff=2;Founder=3;};

local MarketplaceService = game:GetService("MarketplaceService");
local BadgeService = game:GetService("BadgeService");
local HttpService = game:GetService("HttpService");
local RunService = game:GetService("RunService");
local MessagingService = game:GetService("MessagingService");
local DataStoreService = game:GetService("DataStoreService");
local PolicyService = game:GetService("PolicyService");
local LocalizationService = game:GetService("LocalizationService");
local MemoryStoreService = game:GetService("MemoryStoreService");


local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = Debugger:Require(game.ReplicatedStorage.Library.RemotesManager);
local modColorsLibrary = Debugger:Require(game.ReplicatedStorage.Library.ColorsLibrary);
local modSkinsLibrary = Debugger:Require(game.ReplicatedStorage.Library.SkinsLibrary);
local modCollectiblesLibrary = Debugger:Require(game.ReplicatedStorage.Library.CollectiblesLibrary);
local modSettings = Debugger:Require(game.ReplicatedStorage.Library.Settings);
local modGlobalVars = Debugger:Require(game.ReplicatedStorage.GlobalVariables);
local modEventSignal = Debugger:Require(game.ReplicatedStorage.Library.EventSignal);
local modPlayerTitlesLibrary = Debugger:Require(game.ReplicatedStorage.Library.PlayerTitlesLibrary);
local modPseudoRandom = Debugger:Require(game.ReplicatedStorage.Library.PseudoRandom);
local modItemsLibrary = Debugger:Require(game.ReplicatedStorage.Library.ItemsLibrary);
local modSyncTime = Debugger:Require(game.ReplicatedStorage.Library.SyncTime);
local modJsonValidator = Debugger:Require(game.ReplicatedStorage.Library.JsonValidator);
local modSerializer = require(game.ReplicatedStorage.Library.Serializer);
local modStorageItem = require(game.ReplicatedStorage.Library.StorageItem);
local modTableManager = require(game.ReplicatedStorage.Library.TableManager);
local modBitFlags = require(game.ReplicatedStorage.Library.BitFlags);

local FirebaseService = Debugger:Require(game.ServerScriptService.ServerLibrary.FirebaseService);
local modGameSave = Debugger:Require(game.ServerScriptService.ServerLibrary.GameSave);
local modFlags = require(game.ServerScriptService.ServerLibrary.Flags);
local modSkillTree = Debugger:Require(game.ServerScriptService.ServerLibrary.SkillTree);
local modTraderProfile = Debugger:Require(game.ServerScriptService.ServerLibrary.TraderProfile);
local modBlueprints = Debugger:Require(game.ServerScriptService.ServerLibrary.Blueprints);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modAnalyticsProfile = Debugger:Require(game.ServerScriptService.ServerLibrary.AnalyticsProfile);
local modItemUnlockables = Debugger:Require(game.ServerScriptService.ServerLibrary.ItemUnlockables);
local modBattlePassSave = Debugger:Require(game.ServerScriptService.ServerLibrary.BattlePassSave);
local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);

local remotes = game.ReplicatedStorage.Remotes;
local remotePlayerDataSync = modRemotesManager:Get("PlayerDataSync");


local remoteMasterySync = modRemotesManager:Get("MasterySync");
local remoteRequestPublicProfile = modRemotesManager:Get("RequestPublicProfile");
local remoteOnInvitationsUpdate = modRemotesManager:Get("OnInvitationsUpdate");
local remoteSetPlayerTitle = modRemotesManager:Get("SetPlayerTitle");
local remoteHudNotification = modRemotesManager:Get("HudNotification");
local remotePromptWarning = remotes.Interface.PromptWarning;

local random = Random.new();

local hardModeBitFlag = modBitFlags.new();
hardModeBitFlag:AddFlag("Slow", 1);
hardModeBitFlag:AddFlag("LongerLoad", 2);
hardModeBitFlag:AddFlag("KickLoad", 3);
hardModeBitFlag:AddFlag("RngCrash", 4);

--== Script;
local profileDatabase = FirebaseService:GetFirebase("Profiles");
local dataSizeDatabase = DataStoreService:GetOrderedDataStore("DataSize");

--== LiveProfile
local liveProfileDatabase = modDatabaseService:GetDatabase("LiveProfiles");
local liveProfileSerializer = modSerializer.new();

Profile.LiveProfileDatabase = liveProfileDatabase;

local LiveProfile = {};
LiveProfile.__index = LiveProfile;
LiveProfile.ClassType = "LiveProfile";

function LiveProfile.new(userId)
	local self = {
		Key=tostring(userId);
		LastOnline=-1;
		AccessCode="";
		
		HacModules = {};
		TaskQueue={};
	};

	setmetatable(self, LiveProfile);
	return self;
end

function LiveProfile:IsOnline()
	local unixTime = DateTime.now().UnixTimestamp;
	
	if (unixTime - self.LastOnline) > 60 then
		return false;
	end
	return true;
end

--function LiveProfile:AddTask()
	
--end

liveProfileSerializer:AddClass(LiveProfile.ClassType, LiveProfile.new);
liveProfileDatabase:BindSerializer(liveProfileSerializer);
--==

modBlueprints.Profiles = Profile;

Profile.OnProfileSave = modEventSignal.new("OnProfileSave");
Profile.OnProfileLoad = modEventSignal.new("OnProfileLoad");
Profile.OnPlayerPacketRecieved = modEventSignal.new("OnPlayerPacketRecieved");

function Profile:GetLastOnline(userId)
	local userKey;
	if userId then
		userKey = tostring(userId);
	elseif self then
		userKey = tostring(self.UserId);
	end
	
	local lastOnline = -1;
	local _, _ = pcall(function()
		local lastOnlineData = MemoryStoreService:GetSortedMap("LastOnline");
		lastOnline = lastOnlineData:GetAsync(userKey);
	end)
	
	return lastOnline;
end

function Profile:GetLiveProfile(userId)
	local _unixTime = DateTime.now().UnixTimestamp;
	
	local userKey;
	if userId then
		userKey = tostring(userId);
	elseif self then
		userKey = tostring(self.UserId);
	end
	
	local liveProfile = liveProfileDatabase:Get(userKey);
	if liveProfile == nil then return end;
	--if rawString == nil then return end;
	
	--local liveProfile = liveProfileSerializer:Deserialize(rawString);

	liveProfile.LastOnline = self:GetLastOnline(userKey);
	liveProfile.AccessCode = nil;
	local getAccessCodeS, getAccessCodeE = pcall(function()
		local accessCodeData = MemoryStoreService:GetSortedMap("AccessCode");
		liveProfile.AccessCode = accessCodeData:GetAsync(userKey);
	end)
	if not getAccessCodeS then Debugger:Warn(":GetLiveProfile getAccessCodeE:",getAccessCodeE) end;
	
	return liveProfile;
end

function Profile.new(player) -- Contains player to game statistics. Not character save data.
	local playerName = player.Name;
	local profile = Profile.Profiles[playerName];
	if profile == nil then
		profile = {};

		local unixTime = DateTime.now().UnixTimestamp;
		
		local profileMeta = setmetatable({}, {__index=Profile;});
		profileMeta.__index = profileMeta;
		profileMeta.SaveCooldown = unixTime;
		profileMeta.Loaded = false;
		profileMeta.Player = player;
		profileMeta.ActiveSave = nil;
		profileMeta.EquippedTools = {};
		profileMeta.Invitations = {};
		profileMeta.TeleportData = {};
		profileMeta.WeaponPropertiesCache = {};
		profileMeta.ItemClassesCache = {};
		profileMeta.ToolsCache = {};
		profileMeta.Analytics = modAnalyticsProfile.new(player);
		profileMeta.Junk = {CacheInstances = {};};
		profileMeta.Cache = {
			CasualRandom = modPseudoRandom.new();
			PickupCache = {};
		};
		profileMeta.PlaytimeTick = tick();
		profileMeta.MockStorageItem = modStorageItem.new();
		profileMeta.MockStorageItem.MockItem = true;
		profileMeta.MockStorageItem.ID = "MockStorageItem";
		profileMeta.MockStorageItem:UpdatePlayer(player);
		profileMeta.MockStorageItem:SetStorageId("MockStorageItem");

		profileMeta.HardModeBitFlag = hardModeBitFlag;
		
		function profileMeta:GetHardMode(tag)
			return hardModeBitFlag:Test(tag, self.HardMode or 0);
		end
		function profileMeta:SetHardMode(tag, value)
			self.HardMode = hardModeBitFlag:Set(self.HardMode, tag, value);
		end
		
		local CacheStorage = setmetatable({}, {__newindex=function(t, k, v) rawset(t, k, v); delay(600, function() t[k]=nil; end) end});
		
		function profileMeta:GetCacheStorages()
			return CacheStorage;
		end
		
		profile.SessionLock = 0;
		profile.SaveIndex = 0; -- Save Version;
		profile.IdCounter = 0;
		profile.Name = player.Name;
		profile.UserId = player.UserId;
		profile.Premium = false;
		profile.ReferralList = {};
		profile.ReferredBy = false;

		profile.Saves = {};
		
		profile.PlayTime = 0;
		profile.PlayPoints = 0;
		profile.TrustLevel = 0;
		profile.TrustTable = {};
		profile.OnlineStreak = 0;
		
		
		profile.Purchases = {};
		profile.ColorPacks = {Dull=true;};
		profile.SkinsPacks = {Basic=true};
		profile.SkillTree = modSkillTree.new(player);
		profile.Achievements = {};
		profile.Punishment = 0;

		profile.HardMode = 0;
		
		profile.FirstJoined = unixTime;
		profile.FirstOnline = unixTime; -- tracks session duration;
		profile.LastOnline = unixTime;
		
		profile.Collectibles = {};
		profile.TitleId = "";

		--== Ban
		profile.ShadowBan = 0;
		profile.TradeBan = 0;
		profile.FactionBan = 0;
		profile.Reports = 2;

		--== Squad Integration
		profile.ActiveSquad = {};

		profile.GamePass = {};
		profile.Settings = {
			ToggleClothing={};
		};

		--== Leaderboard
		profile.LeaderstatsTimer = unixTime-120;
		profile.AllTimeStats = {};
		profile.WeeklyStats = {};
		profile.DailyStats = {};
		profile.WeekEndTime = 0;
		profile.DayEndTime = 0;

		profile.PolicyData = {
			ArePaidRandomItemsRestricted = true;
			AllowedExternalLinkReferences = {};
			IsPaidItemTradingAllowed = false;
			IsSubjectToChinaPolicies = true;
			Locale = ""; -- lang, analytics;
		};
		
		profile.PseudoRandom = modPseudoRandom.new(player);
		profile.Flags = modFlags.new(player, function() profile:Sync("Flags"); end);

		--Any attributes default as nil will not be saved.
		setmetatable(profile, profileMeta);
		profile.GameSave = modGameSave.new(profile);
		
		--== Integrations;
		if modGlobalVars.EngineMode == "RiseOfTheDead" then
			profile.ItemUnlockables = modItemUnlockables.new(player);
			profile.Trader = modTraderProfile.new(player);
			
			local modSafehomeData = require(game.ServerScriptService.BaseServerLibrary.SafehomeData);
			profile.Safehome = modSafehomeData.new(player);
			profile.BattlePassSave = modBattlePassSave.new(profile, function() profile:Sync("BattlePassSave"); end);
			
			--== Faction Integration
			profile.Faction = {
				FactionTitle="n/a";
				FactionIcon="9890634236";
			}
			
		else
			local moddedSelf = modModEngineService:GetServerModule(script.Name);
			if moddedSelf then
				moddedSelf:OnNewProfile(Profile, profile);
			end
			
		end
		
		profileMeta.__newindex = function(self, key, value) if rawget(profile, key) == nil then profileMeta[key] = value; end; end;
		Profile.Profiles[playerName] = profile;
	end
	
	profile:Load();
	profile:UpdateTrustLevel();
	
	task.spawn(function()
		local key = tostring(profile.UserId);
		if liveProfileDatabase:Get(key) == nil then
			liveProfileDatabase:Publish(key, function(rawData)
				if rawData ~= nil then Debugger:Warn("Player (",profile.Player,") live profile already exist.", rawData); return end;
				
				return liveProfileSerializer:Serialize(LiveProfile.new(key));
			end)
		end

		liveProfileDatabase:SetUserId(key, {player.UserId});
	end)
	
	return profile;
end

function Profile:Get(player)
	if player == nil or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return;
	end;
	return Profile.GetByName(player.Name);
end

function Profile:InitMessaging()
	self.MsgTopic = "Msg"..self.UserId;
	self.MsgCount = 0;
	self.LastMsg = 0;
	self.OnMessageRecieved = modEventSignal.new("OnMessageRecieved");
	
	local subscribeS, subscribeE;
	task.spawn(function()
		while true do
			subscribeS, subscribeE = pcall(function()
				self.MessageConnection = MessagingService:SubscribeAsync(self.MsgTopic, function(...)
					self.OnMessageRecieved:Fire(...);
					Profile.OnPlayerPacketRecieved:Fire(self, ...);
				end)
				Debugger:Log("Connected player (",self.Player,") MessageConnection.");
			end)
			if subscribeS then break; else Debugger:Warn("Failed to subscribe player (",self.Player,") :", subscribeE) end;
			
			task.wait(10);
			if not self.Player:IsDescendantOf(game.Players) then break; end;
		end
	end)
end


--[[
local data = {
	Request = "TravelRequest";
	Sender = player.Name;
	Value = {
		VisitorId=player.UserId;
		UserName=player.Name;
		PlaceId=game.PlaceId;
	}
};

--]]
function Profile:SendMsg(topic, data)
	if self.MsgCount >= 10 and os.time()-self.LastMsg <= 60 then return; end
	if self.MsgCount >= 10 then self.MsgCount = 0 end;
	self.MsgCount = self.MsgCount +1;
	MessagingService:PublishAsync(topic, data);
	return true;
end


function Profile:WaitForProfile(player, duration)
	local name = player.Name;
	if Profile.Profiles[name] and Profile.Profiles[name].Loaded then return Profile.Profiles[name] end;
	
	local timeout = tick();
	duration = duration or 60;
	
	local printTick = tick();
	repeat
		if (tick()-timeout) > 10 then
			task.wait((tick()-timeout)/10);
		else
			task.wait();
		end
		if Profile.Profiles[name] and Profile.Profiles[name].Loaded then return Profile.Profiles[name] end;
		
		if tick()-printTick >= 10 then
			printTick = tick();
			Debugger:Warn("Waiting for Profile(",name,") Timing out:",math.round((tick()-timeout)*100)/100,"s");
		end
		
	until (Profile.Profiles[name] and Profile.Profiles[name].Loaded == true) or (tick()-timeout) > duration;
	if (tick()-timeout) >= duration then Debugger:Warn("Waiting for Profile(",name,") timed-out.", debug.traceback()); end;
	
	if Profile.Profiles[name] == nil then
		Debugger:Warn("Profile(",name,") does not exist.");
	elseif not Profile.Profiles[name].Loaded then
		Debugger:Warn("Profile(",name,") not loaded.");
	end
	return Profile.Profiles[name];
end

function Profile:Find(name)
	return Profile.Profiles[name];
end

function Profile:IsPremium(player)
	return Profile.Profiles[player.Name] and Profile.Profiles[player.Name].Premium;
end

function Profile.GetByName(name)
	if Profile.Profiles[name] and Profile.Profiles[name].Loaded then return Profile.Profiles[name] end;
	local timeout = tick();
	repeat task.wait() until (Profile.Profiles[name] and Profile.Profiles[name].Loaded == true) or (tick()-timeout) > 60;
	if Profile.Profiles[name] == nil or not Profile.Profiles[name].Loaded then
		Debugger:Warn("Profile(",name,") not loaded. Trace:",debug.traceback());
	end
	return Profile.Profiles[name];
end

function Profile:Unlock(category, key, value)
	self[category][key] = true;
	
	local unlockedName = "";
	if category == "ColorPacks" then
		local colorLib = modColorsLibrary.Packs[key];
		unlockedName = "Color Pack: "..colorLib.Name;
		
	elseif category == "SkinsPacks" then
		local skinLib = modSkinsLibrary.Packs[key];
		unlockedName = "Skin Pack: "..skinLib.Name;

	end
	remoteHudNotification:FireClient(self.Player, "Unlocked", {Name=unlockedName;});
	
	self:UpdateTrustLevel();
	self:AddPlayPoints(60);
	
	self:Sync(category.."/"..key);
end

function Profile:UnlockCollectible(id)
	if id == nil then return end;
	local lib = modCollectiblesLibrary:Find(id);
	if lib == nil then Debugger:Warn("Invalid collectible (",id,")"); return end;
	if self.Collectibles[id] == nil then
		shared.Notify(self.Player, "You have found a collectible! ("..lib.Name..")", "Tier"..lib.Tier);
	end
	self.Collectibles[id] = true;
	self:UpdateTrustLevel();
	self:AddPlayPoints(60);
	
	self:Sync("Collectibles");
end

function Profile:UnlockItemCodex(id, sync)
	local itemCodexFlag = self.Flags:Get("ItemCodex", {Id="ItemCodex"; Data={};});
	
	if id then
		if itemCodexFlag and itemCodexFlag.Data[id] == nil then
			itemCodexFlag.Data[id] = true;

			if sync ~= false then
				self.Flags:Sync();
			end
		end
	else
		if sync == true then
			self.Flags:Sync();
		end
	end
end

function Profile:AwardPremium(temp)
	if self.Premium then return end;
	local player = self.Player;
	self.Premium = true;
	if temp ~= true and BadgeService:IsLegal(BadgeLibrary.Premium) and not BadgeService:UserHasBadge(player.UserId, BadgeLibrary.Premium) then
		BadgeService:AwardBadge(player.UserId, BadgeLibrary.Premium);
	end
	local randomMessages = {
		player.Name.." has just ascended to Premium!";
		"Roll out the red carpet, "..player.Name..", the new Premium has arrived!";
		"We've been expecting a new Premium, "..player.Name.." is here!";
		player.Name.." is now a member of the Premium club!";
		player.Name.." can't wait to try out the new Premium features!";
		"Look who just got Premium, I am so jealous of "..player.Name.."!";
		"Step aside, "..player.Name.." got Premium and is now going to slay some hardcore zombies!";
		player.Name.." seeks to challenge more and acquired Premium! So brave!";
		"Remember the name.. "..player.Name.." has purged to become another Premium!";
		"Another Premium is in town, he is "..player.Name.." and he is ready to fight!";
		"Why did "..player.Name.." become Premium? Because he dares to seek more danger!";
	};
	shared.Notify(game.Players, randomMessages[random:NextInteger(1, #randomMessages)], "OnPremium");
	remoteHudNotification:FireClient(self.Player, "PremiumAward");
	self:UpdateTrustLevel();
	self:AddPlayPoints(3600);
	
	self:Sync("Premium");
end

function Profile:AddPlayPoints(points)
	self.PlayPoints = math.ceil(self.PlayPoints + math.clamp(points, 0, 3600));
end

function Profile:Refresh()
	if modGlobalVars.EngineMode == "RiseOfTheDead" then
		spawn(function()
			local player = self.Player;
			local userId = player.UserId;
			local s, e = pcall(function()
				local passPremium = MarketplaceService:UserOwnsGamePassAsync(userId, 2649294);
				if passPremium then
					local key = "passPremium";
					local assetKey = tostring(868283950); -- assetid, deprecated
					if self.Purchases[assetKey] then
						self.Purchases[assetKey] = nil;
						self.Purchases[key] = 1;

					end
					self.Purchases[key] = 1;
				end;
				
				local passWorkbench = MarketplaceService:UserOwnsGamePassAsync(userId, 2517190);
				if passWorkbench then
					local key = "passWorkbench";
					local assetKey = tostring(849095628); -- assetid, deprecated
					if self.Purchases[assetKey] then
						self.Purchases[assetKey] = nil;
						self.Purchases[key] = 1;
					end
					self.Purchases[key] = 1;
					
					self.GamePass.PortableWorkbench = true;
				end;

				local passVipTraveler = MarketplaceService:UserOwnsGamePassAsync(userId, 18321499);
				if passVipTraveler then
					local key = "passVipTraveler";
					self.Purchases[key] = 1;
					self.GamePass.VipTraveler = true;
				end;
				
				local passDonation = MarketplaceService:UserOwnsGamePassAsync(userId, 932647);
				if passDonation then
					local key = "passDonation";
					local assetKey = tostring(291543276); -- assetid, deprecated
					if self.Purchases[assetKey] then
						self.Purchases[assetKey] = nil;
						self.Purchases[key] = 1;
					end
					self.Purchases[key] = 1;
					
				end;
				
				local badgePremium = BadgeService:UserHasBadge(player.UserId, BadgeLibrary.Premium);
				if passPremium or badgePremium then
					self:AwardPremium();
				end

				if BadgeService:IsLegal(BadgeLibrary.Welcome) and not BadgeService:UserHasBadge(player.UserId, BadgeLibrary.Welcome) then
					BadgeService:AwardBadge(player.UserId, BadgeLibrary.Welcome);
				end
			end)
			if not s then
				warn("Profile:Refresh() "..e)
			end
		end)
	end
	
	self.LastOnline = os.time();
end

function Profile.LoadRaw(userId)
	userId = tostring(userId);
	
	local rawData;
	local _, _ = pcall(function()
		local encodedData = profileDatabase.Datastore:GetAsync(userId);
		rawData = type(encodedData) == "string" and HttpService:JSONDecode(encodedData) or encodedData;
	end)
	
	return rawData;
end

function Profile:Load(loadOverwrite)
	local loadTick = tick();
	
	local loadKey = self.UserId;
	local encodedData, rawData;
	
	local waitTick = tick();
	local loadS, loadE;
	local decodeS, decodeE;
	
	local tempSetDebug = false;
	if RunService:IsStudio() then
		tempSetDebug = script:GetAttribute("Debug") == false;
		script:SetAttribute("Debug", true);
	end
	
	local function tryLoad()
		if not RunService:IsStudio() then
			repeat 
				if tick()-waitTick >= 5 then
					waitTick = tick();
					shared.Notify(self.Player, "Loading previous save, please wait..", "Inform");
					Debugger:Log("Loading ", self.Player, " save.. ",math.floor(tick()-waitTick));
				end
				task.wait();
				local getAsyncBudget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync);
				if getAsyncBudget >= 10 then
					break;
				else
					Debugger:Warn("Profile load waiting for request budget: ", getAsyncBudget);
				end
			until not game.Players:IsAncestorOf(self.Player);
			if not game.Players:IsAncestorOf(self.Player) then return end;
		end
		
		if encodedData then return end;
		 
		task.spawn(function()
			waitTick = tick();
			while encodedData == nil do
				if tick()-waitTick >= 5 then
					waitTick = tick();
					shared.Notify(self.Player, "Loading previous save, please wait..", "Inform");
					Debugger:Log("Loading ", self.Player, " save.. ",math.floor(tick()-waitTick));
				end
				task.wait(0.1);
			end
		end)
		encodedData = profileDatabase.Datastore:GetAsync(loadKey);
	end
	
	for a=1, 5 do
		loadS, loadE = pcall(function()
			local fetchTick = tick();
			tryLoad();
			
			Debugger:Log("Fetched profile player (",self.Player,") data: ", encodedData and #encodedData or "nil", "Took:",math.round((tick()-fetchTick)*100)/100,"s");
		end)
		
		if loadS then
			break;
		else
			local retryDelay = 2^a;
			Debugger:Warn("Failed to load save:", self.Player,"Retrying in:",retryDelay, "s\nError:", loadE); 
			task.wait(retryDelay); 
		end;
	end
	
	decodeS, decodeE = pcall(function()
		rawData = type(encodedData) == "string" and HttpService:JSONDecode(encodedData) or nil;
		
		if loadOverwrite then
			rawData = loadOverwrite;
		end
	end)
	if not loadS or not decodeS then
		remotePromptWarning:FireClient(self.Player, "Failed to load save data from Roblox, please try reconnecting...");
		shared.Notify(self.Player, "Failed to load save data from Roblox, please try reconnecting...", "Negative");
		
		Debugger:WarnClient(self.Player, "Please send the message below to the developer to assist you.");
		Debugger:WarnClient(self.Player, "Failed to load data ("..loadKey.."), Error: "..(loadE or decodeE));
		modAnalytics:ReportError("Load Profile Error", (loadE or decodeE));
		return;
	end

	local dataExpired = false;
	local _isPremium = rawData and rawData.Premium or false;
	if self.UserId > 0 and rawData and rawData.LastOnline
		and modBranchConfigs.IsWorld("MainMenu") and modBranchConfigs.CurrentBranch.Name == "Dev" 
		and rawData.LastOnline+691200 <= modSyncTime.TimeOfEndOfWeek() then -- rawData.LastOnline+86400 <= dayEndTick();
		Debugger:WarnClient(self.Player, "Your save data has expired. It is now wiped.");
		remotePromptWarning:FireClient(self.Player, "Your dev branch save data has expired, it is now wiped.");
		rawData = nil;
		dataExpired = true;
	end
	
	local resetReports = false;
	if rawData and self.UserId > 0 and rawData.LastOnline and rawData.LastOnline+86400 <= modSyncTime.TimeOfEndOfDay() then
		resetReports = true;
	end
	
	if rawData and rawData.LastOnline then
		local weekEndTime = modSyncTime.TimeOfEndOfWeek();
		if weekEndTime ~= rawData.WeekEndTime then
			if rawData.WeekEndTime ~= 0 then
				rawData.WeeklyStats = {};
			end
			getmetatable(self).WeekRollOver = true;
			rawData.WeekEndTime = weekEndTime;
		end
		local dayEndTime = modSyncTime.TimeOfEndOfDay();
		if dayEndTime ~= rawData.DayEndTime then
			if rawData.DayEndTime ~= 0 then
				rawData.DailyStats = {};
			end
			getmetatable(self).DayRollOver = true;
			rawData.DayEndTime = dayEndTime;
		end
		--if rawData.LastOnline+691200 <= modSyncTime.TimeOfEndOfWeek() then
		--	rawData.WeeklyStats = {};
		--end
		--if rawData.LastOnline+86400 <= modSyncTime.TimeOfEndOfDay() then
		--	rawData.DailyStats = {};
		--end
		
		local _lastOnline = rawData.LastOnline;
		local _firstOnline = rawData.FirstOnline;
		local timelapsed = (os.time() - (rawData.FirstOnline or 0))
		
		if timelapsed >= dayInSec then
			rawData.FirstOnline = os.time();
			
			if timelapsed <= dayInSec*2 then
				rawData.OnlineStreak = (rawData.OnlineStreak or 0) +1;
				
			else
				rawData.OnlineStreak = 0;
				
			end
			Debugger:Warn("Login consecutive:", rawData.OnlineStreak, "Logged in yesterday:", timelapsed <= dayInSec*2);
		end
	end
	
	if rawData ~= nil then
		self.IdCounter = rawData.IdCounter or 1;
		
		for key, value in pairs(self) do
			local data = rawData[key] or self[key];
			
			if key == "Saves" then
				if #data > 0 then
					self.GameSave:Load(data[1]);
				end
				--local newSaves = {};
				--for saveDataIndex=1, #data do
				--	local saveObj = modGameSave.new(self);
				--	saveObj.Profile = self;
				--	saveObj:Load(data[saveDataIndex]);
				--	table.insert(newSaves, saveObj);
				--end

				--if self.SaveData == nil then
				--	self[key] = {};
				--	self.SaveData = newSaves[1];
				--end
				
			elseif key == "GameSave" then
				self[key]:Load(data);
				
			--elseif key == "Cosmetics" then
			--	self[key] = modCosmetics.load(data);
				
			elseif key == "SkillTree" then
				self[key]:Load(data);
				
				
			elseif key == "Flags" then
				self[key]:Load(data);
				
			elseif key == "PseudoRandom" then
				self[key]:Load(data);
				
			elseif key == "Settings" then
				for k, v in pairs(data) do
					if modSettings[k] then
						self.Settings[k] = modSettings.Fix(self.Player, k, v);
					end;
				end
				
			--elseif key == "Trader" then
			--	self[key]:Load(data);
			--	self[key]:LoadTrades();

			--elseif key == "Safehome" then
			--	self[key]:Load(data);
				
			elseif key == "HardMode" then
				self[key] = data;
				
				if data > 0 then
					local hmList = self.HardModeBitFlag:List(self.HardMode);
					for tag, v in pairs(hmList) do
						if v == true then
							self.Player:SetAttribute("hm_"..self.HardModeBitFlag.Names[tag], v);
						end
					end
				end
				
			elseif key == "Name" or key == "IdCounter" or key == "UserId" then
			else
				local loaded = false;
				
				if typeof(self[key]) == "table" and self[key].Load then
					self[key]:Load(data);
					loaded = true;
					Debugger:StudioLog("key",key,"loaded");
				end
				
				if not loaded then
					self[key] = data;
					if RunService:IsStudio() then
						Debugger:StudioLog("key",key,"setload");
					end
				end
				
			end
		end
		
		local loadCompleteStr = "Profile ("..self.Name..") loaded. Took "..(math.ceil((tick()-loadTick)*1000)/1000).." secs to load ("..(math.floor((#encodedData/RbxDataLimit)*1000 + 0.5)/1000)..")%.";
		if RunService:IsStudio() then
			Debugger:Warn(loadCompleteStr);
		else
			Debugger:Print(loadCompleteStr);
		end
	else
		if dataExpired then
			self.Reset = true;
		end
		Debugger:Print("Profile ("..self.Name..") setup completed. Took "..(math.ceil((tick()-loadTick)*1000)/1000)..".");
	end
	
	if (os.time()-self.SessionLock) <= 30 then
		task.spawn(function()
			modAnalytics:ReportError("Security Alert", self.Player.Name.." ("..self.UserId..") attempting to join a locked session..", "critical");
			shared.modGameLogService:Log(self.Player.Name.." ("..self.UserId..") attempting to join a locked session..", "Logs");
		end)
		self.Player:Kick("Session is currently locked.");
		return;
	end
	
	if resetReports then self.Reports = 2; end;
	if self.ShadowBan >= os.time() then self.ShadowBan = 0; end
	self.Loaded = true;
	self.Offline = false;
	self.SaveIndex = self.SaveIndex +1;
	
	self:SyncAuthSeed();
	self:GetPolicy();
	
	self:Refresh();
	
	Profile.OnProfileLoad:Fire(self.Player, self);
	
	if tempSetDebug then
		script:SetAttribute("Debug", false);
	end
end
	
function Profile:GetPolicy()
	pcall(function()
		local policyInfo = PolicyService:GetPolicyInfoForPlayerAsync(self.Player);
		if policyInfo then
			for k, v in pairs(policyInfo) do
				self.PolicyData[k] = v;
			end
		end
		
		local locale = LocalizationService:GetCountryRegionForPlayerAsync(self.Player);
		if locale then
			self.PolicyData.Locale = locale;
		end
	end)
end

function Profile:Save(override, force)
	if force ~= true and RunService:IsStudio() then Debugger:Log("Profile (",self.Name,") saving disabled."); return HttpService:JSONEncode(override or self); end;
	if self.FirstJoined == nil then Debugger:Warn("Profile (",self.Name,") saving failed."); return end;
	if not self.Loaded then Debugger:Warn("Profile (",self.Name,") not loaded to be saved."); return end;
	
	if self.Flags:Get("ItemCodex") == nil then
		local playerSave = self:GetActiveSave();
		if playerSave then
			for storageName, _ in pairs(playerSave.Storages) do
				playerSave.Storages[storageName]:Loop(function(storageItem)
					self:UnlockItemCodex(storageItem.ItemId);
				end)
			end
		end
	end
	
	local _saveStart = tick();
	Debugger:WarnClient(self.Player, "Saving data..");
	
	Profile.OnProfileSave:Fire(self.Player, self);
	
	if (os.time()-self.SaveCooldown) <= 6 then return end;
	self.SaveCooldown = os.time();
	
	local activeSave = self:GetActiveSave();
	if activeSave then
		activeSave.LastSave = os.time();
	end
	
	local saveTick = tick();
	self.LastOnline = os.time();
	
	if self.ActiveSquad.Id then
		self.ActiveSquad.ExpireTick = os.time();
	end
	
	local timePlayed = tick()-self.PlaytimeTick;
	self.PlayTime = math.ceil(self.PlayTime + timePlayed);
	self.PlaytimeTick = tick();
	
	if modBranchConfigs.IsWorld("Safehome") then
		if self.Safehome then
			self.Safehome.LastActive = os.time();
		end 
	end
	
	if self.Player == nil or not self.Player:IsDescendantOf(game.Players) then
		self.Offline = true;
	end
	
	local dataToEncode = override or self;
	local encodedData
	local parseS, _ = pcall(function()
		encodedData = HttpService:JSONEncode(dataToEncode);
	end)
	if not parseS then
		pcall(function() 
			local ver = modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild;
			local vSuccess, validatorErrLog = modJsonValidator:Check(dataToEncode);
			if not vSuccess then
				modAnalytics:ReportError(ver.."Load Profile JSON Error", validatorErrLog);
			end
		end)
		return;
	end
	
	local saveTries = 0;
	local saveSuccessful, failErr;
	repeat
		saveSuccessful, failErr = pcall(function()
			profileDatabase.Datastore:UpdateAsync(self.UserId, function(oldData, dataInfo)
				local decodeOld = oldData and HttpService:JSONDecode(oldData) or {};
				
				if self.SaveIndex >= (decodeOld.SaveIndex or -1) or self.Reset then
					return encodedData, {self.UserId};
				else
					return oldData, {self.UserId};
				end
			end)
		end)
		
		saveTries = saveTries+1;
		if saveSuccessful then
			break;
		else
			modAnalytics:ReportError("Save Profile Error", failErr, nil, self.UserId);
			Debugger:Warn("Profile ("..self.Name..")",self.UserId," Save unsuccessfull.. Retrying (",saveTries,").. ", failErr);
			task.wait();
		end
	until saveSuccessful or saveTries >= 5;
	
	Debugger:Log("Profile ("..self.Name..") saved. Took "..(math.ceil((tick()-saveTick)*1000)/1000).." secs to save ("..(math.floor((#encodedData/RbxDataLimit)*1000 + 0.5)/10)..")%.");
	self.Analytics:Submit();
	
	if self.Trader then -- Rise of the Dead
		self.Trader:SaveTrades();
	end
	
	task.spawn(function()
		local dataSizeLen = #encodedData;
		dataSizeDatabase:SetAsync(tostring(self.UserId), dataSizeLen);
	end)
	Debugger:WarnClient(self.Player, "Data saved.");
	
	self:GetPolicy();
	self:UpdateTrustLevel();

	return;
end

function Profile:Unload()
	local playerName = self.Name;
	local _playerUserId = self.UserId;
	self.Loaded = false;
	
	local playerSave = self:GetActiveSave();
	if playerSave then
		if playerSave.Inventory then
			playerSave.Inventory.OnChanged:Destroy();
			playerSave.Inventory.OnAccess:Destroy();
			playerSave.Inventory.OnItemAdded:Destroy();
		end
		if playerSave.Clothing then
			playerSave.Clothing.OnChanged:Destroy();
			playerSave.Clothing.OnAccess:Destroy();
			playerSave.Clothing.OnItemAdded:Destroy();
		end
		for storageName, _ in pairs(playerSave.Storages) do
			playerSave.Storages[storageName].OnChanged:Destroy();
			playerSave.Storages[storageName].OnAccess:Destroy();
			playerSave.Storages[storageName].OnItemAdded:Destroy();
		end
		if playerSave.Missions then
			playerSave.Missions:Unload();
		end
	end
	
	if self.MessageConnection then
		self.OnMessageRecieved:Destroy();
		self.MessageConnection:Disconnect();
	end
	
	Profile.Profiles[playerName] = nil;
	modPseudoRandom.Cache[playerName] = nil;
	self = nil;
	Debugger:Print("Player (",playerName,") profile unloaded.");
end

function Profile:ActivateSave()
	
	if self.GameSave then
		self.ActiveGameSave = self.GameSave;
		self.ActiveInventory = self.GameSave.Inventory;
	end
	
	if self.ActiveSave ~= nil then return end;
	Debugger:Log("Activating Save for (", self.Player,").");
	
	self.ActiveSave = 1;
	self.ActiveInventory:Sync();

	local _, erMsg = pcall(function()
		if self.Player then
			local _lastSaveData = os.date("*t", self:GetActiveSave().LastSave);
			--shared.Notify(self.Player, "Loaded last save data from "..date.day.." "..month[date.month]..", "..date.year.." ("..(date.hour > 12 and date.hour -12 or date.hour)..":"..date.min..":"..date.sec..").", "Inform");

			if self.ShadowBan == -1 then
				shared.Notify(self.Player, "Permanent shadow ban.", "Negative");

			elseif self.ShadowBan > 0 then
				local banDate = os.date("*t", self.ShadowBan);
				shared.Notify(self.Player, "Shadow banned until "..banDate.day.." "..month[banDate.month]..", "..banDate.year.." ("..(banDate.hour > 12 and banDate.hour -12 or banDate.hour)..":"..banDate.min..":"..banDate.sec..").", "Negative");

			end
		end
	end)
	if erMsg then warn("Warning:",erMsg); end;

	self:Sync("ActiveSave");
	self:Sync("ShadowBan");
	
	return self.ActiveGameSave;
end

function Profile:ResetSave()
	self.GameSave = modGameSave.new(self);
	self.SkillTree:ClearTrees();
	
	self.ActiveSave = nil;
	self:ActivateSave();
end

function Profile:GetActiveSave()
	self:ActivateSave();
	return self.GameSave;
end

function Profile:NewSave(title)
	if #self.Saves < Profile.MaxSaves then
		Debugger:Log("Creating new save data for (",self.Player.Name,").");
		local newSave = modGameSave.new(self);
		
		
		newSave.Missions:Start(1);
		
		table.insert(self.Saves, newSave);
		self.ActiveSave = #self.Saves;
		--self:SetActiveSave(#self.Saves);
		return newSave;
	else
		Debugger:Warn("Already maxed out saves.");
	end
	return nil;
end

function Profile:NewCustomSave()
	if #self.Saves < Profile.MaxSaves then
		local newSave = modGameSave.new(self);

		table.insert(self.Saves, newSave);
		self.ActiveSave = #self.Saves;
		--self:SetActiveSave(#self.Saves);
		return newSave;
	else
		Debugger:Warn("Already maxed out saves.");
	end
	return nil;
end


function Profile:Sync(hierarchyKey, paramPacket)
	if hierarchyKey == nil then
		if self.Trader then
			self.Trader:SyncGold();
		end
		if self.GameSave then
			self.GameSave:Sync();
		end
		self:Sync("Settings");
		self:Sync("Purchases");
		self:Sync("GamePass");
		self:Sync("Premium");
		self:Sync("Achievements");
		self:Sync("SkillTree");
		self:Sync("Collectibles");
		
	else
		local data = modTableManager.GetDataHierarchy(self, hierarchyKey);
		
		if RunService:IsStudio() then
			Debugger:Warn("[Studio] Profile Sync: ",hierarchyKey,"(",modRemotesManager.PacketSizeCounter.GetPacketSize{PacketData={data};},")");
		end
		
		paramPacket = paramPacket or {};
		paramPacket[modRemotesManager.Ref("Action")] = "sync";
		paramPacket[modRemotesManager.Ref("Data")] = data;
		paramPacket[modRemotesManager.Ref("HierarchyKey")] = hierarchyKey;
		
		remotePlayerDataSync:Fire(self.Player, paramPacket);
	end
	
	task.spawn(function()
		local modPlayers = require(game.ReplicatedStorage.Library.Players);
		local classPlayer = modPlayers.Get(self.Player);
		classPlayer.ClientReady = true;
	end)
end

function Profile:SyncAuthSeed(sync)
	self.Cache.AuthSeed = modPseudoRandom:NextInteger(self.Player, "Authenticator", 100000, 999999);
	self.Cache.ShotIdGen = Random.new(self.Cache.AuthSeed);
	
	if sync == false then return end;
	self:Sync("Cache/AuthSeed");
end

function Profile:SyncMastery()
	if self.ActiveSave and self.ActiveGameSave then
		local activeSave = self.ActiveGameSave;
		remoteMasterySync:FireAllClients(self.Player.Name, activeSave:GetStat("Level"));
	end
end

function Profile:SyncPublic(caller)
	if self.ActiveSave and self.ActiveGameSave then
		local activeSave = self.ActiveGameSave;
		
		local publicData = {};
		publicData.Name = self.Player.Name;
		publicData.Role = self.Role;
		publicData.GroupRank = self.GroupRank;
		publicData.Premium = self.Premium
		publicData.Stats = {};
		publicData.Collectibles = self.Collectibles;
		publicData.Achievements = activeSave.Achievements;
		publicData.Punishment = self.Punishment;
		publicData.TitleId = self.TitleId;
		
		if publicData.TitleId == nil and self.GroupRank and self.GroupRank > 1 then
			local rankId = "rank"..self.GroupRank;
			local titleLib = modPlayerTitlesLibrary:Find(rankId);
			if titleLib then
				publicData.TitleId = rankId;
			end
		end
	
		if self.Premium then
			activeSave:AwardAchievement("premem", false);
		end
		if self.GamePass.PortableWorkbench then
			activeSave:AwardAchievement("theeng", false);
		end
		if self.GamePass.VipTraveler then
			activeSave:AwardAchievement("theeng", false);
		end
		
		for k, v in pairs(activeSave.Stats) do
			if k ~= "Death" then
				publicData.Stats[k] = v;
			end
		end
		
		local completedMissions = 0;
		for a=1, #activeSave.Missions do
			if activeSave.Missions[a].Type == 3 then
				completedMissions = completedMissions + 1;
			end
		end
		
		local colorPackNames = {};
		for id,_ in pairs(self.ColorPacks) do
			local colorPackLib = modColorsLibrary.Packs[id];
			if colorPackLib then
				table.insert(colorPackNames, colorPackLib.Name);
			end
		end
		local skinPackNames = {};
		for id,_ in pairs(self.SkinsPacks) do
			local skinPackLib = modSkinsLibrary.Packs[id];
			if skinPackLib then
				table.insert(skinPackNames, skinPackLib.Name);
			end
		end
		
		publicData.Stats["MissionsCompleted"] = completedMissions;
		publicData.Stats["ColorPacks"] = table.concat(colorPackNames, ", ");
		publicData.Stats["SkinsPacks"] = table.concat(skinPackNames, ", ");
		
		publicData.Stats["TraderRep"] = math.floor(self.Trader:CalRep()*100).."%";
		
		local playerLevel = activeSave:GetStat("Level") or 0;
		local focusLevel = modGlobalVars.GetLevelToFocus(playerLevel);
		publicData.Stats["FocusLevel"] = focusLevel;
		
		if caller.Name == self.Player.Name then
			publicData.Statistics = activeSave.Statistics:Get();
		end
		
		return publicData;
	end
	return;
end

function Profile:NewID()
	self.IdCounter = self.IdCounter +1;
	return "#"..self.IdCounter;
end

function Profile:OnInvitationsUpdated()
	remoteOnInvitationsUpdate:FireClient(self.Player, self.Invitations);
end

local modWeapons = require(game.ReplicatedStorage.Library.Weapons);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);
local modWeaponsMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);

function Profile:GetItemClass(storageItemId, getShadowCopy)
	local playerSave = self:GetActiveSave(); 
	
	local storageItem, _itemStorage = playerSave:FindItemFromStorages(storageItemId);
	if storageItemId == "MockStorageItem" then
		storageItem = self.MockStorageItem;
		
	end
	
	if storageItem == nil then return end;
	
	local _player = storageItem.Player;

	local itemValues = storageItem.Values;
	local itemId = storageItem.ItemId;
	local itemLib = modItemsLibrary:Find(itemId);
	
	local classLib = nil;
	local classType = nil;

	local attachmentStorage = playerSave.Storages[storageItemId];
	
	local function update(class)
		if class.Reset then class:Reset(); end;
		if modConfigurations.SkipRotDModding == true then return class; end;

		if classType == "Weapon" then
			modWeaponsMechanics.UpdateWeaponPotential(itemValues.L, class);
			
			if itemValues and itemValues.Tweak then
				modWeaponsMechanics.ApplyTraits(storageItem, class);
			end
			
		elseif classType == "Clothing" then

			if itemValues and itemValues.Seed then
				if class.ApplySeed then
					class:ApplySeed(storageItem);
				end;
			end
		end
		
		if class.PreMod then
			class:PreMod();
		end

		if attachmentStorage and next(attachmentStorage.Container) then
			class = modWeaponsMechanics.ApplyPassiveMods(storageItem, attachmentStorage, class);
		end

		if class.PostMod then
			class:PostMod();
		end

		if class.CalculateDps then class:CalculateDps(); end
		if class.CalculateDpm then class:CalculateDpm(); end
		if class.CalculateMd then class:CalculateMd(); end
		if class.CalculateTad then class:CalculateTad(); end
		if class.CalculatePower then class:CalculatePower(); end
		
		return class;
	end
	
	if itemLib.Type == modItemsLibrary.Types.Tool then
		if modWeapons[itemId] then
			classType = "Weapon";
			classLib = modWeapons[itemId];
			
		elseif modTools[itemId] then
			classType = "Tool";
			classLib = modTools[itemId];
			
		end
		
	elseif itemLib.Type == modItemsLibrary.Types.Clothing then
		classType = "Clothing";
		classLib = modClothingLibrary:Find(itemId);
		
	end
	
	if classLib then
		if classLib.NewToolLib == nil then
			Debugger:Warn("Missing newtoollib func ", itemId);
		end
		if getShadowCopy == true then
			return update(classLib.NewToolLib()), classType;
			
		else
			if self.ItemClassesCache[storageItemId] == nil then
				self.ItemClassesCache[storageItemId] = classLib.NewToolLib();
			end
			return update(self.ItemClassesCache[storageItemId]), classType;
		end
	end

	return;
end


local toolHandlers = game.ServerScriptService.ServerLibrary.ToolHandlers;
function Profile:GetToolHandler(storageItem, toolLib, toolModels)
	if storageItem == nil then return end;
	--local playerSave = self:GetActiveSave();
	local toolId = storageItem.ID;
	
	if storageItem.MockItem then
		toolId = storageItem.ItemId;
	end
	
	if self.ToolsCache[toolId] then
		if toolLib then
			self.ToolsCache[toolId].Prefabs = toolModels;
		end
		return self.ToolsCache[toolId];
	end;
	
	if toolLib then
		local handler;

		if game.ServerScriptService:FindFirstChild("ModServerLibrary") then
			local toolHandlerModule = game.ServerScriptService.ModServerLibrary:FindFirstChild("ServerToolHandlers")
				and game.ServerScriptService.ModServerLibrary.ServerToolHandlers:FindFirstChild(toolLib.Type);
			
			handler = toolHandlerModule and require(toolHandlerModule) or nil;
			
		elseif game.ServerScriptService:FindFirstChild("BaseServerLibrary") then
			local toolHandlerModule = game.ServerScriptService.BaseServerLibrary:FindFirstChild("ServerToolHandlers")
				and game.ServerScriptService.BaseServerLibrary.ServerToolHandlers:FindFirstChild(toolLib.Type);

			handler = toolHandlerModule and require(toolHandlerModule) or nil;
			
		end
		
		if handler == nil then
			handler = toolHandlers:FindFirstChild(toolLib.Type) and require(toolHandlers[toolLib.Type]) or nil;
		end
		
		if handler then
			self.ToolsCache[toolId] = handler.new(self.Player, storageItem, toolLib, toolModels);
		end
	end
	
	return self.ToolsCache[toolId];
end

function Profile:GetRemoteConfigs()
	if self.RemoteConfigs == nil and self.Player:FindFirstChild("RemoteConfigs") then
		self.RemoteConfigs = require(self.Player.RemoteConfigs);
	end
	
	return self.RemoteConfigs;
end

function Profile:RefreshSettings(update)
	if update then
		table.clear(self.Settings);
		
		for key, value in pairs(update) do
			if modSettings[key] then
				self.Settings[key] = modSettings.Fix(self.Player, key, value);
			else
				Debugger:Log("Unknown setting key:", key);
			end
		end
	end
	
	self:RefreshPlayerTitle();
	self:Sync("Settings");
	
	modSettings.UpdateAutoPickup(self.Cache.PickupCache, self.Settings.AutoPickupConfig or {});
end

function Profile:RefreshPlayerTitle()
	local playerSave = self:GetActiveSave();
	if playerSave == nil then return false; end;
	
	local rootPart = self.Player and self.Player.Character and self.Player.Character.PrimaryPart;
	local nameDisplay = rootPart and rootPart:FindFirstChild("NameDisplay");
	if nameDisplay == nil then return end;
	
	rootPart.NameDisplay.Status.LevelIcon.Visible = self.Settings.HideLevelIcon ~= 1;
	
	rootPart.NameDisplay.Status.tagFrame.NameTag.Text = self.Settings.Nickname or self.Player.DisplayName;
	
	rootPart.NameDisplay.Status.tagFrame.TitleTag.Visible = self.Settings.HidePlayerTitle ~= 1;
	
	rootPart.NameDisplay.Status.LevelIcon.LevelTag.Text = playerSave:GetStat("Level");
	
	local id = self.TitleId;
	
	if id == "" and self.GroupRank and self.GroupRank > 1 then
		local rankId = "rank"..self.GroupRank;
		local titleLib = modPlayerTitlesLibrary:Find(rankId);
		if titleLib then
			id = rankId;
		end
	end
	
	if id == "" then
		nameDisplay.Status.tagFrame.TitleTag.Text = "";
	else
		local titleLabel = nameDisplay.Status.tagFrame.TitleTag;
		local titleLib = modPlayerTitlesLibrary:Find(id);
		
		if titleLib then
			local titleText = titleLib.Title;
			
			if titleLib.TitleStyle then
				if titleLib.TitleStyle.TextColor3 then
					titleLabel.TextColor3 = titleLib.TitleStyle.TextColor3;
				end
				if titleLib.TitleStyle.TextStrokeColor3 then
					titleLabel.TextStrokeColor3 = titleLib.TitleStyle.TextStrokeColor3;
				end
				if titleLib.TitleStyle.TextStrokeTransparency then
					titleLabel.TextStrokeTransparency = titleLib.TitleStyle.TextStrokeTransparency;
				end
			end
			
			if titleLib.BpLevels then
				local passData = self.BattlePassSave:GetPassData(titleLib.Id);
				if passData and passData.Level then
					titleText = titleText.." Level ".. modFormatNumber.Beautify(passData.Level);
				end
			end
			
			titleLabel.Text = titleText;
		else
			self.TitleId = "";
			titleLabel.Text = "";
		end
	end
	
	local titleTag = self.Player:FindFirstChild("PlayerTitleTag");
	if titleTag == nil then
		titleTag = Instance.new("StringValue");
		titleTag.Name = "PlayerTitleTag";
		titleTag.Parent = self.Player;
	end
	titleTag.Value = id;

	return;
end

function Profile:UpdateTrustLevel()
	local trustTable = self.TrustTable;
	
	local level = 0;
	if self.ShadowBan == -1 then
		self.TrustLevel = level; 
		trustTable.ShadowBan = true;
		return 
	end;
	
	local playPoints = 0;
	
	if self.Player.AccountAge > 30*12 then
		level = level +3;
		trustTable.OneYearAcc = true;
	end
	
	if self.Player.MembershipType ~= Enum.MembershipType.None then 
		level = level +5;
		trustTable.HasMembership = true;
	end
	
	local purchaseCount = 0;
	for _,_ in pairs(self.Purchases) do
		purchaseCount = purchaseCount +1;
	end
	if purchaseCount > 0 then 
		level = level + (purchaseCount * 4); 
		playPoints = playPoints+purchaseCount*600;
		
		trustTable.Purchases = purchaseCount;
	end
	if self.Premium then 
		level = level +10; 
		playPoints = playPoints+1200;
		
		trustTable.IsPremium = true;
	end
	
	local _timeSinceFirstJoin = os.time()-self.FirstJoined;
	if os.time()-self.FirstJoined >= 2592000 then 
		level = level +5;
		trustTable.MonthlyPlayer = true;
	end;
	
	local activeSave = self.ActiveGameSave;
	if activeSave then
		local playerLevel = activeSave:GetStat("Level") or 0;
		if playerLevel >= math.ceil(modGlobalVars.MaxLevels/2)+40 then 
			level = level +30;
			trustTable.MeetHalfLevels = true;
		end;
		
		if playerLevel >= math.ceil(modGlobalVars.MaxLevels*0.8) then 
			level = level +10;
			trustTable.MeetTopLevels = true;
		end;
		
		local killCount = activeSave:GetStat("Kills") or 0;
		if killCount >= 50000 then 
			level = level +2;
			if killCount >= 100000 then 
				level = level +3;
				if killCount >= 500000 then 
					level = level +10;
					if killCount >= 1000000 then 
						level = level +10;
					end
				end
			end
			
			trustTable.KillCount = killCount;
		end;
	end
	
	if self.PlayTime >= 180000 then --50 hours
		level = level+5;
	end
	
	if trustTable.IsPremium and trustTable.MeetHalfLevels then
		level = level+5;
		if trustTable.MeetTopLevels then
			level = level+5;
		end
	end	
	
	trustTable.Level = level;
	self.TrustLevel = level; 
	self.TrustTable = trustTable;
	
	if self.Flags:Get("TrustLevelPlayPoints") == nil then
		self.Flags:Add({Id="TrustLevelPlayPoints"});
		self:AddPlayPoints(playPoints);
	end
	return trustTable;
end

function remoteSetPlayerTitle.OnServerInvoke(player, id)
	local profile = Profile:Get(player);
	
	local titlelib = modPlayerTitlesLibrary:Find(id);
	if profile == nil or titlelib == nil then return false; end
	local playerSave = profile:GetActiveSave();
	if playerSave == nil then return false; end;

	if profile.TitleId == id then
		profile.TitleId = "";
		profile:RefreshPlayerTitle();
		
		shared.Notify(player, "Player title cleared!", "Inform");
		return true;
	end
	
	if titlelib.Unlock == "Achievement" and playerSave.Achievements[id] == nil then
		return false;
	elseif titlelib.Unlock == "Rank" and profile.Rank ~= titlelib.UnlockValue then
		return false;
	end
	
	profile.TitleId = id;
	shared.Notify(player, ("Player title set to $title!"):gsub("$title", titlelib.Title), "Inform");
	profile:RefreshPlayerTitle();
	return profile.TitleId;
end

function remoteRequestPublicProfile.OnServerInvoke(player, targetName)
	local profile = Profile.Profiles[targetName];
	if profile then
		return profile:SyncPublic(player);
	end
	return;
end

task.spawn(function()
	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("togglehardmode", {
		Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
		Description = [[Hardmode commands.
		/togglehardmode tag value
		]];

		RequiredArgs = 0;
		UsageInfo = "/togglehardmode tag value";
		Function = function(player, args)
			local profile = shared.modProfile:Get(player);
			
			local tag = args[1];
			local val = args[2];
			
			if tag == "all" then
				val = val == true;
				
				if val == true then
					profile.HardMode = profile.HardModeBitFlag.Size;
					
				else
					profile.HardMode = 0;
					
				end
				
			elseif val == nil then
				shared.Notify(player, "Hardmode ("..tag.."): "..tostring(profile:GetHardMode(tag)) , "Inform");
				
			else
				profile:SetHardMode(tag, val);
				
			end

			shared.Notify(player, "Hardmode: ".. tostring(profile.HardMode) , "Inform");

			return true;
		end;
	});
end)



shared.modProfile = Profile;
return Profile;