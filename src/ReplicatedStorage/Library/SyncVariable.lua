local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local SyncVariable = {};
SyncVariable.__index = SyncVariable;

SyncVariable.Variables = {};

--==
function SyncVariable.new(id, val)
	local self = {
		Changed = false;
		Records = {};
		Value = val;
		ValueCache = val;
	};

	setmetatable(self, SyncVariable);
	
	self.Variables[id] = self;
	
	return self;
end

function SyncVariable:Get()
	local val = self.Value;

	if self.Changed then
		self.Changed = false;

		table.sort(self.Records, function(a, b) return a.Time < b.Time; end);
		for a=1, #self.Records do
			local func = self.Records[a].Func;
			val = func(val);
		end

		self.ValueCache = val;
	else
		val = self.ValueCache;
	end

	return val;
end

function SyncVariable:Record(unixTime, func)
	table.insert(self.Records, {
		Time = unixTime;
		Func = func;
	});
	self.Changed = true;
end

function SyncVariable:Update(unixTime, func)
	self:Record(unixTime, func);

	self.Value = self:Get();
	self.ValueCache = self.Value;
	table.clear(self.Records);
end


return SyncVariable;
