local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local EconomyAnalytics = {};
EconomyAnalytics.__index = EconomyAnalytics;

local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modSerializer = require(game.ReplicatedStorage.Library.Serializer);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);

local econAnalyticsDatabase = modDatabaseService:GetDatabase("EconomyAnalytics");
local econPoolSerializer = modSerializer.new();

--==

local EconPoolData = {};
EconPoolData.__index = EconPoolData;
EconPoolData.ClassType = "EconPoolData";

function EconPoolData.new()
	local meta = {};
	meta.__index = meta;

	local self = {
		ItemKey = "";
		
		TotalSource = 0;
		TotalSink = 0;
		TotalCount = 0;
		
		DailyStats = {
			Source = 0;
			Sink = 0;
			Count = 0;
			ResetTime = 0;
		};
		
		Logs = {};
	};

	setmetatable(self, meta);
	setmetatable(meta, EconPoolData);
	return self;
end

econPoolSerializer:AddClass(EconPoolData.ClassType, EconPoolData.new);
econAnalyticsDatabase:BindSerializer(econPoolSerializer);


econAnalyticsDatabase:OnUpdateRequest("submit", function(requestPacket)
	local inputValues = requestPacket.Values;
	
	local itemKey = inputValues.ItemKey;
	local amount = inputValues.Amount;
	local submitTime = inputValues.UnixTime;

	local poolData = requestPacket.Data or EconPoolData.new();
	poolData.ItemKey = itemKey;
	
	if poolData.DailyStats.ResetTime == 0 or submitTime >= poolData.DailyStats.ResetTime then
		while #poolData.Logs > 30 do
			table.remove(poolData.Logs, 1);
		end
		table.insert(poolData.Logs, {
			DayUnixTime = poolData.DailyStats.ResetTime;
			Source = poolData.DailyStats.Source;
			Sink = poolData.DailyStats.Sink;
			Count = poolData.DailyStats.Count;
		})

		poolData.DailyStats.ResetTime = submitTime + modSyncTime.TimeOfEndOfDay();
		poolData.DailyStats.Source = 0;
		poolData.DailyStats.Sink = 0;
		poolData.DailyStats.Count = 0;
	end
	
	
	if amount > 0 then
		poolData.TotalSource = poolData.TotalSource + amount;
		poolData.DailyStats.Source = poolData.DailyStats.Source + amount;
		
	elseif amount < 0 then
		poolData.TotalSink = poolData.TotalSink + math.abs(amount);
		poolData.DailyStats.Sink = poolData.DailyStats.Sink + math.abs(amount);
		
	end
	
	poolData.TotalCount = poolData.TotalCount + amount;
	poolData.DailyStats.Count = poolData.DailyStats.Count + amount;
	
	return poolData;
end);


--== Local analytics
local EconPoolCache = {};

local cacheFlushPeriod = 60;
local forceFlushPeroid = 300;
function EconomyAnalytics.Record(itemKey, amount)
	if amount == 0 then return end;
	
	local unixTime = modSyncTime.GetTime();
	
	if EconPoolCache[itemKey] == nil then
		EconPoolCache[itemKey] = EconPoolData.new();
		EconPoolCache[itemKey].LastFlush = unixTime;
	end
	
	local poolData = EconPoolCache[itemKey];

	poolData.ItemKey = itemKey;
	poolData.RecordTime = unixTime;
	
	if amount > 0 then
		poolData.TotalSource = poolData.TotalSource +amount;
		
	elseif amount < 0 then
		poolData.TotalSink = poolData.TotalSink +math.abs(amount);
		
	end
	
	task.delay(cacheFlushPeriod, function()
		local poolData = EconPoolCache[itemKey];
		if poolData == nil then return end
		
		
		local flush = true;
		local currTime = modSyncTime.GetTime();
		
		if (currTime-poolData.RecordTime) <= cacheFlushPeriod-1 then
			flush = false;
		end
		
		if (currTime-poolData.LastFlush) >= forceFlushPeroid then
			Debugger:Warn("Force flush anyways", itemKey);
			flush = true;
		end

		local amtChange = (poolData.TotalSource - poolData.TotalSink);
		if amtChange == 0 then
			flush = false;
		end
		
		if flush ~= true then return end;
		
		
		if modBranchConfigs.CurrentBranch.Name == "Dev" then
			Debugger:Warn("Submitting item analytics: ", itemKey, "=",amtChange);
		end
		
		local oldFlushTime = poolData.LastFlush;
		poolData.LastFlush = currTime;

		local submitRp = econAnalyticsDatabase:UpdateRequest(itemKey, "submit", {
			ItemKey = itemKey;
			Amount = amtChange;
			UnixTime = currTime;
		});
		
		if submitRp.Success then
			poolData.TotalSource = 0;
			poolData.TotalSink = 0;

			-- delete if no changes since flush;
			if poolData.RecordTime == unixTime then
				EconPoolCache[itemKey] = nil;
			end
			
		else
			Debugger:Warn("Failed to submit: ", submitRp.FailMsg);
			EconomyAnalytics.Record(itemKey, 0);
			
		end
		
	end)
end


task.spawn(function()
	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);
	Debugger.AwaitShared("modCommandsLibrary");

	shared.modCommandsLibrary:HookChatCommand("economy", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
		Description = [[Server economy commands:
		/economy view itemKey
		/economy record itemKey amount
		]];

		RequiredArgs = 0;
		Function = function(speaker, args)
			local action = args[1];
			
			if action == "view" then
				local itemKey = args[2];
				
				local poolData = econAnalyticsDatabase:Get(itemKey);
				Debugger:Warn("poolData", poolData);
				if poolData == nil then
					shared.Notify(speaker, "No records for key: "..itemKey, "Negative");
					return;
				end
				
				local rStr = "";
				
				rStr = rStr.."Analytics (<b>".. poolData.ItemKey .."</b>)";
				rStr = rStr.."\n    Total Source: ".. modFormatNumber.Beautify(poolData.TotalSource);
				rStr = rStr.."\n    Total Sink: ".. modFormatNumber.Beautify(poolData.TotalSink);
				rStr = rStr.."\n    Total Count: ".. modFormatNumber.Beautify(poolData.TotalCount);
				
				local function formatLog(days)
					local source, sink, total = 0, 0, 0;
					local d = 0;
					for a=#poolData.Logs, 1, -1 do
						local logInfo = poolData.Logs[a];
						
						source = source + logInfo.Source;
						sink = sink + logInfo.Sink;
						total = total + logInfo.Count;
						
						d = d +1;
						if d >= days then
							break;
						end
					end
					
					return "( ".. modFormatNumber.Beautify(source) .." / ".. modFormatNumber.Beautify(sink) .." / ".. modFormatNumber.Beautify(total) .." )"
				end
				
				rStr = rStr.."\n\n    Daily: ".. formatLog(1);
				rStr = rStr.."\n    Weekly: ".. formatLog(7);
				rStr = rStr.."\n    Monthly: ".. formatLog(30);
				
				Debugger:Warn("PoolData ",itemKey, ":", poolData);
				shared.Notify(speaker, rStr, "Inform");
				
			elseif action == "record" then
				local itemKey = args[2];
				local amount = args[3];
				
				local submitRp = econAnalyticsDatabase:UpdateRequest(itemKey, "submit", {
					ItemKey = itemKey;
					Amount = amount;
					UnixTime = modSyncTime.GetTime();
				});
				
				if submitRp.Success then
					Debugger:Warn("PoolData ",itemKey, ":", submitRp);
					shared.Notify(speaker, "Recorded (".. itemKey ..") "..amount, "Inform");
					
				else
					shared.Notify(speaker, "Failed to record: "..itemKey..": "..submitRp, "Inform");
					
				end
				
			else
				shared.Notify(speaker, "Unknown action for /economy", "Negative");
				
			end
			
			return;
		end;
	});
	
end)

return EconomyAnalytics;
