local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

--== Script;
local AnalyticsProfile = {};
AnalyticsProfile.__index = AnalyticsProfile;

function AnalyticsProfile:Submit()
	task.spawn(function()
		for key, data in pairs(self) do
			if data.Source then
				modAnalytics.RecordResource(self.Player, data.Source, "Source", key, "Net", "Session");
			end
			if data.Sink then
				modAnalytics.RecordResource(self.Player, data.Sink, "Sink", key, "Net", "Session");
			end
			if data.Time then
				local split = string.split(key, ":");
				if #split > 1 then
					--modAnalytics.RecordResource(self.Player, data.Time, "Source", "Time", split[1], split[2]);
				end
			end
			self[key] = nil;
		end
	end)
end

function AnalyticsProfile:Log(key, value)
	task.spawn(function()
		if self[key] == nil then self[key] = {} end;
		if value > 0 then
			self[key].Source = (self[key].Source or 0) + value;
		elseif value < 0 then
			self[key].Sink = (self[key].Sink or 0) - value;
		end
	end)
end

function AnalyticsProfile:LogTime(key, duration)
	task.spawn(function()
		if self[key] == nil then self[key] = {} end;
		self[key].Time = (self[key].Time or 0) + duration;
	end)
end

function AnalyticsProfile.new(player)
	local analyticsMeta = {
		Player = player;
	};
	
	local self = {};
	
	analyticsMeta.__index = analyticsMeta;
	setmetatable(analyticsMeta, AnalyticsProfile);
	setmetatable(self, analyticsMeta);
	return self;
end

return AnalyticsProfile;
