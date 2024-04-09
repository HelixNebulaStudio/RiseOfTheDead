local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SyncTime = {};
SyncTime.Weekdays = {
	"Sunday";
	"Monday";
	"Tuesday";
	"Wednesday";
	"Thursday";
	"Friday";
	"Saturday";
};

local RunService = game:GetService("RunService");

if RunService:IsServer() then
	SyncTime.Clock = Instance.new("IntValue");
	SyncTime.Clock.Name = "GameClock";
	SyncTime.Clock.Value = os.time();
	SyncTime.Clock.Parent = game.ReplicatedStorage

	SyncTime.WeekDay = Instance.new("StringValue");
	SyncTime.WeekDay.Name = "WeekDay";
	SyncTime.WeekDay.Value = "Monday";
	SyncTime.WeekDay.Parent = game.ReplicatedStorage

	SyncTime.EndOfDay = Instance.new("IntValue");
	SyncTime.EndOfDay.Name = "EndOfDay";
	SyncTime.EndOfDay.Value = os.time();
	SyncTime.EndOfDay.Parent = game.ReplicatedStorage

	SyncTime.EndOfWeek = Instance.new("IntValue");
	SyncTime.EndOfWeek.Name = "EndOfWeek";
	SyncTime.EndOfWeek.Value = os.time();
	SyncTime.EndOfWeek.Parent = game.ReplicatedStorage

	SyncTime.TimeOffset = Instance.new("IntValue");
	SyncTime.TimeOffset.Name = "TimeOffset";
	SyncTime.TimeOffset.Value = 0;
	SyncTime.TimeOffset.Parent = game.ReplicatedStorage


	SyncTime.ServerUpTime = Instance.new("IntValue");
	SyncTime.ServerUpTime.Name = "ServerUpTime";
	SyncTime.ServerUpTime.Value = os.time();
	SyncTime.ServerUpTime.Parent = game.ReplicatedStorage
	
	local minTick = tick()-60;
	RunService.Heartbeat:Connect(function()
		local unixTime = DateTime.now().UnixTimestamp;
		
		local liveTime = unixTime + SyncTime.TimeOffset.Value;
		
		local setTime = workspace:GetAttribute("SetTime");
		if setTime then
			liveTime = setTime;
		end
		
		SyncTime.Clock.Value = liveTime
		
		--workspace:SetAttribute("OsTime", liveTime);
		
		if tick()-minTick > 60 then
			minTick = tick();
			
			if setTime then
				Debugger:Warn("Time frozen to:", setTime);
			end
			
			SyncTime.WeekDay.Value = SyncTime.Weekdays[os.date("*t", unixTime).wday];

			local t = os.date("!*t", unixTime);
			t.wday = (8 - t.wday) % 7;
			t.hour, t.min, t.sec = 23 - t.hour, 59 - t.min, 59 - t.sec;

			SyncTime.EndOfDay.Value = unixTime+t.hour*3600+t.min*60+t.sec; --  - (3600*2) test offset
			SyncTime.EndOfWeek.Value = unixTime+(t.wday)*86400+t.hour*3600+t.min*60+t.sec;
		end
	end)
end

function SyncTime.SetOffset(num)
	SyncTime.TimeOffset.Value = tonumber(num) or 0;
end

function SyncTime.GetWeekDay()
	SyncTime.WeekDay = SyncTime.WeekDay or game.ReplicatedStorage:FindFirstChild("WeekDay");
	return SyncTime.WeekDay.Value;
end

function SyncTime.TimeOfEndOfDay()
	SyncTime.EndOfDay = SyncTime.EndOfDay or game.ReplicatedStorage:FindFirstChild("EndOfDay");
	return SyncTime.EndOfDay.Value;
end
	
function SyncTime.TimeOfEndOfWeek()
	SyncTime.EndOfWeek = SyncTime.EndOfWeek or game.ReplicatedStorage:FindFirstChild("EndOfWeek");
	return SyncTime.EndOfWeek.Value;
end

function SyncTime.GetUpTime()
	SyncTime.ServerUpTime = SyncTime.ServerUpTime or game.ReplicatedStorage:FindFirstChild("ServerUpTime");
	return SyncTime.ServerUpTime and SyncTime.ServerUpTime.Value or 0;
end


--workspace:SetAttribute("OsTime", DateTime.now().UnixTimestamp);
function SyncTime.GetTime()
	if SyncTime.TimeOffset == nil then
		SyncTime.TimeOffset = game.ReplicatedStorage:FindFirstChild("TimeOffset");
	end
	local offsetTime = SyncTime.TimeOffset and SyncTime.TimeOffset.Value or 0;
	
	local liveTime = workspace:GetServerTimeNow() + offsetTime;

	local setTime = workspace:GetAttribute("SetTime");
	if setTime then
		liveTime = setTime;
	end
	return liveTime;
	
	--return workspace:GetAttribute("OsTime");
	
	--SyncTime.Clock = SyncTime.Clock or game.ReplicatedStorage:FindFirstChild("GameClock");
	--return SyncTime.Clock and SyncTime.Clock.Value or 0;
end

function SyncTime.GetClock()
	repeat 
		SyncTime.Clock = SyncTime.Clock or game.ReplicatedStorage:FindFirstChild("GameClock");
	until SyncTime.Clock or not task.wait(0.1);
	return SyncTime.Clock;
end

function SyncTime.ToString(s)
	if s < 3600 then
		return string.format("%02i:%02i", s/60%60, s%60);
	end
	return string.format("%02i:%02i:%02i", s/(3600), s/60%60, s%60);
end

return SyncTime;