local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);


local CoopMission = {};
CoopMission.__index = CoopMission;
CoopMission.ClassType = "CoopMission";


CoopMission.Groups = {};

---
function CoopMission:Get(groupId, missionId)
	local group = self.Groups[groupId];
	if group == nil then return end;
	
	return group[missionId];
end


function CoopMission.new(groupId, missionId)
	local meta = {
		Lib = modMissionLibrary.Get(missionId);
	}
	local self = {
		GroupId=groupId;
		Id=missionId;
		Players = {};
		
		Type = 1;
		CheckPoint = 1;
		
		SaveData = {};
		
		Changed = modEventSignal.new("OnCoopMissionChanged");
		OnPlayerAdded = modEventSignal.new("OnCoopMissionPlayerAdded");
	};
	
	setmetatable(meta, CoopMission)
	meta.__index = meta;
	setmetatable(self, meta);
	
	if CoopMission.Groups[groupId] == nil then
		CoopMission.Groups[groupId] = {};
	end
	CoopMission.Groups[groupId][missionId] = self;
	
	return self;
end

function CoopMission:Progress(func)
	func(self);
	self.Changed:Fire(false, self);
end

function CoopMission:Fail(reasonStr)
	self.Type = 4;
	self.FailReason = reasonStr;
	
	self.Changed:Fire(false, self);
end

function CoopMission:AddPlayer(player)
	if table.find(self.Players, player) then return end;
	
	table.insert(self.Players, player);
	self.OnPlayerAdded:Fire(player);
	
end

function CoopMission:ForEachPlayer(func)
	for a=#self.Players, 1, -1 do
		local player = game.Players:FindFirstChild(self.Players[a].Name);
		if player then
			task.spawn(func, player);
			
		else
			Debugger:Warn("Player (",self.Players[a].Name,") disconnected, removing from mission.");
			table.remove(self.Players, a);
			
		end
	end
end

function CoopMission:GetPlayers()
	return table.clone(self.Players);
end

function CoopMission:Destroy()
	local group = CoopMission.Groups[self.GroupId];
	if group == nil then return end;
	
	CoopMission.Groups[self.GroupId][self.Id] = nil;
	
	self.Changed:Destroy();
	self.OnPlayerAdded:Destroy();
end

return CoopMission;
