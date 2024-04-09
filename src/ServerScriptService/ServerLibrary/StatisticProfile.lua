local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local StatisticProfile = {Profiles=nil;};
StatisticProfile.__index = StatisticProfile;
--==
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local DataStoreService = game:GetService("DataStoreService");

local statisticsDatabase = DataStoreService:GetDataStore("StatsArchive2");
--== Script;
function StatisticProfile.new(player)
	local meta = {
		Player = player;
		LastGet = 0;
		Cache = {};
	};
	meta.__index=meta;
	
	local self = {
		KillTracker = {};
	};
	
	setmetatable(self, meta);
	setmetatable(meta, StatisticProfile);
	return self;
end

function StatisticProfile:SetStat(t, k, v)
	if t == nil or k == nil then return end;
	v = v or 1;
	
	if self[t] == nil then self[t] = {}; end;
	self[t][k] = v;
end

function StatisticProfile:AddStat(t, k, v)
	if t == nil or k == nil then return end;
	v = v or 1;
	
	if self[t] == nil then self[t] = {}; end;
	self[t][k] = (self[t][k] or 0) + v;
end

function StatisticProfile:Save()
	spawn(function()
		local key = tostring(self.Player.UserId);
		
		pcall(function()
			statisticsDatabase:UpdateAsync(key, function(oldValue)
				local rawTable = {};
				local s, e = pcall(function()
					rawTable = oldValue and HttpService:JSONDecode(oldValue) or {};
				end)
				if not s then Debugger:Warn(e) end;
				
				for t, _ in pairs(self) do
					if rawTable[t] == nil then rawTable[t] = {}; end;
					if type(self[t]) == "table" then
						if type(rawTable[t]) ~= "table" then rawTable[t] = {} end;
						
						for k, v in pairs(self[t]) do
							if type(v) == "number" then
								if type(rawTable[t][k]) ~= "number" then
									rawTable[t][k] = 0;
								end
								rawTable[t][k] = (rawTable[t][k] or 0) + v;
							end
						end
						
						self[t] = {};
					end
				end
				
				local encode = HttpService:JSONEncode(rawTable);
				return encode;
			end)
		end)
	end)
end

function StatisticProfile:Get()
	if tick()-self.LastGet <= 300 then return self.Cache; end;
	self.LastGet = tick();
	
	spawn(function() 
		local key = tostring(self.Player.UserId);
		pcall(function()
			local encoded = statisticsDatabase:GetAsync(key);
			self.Cache = encoded and HttpService:JSONDecode(encoded) or {};
		end);
		
		local function limitTableSize(dict, lim)
			if dict == nil then return end;
			local sort = {};
			for k, v in pairs(dict) do
				table.insert(sort, {Key=k; Value=v});
			end
			table.sort(sort, function(a, b) return a.Value > b.Value end);
			
			for _, pack in pairs(sort) do
				lim = lim -1;
				if lim > 0 then
					dict[pack.Key] = pack.Value;
					
				else
					dict[pack.Key] = nil;
					
				end;
			end
		end
		
		limitTableSize(self.Cache.PickUp, 10);
		limitTableSize(self.Cache.KillTracker, 10);
		
		self.Cache.LastGet = nil;
		self.Cache.Cache = nil;
	end)
	
	return self.Cache;
end

return StatisticProfile;
