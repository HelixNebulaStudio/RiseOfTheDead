local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");
local MemoryStoreService = game:GetService("MemoryStoreService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSerializer = require(game.ReplicatedStorage.Library.Serializer);

local devBranchPrefix = modBranchConfigs.CurrentBranch.Name == "Dev" and "dev_" or "";
--== Script;
local TimeSpan = {
	FiveMin = 300;
	HourSecs = 3600;
	DaySecs = 86400;
	MonthSecs = 86400*30;
}

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

--
local MemoryMap = {};
MemoryMap.Active = {};
MemoryMap.__index = MemoryMap;

function MemoryMap.new(scopeKey)
	--scopeKey = devBranchPrefix..scopeKey;
	
	local self = {
		ScopeKey=scopeKey;
		SortedMap=MemoryStoreService:GetSortedMap(scopeKey);
		Serializer=nil;
		
		TimeSpan=TimeSpan.FiveMin;
	};
	
	setmetatable(self, MemoryMap);
	return self;
end

function MemoryMap:Get(key)
	local raw;
	
	local loadS, loadE = TryFunction("MapGet", function()
		raw = self.SortedMap:GetAsync(key);
	end)
	if not loadS then
		Debugger:Warn(":MapGet failed (",self.ScopeKey,"/",key,")", loadE);
		return
	end
	
	local data = raw;
	
	if self.Serializer then
		data = self.Serializer:Deserialize(raw);
	end
	
	return data;
end

function MemoryMap:Set(key, object)
	local raw = object;
	if self.Serializer and typeof(object) == "table" then
		raw = self.Serializer:Serialize(object);
	end
	local setS, setE = TryFunction("MapSet", function()
		self.SortedMap:SetAsync(key, raw, self.TimeSpan);
	end)
	if not setS then
		Debugger:Warn(":MapSet failed (",self.ScopeKey,"/",key,")", setE);
		return
	end
end

function MemoryMap:Remove(key)
	local removeS, removeE = TryFunction("MapRemove", function()
		self.SortedMap:Remove(key);
	end)
	if not removeS then
		Debugger:Warn(":MapRemove failed (",self.ScopeKey,"/",key,")", removeE);
		return
	end
end

function MemoryMap:GetRange(direction, count, lowerBound, upperBoard)
	local results = {};
	
	local loadS, loadE = TryFunction("GetRangeAsc", function()
		results = self.SortedMap:GetRangeAsync(direction, count, lowerBound, upperBoard);
	end)
	
	for a=1, #results do
		local key = results[a].key;
		
		results[a].Key = key;
		results[a].key = nil;

		local raw = results[a].value;
		local data = raw;

		if self.Serializer then
			data = self.Serializer:Deserialize(raw);
		end
		
		results[a].Value = data;
		results[a].value = nil;
	end
	
	return results;
end

function MemoryMap:Update(key, func)
	local updateS, updateE = TryFunction("MapUpdate", function()
		self.SortedMap:UpdateAsync(key, function(oldRaw)
			local data = oldRaw;
			if self.Serializer then
				data = self.Serializer:Deserialize(oldRaw);
			end
			
			local rObject = func(data, oldRaw);
			if rObject == nil then return nil end;
			
			local rRaw = rObject;
			if self.Serializer and typeof(rObject) == "table" then
				rRaw = self.Serializer:Serialize(rObject);
			end
			
			return rRaw;
		end, self.TimeSpan);
	end)
	if not updateS then
		Debugger:Warn(":MapUpdate failed",self.ScopeKey,"/",key,")", updateE);
	end
end

function MemoryMap:GetMap(scope)
	if self.Active[scope] then return self.Active[scope]; end

	self.Active[scope] = MemoryMap.new(scope);
	return self.Active[scope];
end

function MemoryMap:BindSerializer(serializer)
	self.Serializer = serializer;
end


task.spawn(function()
	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

	Debugger.AwaitShared("modCommandsLibrary");

	local demoMap = MemoryMap:GetMap("DevDemo");
	local demoSerializer = modSerializer.new();

	local DemoClass = {};
	DemoClass.__index = DemoClass;
	DemoClass.ClassType = "Demo";

	function DemoClass.new()
		local self = {
			A=0;
			B="Hello";
		}

		setmetatable(self, DemoClass);
		return self;
	end

	demoSerializer:AddClass(DemoClass.ClassType, DemoClass.new);
	demoMap:BindSerializer(demoSerializer);

	shared.modCommandsLibrary:HookChatCommand("memmap", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
		Description = [[
			Memory map information. scope Key DevDemo for demo data;
			/memmap get scope key
			/memmap set scope key value
			/memmap demoget key
			/memmap demoset key value
		]];

		RequiredArgs = 0;
		Function = function(speaker, args)
			local player = speaker;
			local action = args[1];

			if action == "get" then
				local scopeKey = args[2];
				local key = args[3];
				
				if scopeKey == nil or key == nil then
					shared.Notify(player, "Need scope and key", "Negative");
					return;
				end
				
				local map = MemoryMap:GetMap(scopeKey);
				
				local data = map:Get(key);

				Debugger:Log("Memory map(",scopeKey,"/",key,"):", data);
				shared.Notify(player, Debugger:Stringify("Database Cache(",scopeKey,"/",key,"):", data), "Inform");
				
			elseif action == "set" then
				local scopeKey = args[2];
				local key = args[3];
				local data = args[4];
				
			elseif action == "demoget" then
				local key = args[2];

				local data = demoMap:Get(key);

				Debugger:Log("Memory map(DevDemo/",key,"):", data);
				shared.Notify(player, Debugger:Stringify("Database Cache(DevDemo/",key,"):", data), "Inform");
				
			elseif action == "demoset" then
				local key = args[2];
				local data = args[3];
				
				demoMap:Update(key, function(demoClassObj)
					if demoClassObj == nil then
						demoClassObj = DemoClass.new();
					end
					demoClassObj.Set = data;
					return demoClassObj;
				end)
			end

			return;
		end;
	});
end)


return MemoryMap;
