local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
--==
local FactionMeta = {};
FactionMeta.__index = FactionMeta;
FactionMeta.ClassType = "FactionMeta";

function FactionMeta.new()
	local self = {
		List={};
	};

	setmetatable(self, FactionMeta);
	return self;
end

function FactionMeta:Get(tag)
	return self.List[tag];
end

function FactionMeta:Set(tag, factionPacket)
	local unixTime = DateTime.now().UnixTimestamp;

	for k, v in pairs(self.List) do
		if v.Tick and unixTime-v.Tick < shared.Const.OneDaySecs * 30 then continue end;
		
		self.List[k] = nil;
	end

	self.List[tag] = {
		Tick=unixTime;
		Tag=factionPacket.Tag;
		Title=factionPacket.Title;
		Icon=factionPacket.Icon;
		Color=factionPacket.Color;
	};
end
return FactionMeta;
