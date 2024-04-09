local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local DataStoreService = game:GetService("DataStoreService");
local MemoryStoreService = game:GetService("MemoryStoreService");
local HttpService = game:GetService("HttpService");
local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modSerializer = require(game.ReplicatedStorage.Library.Serializer);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGameLogService = require(game.ReplicatedStorage.Library.GameLogService);
local modTableManager = require(game.ReplicatedStorage.Library.TableManager);

local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

local CacheFlushQueue: MemoryStoreQueue = MemoryStoreService:GetQueue("Cache", 60);
local lastProcessCacheTick = tick();
local cacheMemPool = (1024*32);

local LocalCacheQueue = {};

--== Variables;

local DatabaseService = {};
DatabaseService.__index = DatabaseService;
DatabaseService.Active = {};

local oneHourSecs = 3600;
local oneDaySecs = 86400;
local oneMonthSecs = 86400*30;

local devBranchPrefix = modBranchConfigs.CurrentBranch.Name == "Dev" and "dev_" or "";
--== Script;


local function TryFunction(id: string, func)
	local s, e;
	
	local tryCount = 6;
	if RunService:IsStudio() then
		tryCount = 3;
	end
	
	for a=1, tryCount do
		s, e = pcall(func);
		if s == true then
			break;
		end
		Debugger:Warn("Try ",a.."/"..tryCount," (",id,") failed:",e);
		task.wait((a-1)^2);
	end

	return s, e;
end


function DatabaseService:SetUserId(key, list) -- assigns a cache to a data, such as UserIds;
	self.UserIds[key] = list;
end


function DatabaseService:GetCache(key)
	local cacheList;
	
	local loadS, loadE = TryFunction("GetCache", function()
		cacheList = self.CachePool:GetAsync(key);
		cacheList = cacheList or {};
	end)
	
	if not loadS then
		Debugger:Warn(":GetCache (",key,") failed:", loadE, debug.traceback());
		return {}, 0;
	end;
	
	
	local cacheSize = 0;
	
	if typeof(cacheList) == "table" then
		cacheSize = #HttpService:JSONEncode(cacheList);
	end

	return cacheList, cacheSize;
end


function DatabaseService:AddCache(key, funcId, values)
	local cacheId, cachePacket;
		
	local addS, addE = TryFunction("AddCache", function()
		self.CachePool:UpdateAsync(key, function(cacheList)
			cacheList = cacheList or {};
			cacheId = DateTime.now().UnixTimestampMillis;
			
			local latestCacheId = cacheId;

			for a=1, #cacheList do
				if cacheList[a].I > latestCacheId then
					latestCacheId = cacheList[a].I;
				end
			end
			latestCacheId = latestCacheId+1;

			cachePacket = {
				I=cacheId;
				F=funcId;
				V=values;
			};
			table.insert(cacheList, cachePacket)

			return cacheList;
		end, oneDaySecs)
	end)
	
	if not addS then
		Debugger:Warn(":AddCache",(cachePacket and cachePacket.F or "newCache nil line:122"),"(",self.Scope,"/",key,") Error Message:", addE);
		return nil;
		
	end
	
	if cachePacket then
		Debugger:Log(":AddCache ",(cachePacket and cachePacket.F or "newCache nil line:130")," (", self.Scope,"/",key ,") successful.");
		return cachePacket;
	end
end


function DatabaseService:ClearCache(key) -- empties entire cache, for when deleting value from db;
	local flushS, flushE = TryFunction("ClearCache", function()
		self.CachePool:UpdateAsync(key, function(cacheList)
			return {};
		end, oneDaySecs);
	end)
	
	if not flushS then
		Debugger:Warn(":ClearCache (",key,") failed", flushE);
		return;
	end;
end


function DatabaseService:Publish(key, updateFunc)
	local unixTime = DateTime.now().UnixTimestampMillis;
	local rawData, dsKeyInfo;
	
	local isDataLocked = false;
	local loopCount = 1;
	repeat
		isDataLocked = false;
		
		local lockS, lockE = pcall(function()
			self.DataLocks:UpdateAsync(key, function(v)
				if v == true then
					isDataLocked = true;
				else
					return true;
				end
				return nil;
			end, 10);
		end)
		if not lockS then
			isDataLocked = true;
			Debugger:Warn("DataLock (",key,") Error:", lockE);
		end
		
		if isDataLocked == true then
			Debugger:Warn("Publish (",key,") isDataLocked", isDataLocked);
			task.wait(10*loopCount);
			loopCount = loopCount+1;
		end
	until isDataLocked == false;
	
	local cacheList = self:GetCache(key);
	if #cacheList > 0 or updateFunc then
		local pulledCache = {};
		
		if #cacheList > 0 then
			local pullCacheS, pullCacheE = TryFunction("PublishPullCache", function()
				self.CachePool:UpdateAsync(key, function(cacheList)
					cacheList = cacheList or {};

					pulledCache = cacheList;

					return {};
				end, oneDaySecs);
			end)
			if not pullCacheS then
				Debugger:Warn(":PullCache (",key,") failed: ", pullCacheE);
			end;
			
		end
		
		if #pulledCache > 0 or updateFunc then
			
			local saveS, saveE = TryFunction("PublishStore", function()
				rawData, dsKeyInfo = self.DataStore:UpdateAsync(key, function(rawData, dsKeyInfo)
					local reqId = math.random(100000, 999999);
					for a=1, #pulledCache do
						local cacheFuncId = pulledCache[a].F;
						local set;

						if self.RequestCallbacks[cacheFuncId] then
							local callbackFunc = self.RequestCallbacks[cacheFuncId];

							local requestPacket = {};
							requestPacket.ReqId = reqId;
							requestPacket.Key = key;
							requestPacket.RawData = rawData;
							requestPacket.Values = pulledCache[a].V;
							requestPacket.Publish = true;

							local callbackFinished = false;
							local funcS, funcE = pcall(function()
								task.delay(1, function()
									if not callbackFinished then
										Debugger:Warn(":Cache (",cacheFuncId,") exhausted: ", pulledCache[a]);
									end
								end)
								set = callbackFunc(requestPacket);
								callbackFinished = true;

							end) if not funcS then Debugger:Warn(":Cache (",cacheFuncId,") failed:", funcE, pulledCache[a]); end;

							if requestPacket.FailMsg ~= nil then
								requestPacket.Success = false;
							else
								requestPacket.Success = funcS;
							end
						end

						if set ~= nil then
							rawData = set;
						else
							rawData = rawData;
						end
					end

					if updateFunc then
						rawData = updateFunc(rawData, dsKeyInfo);
					end

					if rawData == nil then Debugger:Log(":Read (",self.Scope,"/",key,")") return nil end;
					return rawData, self.UserIds[key];
				end)
			end)
			
			if not saveS then 
				Debugger:Warn(":Published Failed (",self.Scope,"/",key,") TrySave 3 times, aborting..");
				return nil;
			end;
			
			if saveS and rawData then
				Debugger:Log(":Published (",self.Scope,"/",key,") Size:", #tostring(rawData) or "nil", "  Pulled Cache:", #pulledCache);
				
				TryFunction("UpdatePublishTime", function()
					self.CachePool:SetAsync(key.."lastpublish", DateTime.now().UnixTimestampMillis, oneDaySecs);
				end)
				
			else
				if #pulledCache > 0 then
					Debugger:Log(":Flushed (",self.Scope,"/",key,") Pulled Cache:", #pulledCache);
				end
				
			end
		end
	end

	--if self.Serializer then
	--	return self.Serializer:Deserialize(rawData), dsKeyInfo;
	--end;
	--return rawData, dsKeyInfo;
end

function DatabaseService:AddLocalCacheQueue(newScope, newKey)
	local newScopeKey = newScope.."_"..newKey;
	local currTimeMs = DateTime.now().UnixTimestampMillis;
	
	local exist = false;
	
	for _, packet in pairs(LocalCacheQueue) do
		local scopeKey = packet.Scope.."_"..packet.Key;
		
		if newScopeKey == scopeKey then
			packet.AddTickMs = currTimeMs;
			exist = true;
			break;
		end
	end
	
	if not exist then
		LocalCacheQueue[newScopeKey] = {
			Scope = newScope;
			Key = newKey;
			AddTickMs = currTimeMs;
		}
	end
end

function DatabaseService:ProcessLocalCacheQueue()
	local processedScopeKeys = {};

	if typeof(LocalCacheQueue) == "table" then
		local currTimeMs = DateTime.now().UnixTimestampMillis;

		for scopeKey, packet in pairs(LocalCacheQueue) do
			local scope = packet.Scope;
			local key = packet.Key;
			local addTimeMs = packet.AddTickMs;

			if addTimeMs and currTimeMs-addTimeMs >= 30*1000 then
				Debugger:Log(":LocalCacheQueue Publish:", scope,"/",key);

				local database = DatabaseService:GetDatabase(scope);
				database:Publish(key);
				
				LocalCacheQueue[scopeKey] = nil;
			end
		end
	end
end

function DatabaseService:AddCacheQueue(newScope, newKey)
	if newScope == nil or newKey == nil then
		return
	end;

	local flushPacket = {
		Scope = newScope;
		Key = newKey;
		AddTickMs = DateTime.now().UnixTimestampMillis;
	};

	TryFunction("AddFlushQueue", function()
		CacheFlushQueue:AddAsync(flushPacket, 300);
		Debugger:Log(":ProcessCacheQueue AddFlushQueue:", flushPacket);
	end)
end

function DatabaseService:ProcessCacheQueue(newScope, newKey)
	local queueData, queueKey;

	TryFunction("ProcessCacheQueue", function()
		queueData, queueKey = CacheFlushQueue:ReadAsync(100, false, 0);
		Debugger:Log(":ProcessCacheQueue ReadQueue:",queueData and #queueData or 0, queueKey);
	end)

	if queueKey then
		TryFunction("ClearCacheQueue", function()
			CacheFlushQueue:RemoveAsync(queueKey);
		end)
	end
	
	local processedScopeKeys = {};
	
	if typeof(queueData) == "table" then
		local currTimeMs = DateTime.now().UnixTimestampMillis;
		
		for a=1, #queueData do
			local packet = queueData[a];
			local addTimeMs = packet.AddTickMs;
			
			local scopeKey = packet.Scope.."_"..packet.Key;
			local oldPacket = processedScopeKeys[scopeKey];
			
			if oldPacket == nil or addTimeMs > oldPacket.AddTickMs then
				if addTimeMs and currTimeMs-addTimeMs >= 30*1000 then
					-- publish
					packet.Index = 1;
				else
					-- Re-add to queue;
					packet.Index = 2;
				end

				processedScopeKeys[scopeKey] = packet;
			end
		end
		
		for _, packet in pairs(processedScopeKeys) do
			local scope = packet.Scope;
			local key = packet.Key;

			if packet.Index == 1 then
				Debugger:Log(":ProcessCacheQueue Publish:", scope,"/",key);
				
				local database = DatabaseService:GetDatabase(scope);
				database:Publish(key);
				
				
			elseif packet.Index == 2 then
				Debugger:Log(":ProcessCacheQueue Queue:", scope,"/",key);
				
				packet.Index = nil;
				if packet.AddTickMs == nil then
					packet.AddTickMs = currTimeMs;
				end
				
				TryFunction("ReAddFlushQueue", function()
					CacheFlushQueue:AddAsync(packet, 300);
				end)
				
			end
		end
	end
end


function DatabaseService:UpdateRequest(key, callbackId, values)
	callbackId = devBranchPrefix.. callbackId;

	if self.RequestCallbacks[callbackId] == nil then
		Debugger:Log("Missing RequestCallbacks", callbackId, debug.traceback());
		return;
	end
	
	
	local cacheList, cacheSize = self:GetCache(key);
	
	
	local requestPacket = {};
	requestPacket.Key = key;
	
	local newCache;
	if cacheSize >= cacheMemPool or #cacheList > 32 then
		Debugger:Warn("UpdateRequest() Publishing: (",self.Scope,"/",key,") ", callbackId, (cacheSize >= cacheMemPool) and "MemPool Full" or "CacheCount Full");
		
		self:Publish(key, function(rawData, dsKeyInfo)
			if self.RequestCallbacks[callbackId] == nil then return; end;
			
			requestPacket.RawData = rawData;
			requestPacket.Values = values;
			
			return self.RequestCallbacks[callbackId](requestPacket);
		end)
		
	else
		Debugger:Log("UpdateRequest() AddCache: (",self.Scope,"/",key,") ", callbackId);
		newCache = self:AddCache(key, callbackId, values);
		
	end
	task.spawn(function()
		DatabaseService:AddLocalCacheQueue(self.Scope, key);
	end)
	
	requestPacket.CacheId = newCache and newCache.I or nil;
	
	local r = self:Get(key, requestPacket);
	requestPacket.Data = r;
	
	
	Debugger:Log("UpdateRequest() newCache ", newCache, " ProxyRequestPacket:", {
		Success=requestPacket.Success;
		FailMsg=requestPacket.FailMsg;
		CacheId=requestPacket.CacheId;
		Data=tostring(requestPacket.Data);
		RawData=tostring(requestPacket.RawData);
		Values=tostring(requestPacket.Values);
	});
	
	
	for key, cache in pairs(self.LocalCache) do
		if tick()-(cache.Tick or 0) >= 300 then
			self.UserIds[key] = nil;
		end
	end
	
	return requestPacket;
end


function DatabaseService:Get(key, requestPacket)
	local rawData, dsKeyInfo;
	
	local loadS, loadE = TryFunction("LoadDatastore", function()
		rawData, dsKeyInfo = self.DataStore:GetAsync(key);
	end)
	if not loadS then
		Debugger:Warn(":Get failed (",self.Scope,"/",key,")", loadE);
		return
	end
	
	
	if typeof(rawData) == "table" then
		rawData = modTableManager.CloneTable(rawData);
	end
	
	local cacheList = self:GetCache(key);
	if #cacheList > 0 then
		local reqId = math.random(100000, 999999);
		
		for a=1, #cacheList do
			local cacheFuncId = cacheList[a].F;
			local set;
			
			if self.RequestCallbacks[cacheFuncId] then
				local callbackFunc = self.RequestCallbacks[cacheFuncId];
				
				local proxyRequestPacket = {};
				proxyRequestPacket.Key = key;
				if requestPacket and requestPacket.CacheId == cacheList[a].I then
					proxyRequestPacket = requestPacket;
				end
				
				proxyRequestPacket.ReqId = reqId;
				proxyRequestPacket.RawData = rawData;
				proxyRequestPacket.Values = cacheList[a].V;

				local funcS, funcE = pcall(function()
					set = callbackFunc(proxyRequestPacket);
				end)
				if not funcS then
					Debugger:Warn(":Cache proxy (",cacheFuncId,") failed:", funcE, cacheList[a]);
				end;

				if proxyRequestPacket.FailMsg ~= nil then
					proxyRequestPacket.Success = false;
				else
					proxyRequestPacket.Success = funcS;
				end
				
			end
			
			if set ~= nil then
				rawData = set;
				
			else
				rawData = rawData;
				
			end
		end
	else
		if requestPacket then
			requestPacket.Success = true;
		end
	end
	
	Debugger:Log(":Get (",self.Scope,"/",key,") RawData:", RunService:IsStudio() and {rawData} or tostring(rawData));

	if self.Serializer then
		return self.Serializer:Deserialize(rawData), dsKeyInfo;
	end;

	return rawData, dsKeyInfo;
end


function DatabaseService:Remove(key)
	self:ClearCache(key);
	self.DataStore:RemoveAsync(key);
end


function DatabaseService:BindSerializer(serializer)
	self.Serializer = serializer;
end

function DatabaseService:OnUpdateRequest(callbackId, func)
	callbackId = devBranchPrefix.. callbackId;
	
	self.RequestCallbacks[callbackId] = function(requestPacket)
		if self.Serializer == nil then return func(requestPacket); end;
		
		local object = self.Serializer:Deserialize(requestPacket.RawData);
		requestPacket.Data = object;
		
		object = func(requestPacket);
		
		if requestPacket.FailMsg then
			Debugger:Log(callbackId, "IsPublish:",requestPacket.Publish == true,"FailMsg", requestPacket.FailMsg);
		end
		
		if object then
			return self.Serializer:Serialize(object);
		end
		
		return nil;
	end;
end


function DatabaseService.new(scope)
	local self = {
		Scope=scope;
		DataStore = DataStoreService:GetDataStore(scope);
		CachePool = MemoryStoreService:GetSortedMap(scope.."Cache");
		DataLocks = MemoryStoreService:GetSortedMap(scope.."Locks");
		
		RequestCallbacks = {};
		
		LocalCache = {};
		UserIds = {};
		
		
	};
	
	setmetatable(self, DatabaseService);
	
	self:OnUpdateRequest("default", function(requestPacket)
		Debugger:Log("Using (default) callback. RequestPacket:", requestPacket);
		local rawData = requestPacket.RawData;
		local dataObject = requestPacket.Data;
		local inputValues = requestPacket.Values;

		return inputValues;
	end)
	
	return self;
end


function DatabaseService:GetDatabase(scope)
	if self.Active[scope] then return self.Active[scope]; end
	
	self.Active[scope] = DatabaseService.new(scope);
	return self.Active[scope];
end

task.spawn(function()
	local minuteTick = tick();
	while true do
		task.wait(20);
		DatabaseService:ProcessLocalCacheQueue();
		
		if tick()-minuteTick >= 60 then
			minuteTick = tick();

			DatabaseService:ProcessCacheQueue();
		end
	end
end)

game:BindToClose(function()
	for _, packet in pairs(LocalCacheQueue) do
		DatabaseService:AddCacheQueue(packet.Scope, packet.Key);
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	for dbId, database in pairs(DatabaseService.Active) do
		for key,_ in pairs(database.UserIds) do
			if tostring(player.UserId) == key then
				DatabaseService.Active[dbId]:Publish(key);
			end
		end
	end
end)


task.spawn(function()
	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);
	
	Debugger.AwaitShared("modCommandsLibrary");
	
	local demoDatabase = DatabaseService:GetDatabase("DevDemo");
	local demoSerializer = modSerializer.new();
	
	local DemoClass = {};
	DemoClass.__index = DemoClass;
	DemoClass.ClassType = "Demo";
	
	function DemoClass.new()
		local self = {
			A=0;
			B=0;
		}
		
		setmetatable(self, DemoClass);
		return self;
	end

	demoDatabase:OnUpdateRequest("adddemo", function(requestPacket)
		local demo = requestPacket.Data or DemoClass.new();
		local letter = requestPacket.Values or "A";
		
		demo[letter] = demo[letter] +1;
		
		return demo;
	end)
	
	demoSerializer:AddClass(DemoClass.ClassType, DemoClass.new);
	demoDatabase:BindSerializer(demoSerializer);
	local demoKey = "demo";
	
	shared.modCommandsLibrary:HookChatCommand("db", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
		Description = [[
			Database information.
			/db cache [scope] [key]
			/db activecache
			/db flush
			
			/db demoadd [A/B]
		]];

		RequiredArgs = 0;
		Function = function(speaker, args)
			local player = speaker;
			local action = args[1];
			local key = args[2];
			local value = args[3];

			if action == "cache" then
				if key == nil or value == nil then
					shared.Notify(player, "Need scope and key", "Negative");
					return;
				end
				local db = DatabaseService:GetDatabase(key);
				local cacheData = db:GetCache(value);
				
				Debugger:Log("Database Cache(",key,"):", cacheData, "\nCount:", #cacheData);
				shared.Notify(player, Debugger:Stringify("Database Cache(",key,"):", cacheData, "\nCount:", #cacheData), "Inform");
				
			elseif action == "flush" then
				Debugger:Warn("Flushing old >60s cache");
				DatabaseService:ProcessCacheQueue();

			elseif action == "demoadd" then
				local rPacket = demoDatabase:UpdateRequest(demoKey, "adddemo", value);
				--Debugger:Warn("rPacket", rPacket);
				shared.Notify(player, Debugger:Stringify("rPacket", rPacket), "Inform");

			elseif action == "demopublish" then
				demoDatabase:Publish(demoKey);
				shared.Notify(player, "Publishing demo", "Inform");
				
			else
				shared.Notify(player, "Database Cache Size: "..(#HttpService:JSONEncode(DatabaseService:GetCache())), "Inform");
			end

			return;
		end;
	});
end)

return DatabaseService;