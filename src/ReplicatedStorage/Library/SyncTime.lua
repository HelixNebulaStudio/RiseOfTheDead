local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SyncTime = {};
SyncTime.IsDay = nil;
SyncTime.Weekdays = {
	"Sunday";
	"Monday";
	"Tuesday";
	"Wednesday";
	"Thursday";
	"Friday";
	"Saturday";
};
SyncTime.WeekdayIndex = {
	["Monday"] = 1;
	["Tuesday"] = 2;
	["Wednesday"] = 3;
	["Thursday"] = 4;
	["Friday"] = 5;
	["Saturday"] = 6;
	["Sunday"] = 7;
}

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
	
	SyncTime.EndOfMonth = Instance.new("IntValue");
	SyncTime.EndOfMonth.Name = "EndOfMonth";
	SyncTime.EndOfMonth.Value = os.time();
	SyncTime.EndOfMonth.Parent = game.ReplicatedStorage
	
	SyncTime.EndOfSeason = Instance.new("IntValue");
	SyncTime.EndOfSeason.Name = "EndOfSeason";
	SyncTime.EndOfSeason.Value = os.time();
	SyncTime.EndOfSeason.Parent = game.ReplicatedStorage

	SyncTime.EndOfYear = Instance.new("IntValue");
	SyncTime.EndOfYear.Name = "EndOfYear";
	SyncTime.EndOfYear.Value = os.time();
	SyncTime.EndOfYear.Parent = game.ReplicatedStorage

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
			local smonth = (4 - ((t.month+1) % 4)); 
			t.month = (12 - t.month);
			t.day = (31 - t.day);
			t.wday = (8 - t.wday) % 7;
			t.hour, t.min, t.sec = 23 - t.hour, 59 - t.min, 59 - t.sec;

			SyncTime.EndOfDay.Value = unixTime+t.hour*3600+t.min*60+t.sec;
			SyncTime.EndOfWeek.Value = unixTime+(t.wday*86400)+t.hour*3600+t.min*60+t.sec;
			
			SyncTime.EndOfMonth.Value = unixTime+(t.day*86400)+(t.hour*3600)+(t.min*60)+(t.sec);
			SyncTime.EndOfSeason.Value = unixTime+(smonth*2678400)+(t.day*86400)+(t.hour*3600)+(t.min*60)+(t.sec);
			SyncTime.EndOfYear.Value = unixTime+(t.month*2678400)+(t.day*86400)+(t.hour*3600)+(t.min*60)+(t.sec);
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

function SyncTime.TimeOfEndOfMonth()
	SyncTime.EndOfMonth = SyncTime.EndOfMonth or game.ReplicatedStorage:FindFirstChild("EndOfMonth");
	return SyncTime.EndOfMonth.Value;
end

function SyncTime.TimeOfEndOfSeason()
	SyncTime.EndOfSeason = SyncTime.EndOfSeason or game.ReplicatedStorage:FindFirstChild("EndOfSeason");
	return SyncTime.EndOfSeason.Value;
end

function SyncTime.TimeOfEndOfYear()
	SyncTime.EndOfYear = SyncTime.EndOfYear or game.ReplicatedStorage:FindFirstChild("EndOfYear");
	return SyncTime.EndOfYear.Value;
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
	if s/(3600) <= 24 then
		return string.format("%02i:%02i:%02i", s/(3600), s/60%60, s%60);
	end
	return string.format("%02id:%02i:%02i:%02i", math.floor(s/3600/24), (s/(3600)) % 24, s/60%60, s%60);
end

function SyncTime.FormatMs(ms)
	if ms/1000/60/60 >= 1 then
		return string.format("%d:%02d:%02d.%03d", ms/1000/60/60%60, ms/1000/60%60, ms/1000%60, (ms%1000));
	end
	return string.format("%02d:%02d.%03d", ms/1000/60%60, ms/1000%60, (ms%1000));
end

task.spawn(function()
	if RunService:IsClient() then return end;

	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("synctime", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;

		RequiredArgs = 0;
		UsageInfo = "/synctime [endtimes]";
		Function = function(player, args)
			local action = args[1];
			
			if action == "endtimes" then

				local function warnNotify(...)
					Debugger:Warn(...);
					shared.Notify(player, Debugger:Stringify(...), "Inform");
				end

				warnNotify("EoD", DateTime.fromUnixTimestamp(SyncTime.EndOfDay.Value):ToIsoDate());
				warnNotify("EoW", DateTime.fromUnixTimestamp(SyncTime.EndOfWeek.Value):ToIsoDate());
				warnNotify("EoM", DateTime.fromUnixTimestamp(SyncTime.EndOfMonth.Value):ToIsoDate());
				warnNotify("EoS", DateTime.fromUnixTimestamp(SyncTime.EndOfSeason.Value):ToIsoDate());
				warnNotify("EoY", DateTime.fromUnixTimestamp(SyncTime.EndOfYear.Value):ToIsoDate());
			end
			
			return true;
		end;
	});
end)

return SyncTime;